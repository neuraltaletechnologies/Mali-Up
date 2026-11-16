import {onDocumentCreated} from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";

/**
 * Sends an admin-composed notification through FCM **topics**.
 *
 * The admin console (apps/admin "Notifications" page) only ever creates the
 * `admin_broadcasts/{id}` doc — all send logic lives here. Devices subscribe
 * themselves (lib/core/services/push_notification_service.dart):
 *   - `all_<lang>`                    every signed-in device, in its app language
 *   - `biz_<businessId>_<lang>`        devices whose active business is that one
 *   - `owners_<lang>` / `biz_<businessId>_owners_<lang>`  the same, owners only
 * `recipients: "owners"` on the broadcast targets the owner-only topics, so
 * billing/plan messages never reach team members.
 * One FCM request per topic reaches every subscribed device, so the cost of a
 * broadcast doesn't grow with the number of users (no token reads, no
 * per-device fan-out in this function).
 *
 * Legacy path: app builds from before topics registered tokens under
 * `users/{uid}/fcm_tokens/{token}`. Updated clients delete their entry, so
 * whatever is left there is exactly the not-yet-updated installs; they still
 * get broadcasts the old way until they update. Remove `sendLegacy` once that
 * collection is empty.
 */

type BroadcastAudience =
  | {kind: "all"}
  | {kind: "businesses"; businessIds: string[]; businessNames: string[]};

interface BroadcastDoc {
  titleEn: string;
  bodyEn: string;
  titleSw?: string | null;
  bodySw?: string | null;
  category?: string;
  route?: string | null;
  audience: BroadcastAudience;
  /** "owners" skips team members; default "everyone" (owners + team). */
  recipients?: "everyone" | "owners";
}

type Lang = "sw" | "en";

const SEND_BATCH_SIZE = 500;

// FCM error codes meaning a token is permanently dead — safe to delete.
const STALE_TOKEN_ERROR_CODES = new Set([
  "messaging/registration-token-not-registered",
  "messaging/invalid-argument",
]);

/** FCM topic names allow only [a-zA-Z0-9-_.~%]. Mirrors PushTopics (Dart). */
const safe = (id: string) => id.replace(/[^a-zA-Z0-9\-_.~%]/g, "_");

export function topicsFor(
  audience: BroadcastAudience,
  lang: Lang,
  ownersOnly = false,
): string[] {
  if (audience.kind === "all") return [ownersOnly ? `owners_${lang}` : `all_${lang}`];
  const suffix = ownersOnly ? `owners_${lang}` : lang;
  return (audience.businessIds ?? []).map((id) => `biz_${safe(id)}_${suffix}`);
}

function copyFor(data: BroadcastDoc, lang: Lang) {
  // Swahili users get the Swahili copy when the admin supplied one, else the
  // English text; English users always get English.
  if (lang === "sw") {
    return {
      title: data.titleSw?.trim() || data.titleEn,
      body: data.bodySw?.trim() || data.bodyEn,
    };
  }
  return {title: data.titleEn, body: data.bodyEn};
}

function messageBase(data: BroadcastDoc, broadcastId: string, lang: Lang) {
  return {
    notification: copyFor(data, lang),
    data: {
      category: data.category ?? "general",
      broadcastId,
      ...(data.route ? {route: data.route} : {}),
    },
    android: {notification: {channelId: "mali_up_alerts"}},
    // Groups delivery/open stats per broadcast in Firebase Console →
    // Messaging → Reports.
    fcmOptions: {analyticsLabel: `broadcast_${safe(broadcastId)}`.slice(0, 50)},
  };
}

export const sendAdminBroadcast = onDocumentCreated(
  // 300s: headroom for very large "selected businesses" sends.
  {document: "admin_broadcasts/{broadcastId}", region: "us-central1", timeoutSeconds: 300},
  async (event) => {
    const snap = event.data;
    if (!snap) return;
    const data = snap.data() as BroadcastDoc;
    const broadcastId = event.params.broadcastId;
    const db = admin.firestore();

    const messages: admin.messaging.Message[] = [];
    for (const lang of ["sw", "en"] as const) {
      const base = messageBase(data, broadcastId, lang);
      for (const topic of topicsFor(data.audience, lang, data.recipients === "owners")) {
        messages.push({...base, topic});
      }
    }

    let topicSent = 0;
    let topicFailed = 0;
    for (let i = 0; i < messages.length; i += SEND_BATCH_SIZE) {
      try {
        const res = await admin.messaging().sendEach(messages.slice(i, i + SEND_BATCH_SIZE));
        topicSent += res.successCount;
        topicFailed += res.failureCount;
        res.responses.forEach((r) => {
          if (!r.success) console.error("[sendAdminBroadcast] topic send failed", r.error?.code, r.error?.message);
        });
      } catch (error) {
        console.error("[sendAdminBroadcast] topic batch failed", error);
        topicFailed += Math.min(SEND_BATCH_SIZE, messages.length - i);
      }
    }

    let legacy = {target: 0, sent: 0, failed: 0};
    try {
      legacy = await sendLegacy(db, data, broadcastId);
    } catch (error) {
      console.error("[sendAdminBroadcast] legacy token send failed", error);
    }

    await snap.ref.update({
      status: topicSent > 0 || legacy.sent > 0 || messages.length === 0 ? "sent" : "failed",
      sentAt: admin.firestore.FieldValue.serverTimestamp(),
      deliveryMode: "topics",
      topicCount: messages.length,
      topicSentCount: topicSent,
      topicFailureCount: topicFailed,
      // Legacy (pre-topics app builds) per-device counts.
      targetCount: legacy.target,
      sentCount: legacy.sent,
      failureCount: legacy.failed,
    });
  },
);

// ── Legacy: per-token fan-out for app builds that predate topics ───────────

interface TokenRef {
  token: string;
  ref: FirebaseFirestore.DocumentReference;
}

async function sendLegacy(
  db: FirebaseFirestore.Firestore,
  data: BroadcastDoc,
  broadcastId: string,
): Promise<{target: number; sent: number; failed: number}> {
  // Legacy "businesses" sends already reach only the owner's tokens.
  const recipients = await resolveLegacyTokens(db, data.audience, data.recipients === "owners");
  if (recipients.length === 0) return {target: 0, sent: 0, failed: 0};

  // Old builds have no language topic; keep their previous Swahili-first copy.
  const base = messageBase(data, broadcastId, "sw");
  let sent = 0;
  let failed = 0;
  const staleRefs: FirebaseFirestore.DocumentReference[] = [];

  for (let i = 0; i < recipients.length; i += SEND_BATCH_SIZE) {
    const batch = recipients.slice(i, i + SEND_BATCH_SIZE);
    const res = await admin.messaging().sendEachForMulticast({
      ...base,
      tokens: batch.map((r) => r.token),
    });
    sent += res.successCount;
    failed += res.failureCount;
    res.responses.forEach((r, idx) => {
      if (!r.success && r.error && STALE_TOKEN_ERROR_CODES.has(r.error.code)) {
        staleRefs.push(batch[idx].ref);
      }
    });
  }

  if (staleRefs.length > 0) {
    const writer = db.bulkWriter();
    for (const ref of staleRefs) writer.delete(ref);
    await writer.close();
  }

  return {target: recipients.length, sent, failed};
}

async function resolveLegacyTokens(
  db: FirebaseFirestore.Firestore,
  audience: BroadcastAudience,
  ownersOnly: boolean,
): Promise<TokenRef[]> {
  if (audience.kind === "all") {
    const snap = await db.collectionGroup("fcm_tokens").get();
    let docs = snap.docs;
    if (ownersOnly) {
      const owners = await db.collection("businesses").select("ownerUid").get();
      const ownerUids = new Set(owners.docs.map((d) => String(d.get("ownerUid") ?? "")));
      // users/{uid}/fcm_tokens/{token} → uid is the grandparent doc id.
      docs = docs.filter((d) => ownerUids.has(d.ref.parent.parent?.id ?? ""));
    }
    return dedupe(docs.map((d) => ({token: d.id, ref: d.ref})));
  }

  const ownerUids = new Set<string>();
  await Promise.all(
    (audience.businessIds ?? []).map(async (businessId) => {
      const bizDoc = await db.collection("businesses").doc(businessId).get();
      const ownerUid = bizDoc.data()?.ownerUid as string | undefined;
      if (ownerUid) ownerUids.add(ownerUid);
    }),
  );

  const tokenLists = await Promise.all(
    Array.from(ownerUids).map(async (uid) => {
      const snap = await db.collection("users").doc(uid).collection("fcm_tokens").get();
      return snap.docs.map((d) => ({token: d.id, ref: d.ref}));
    }),
  );

  return dedupe(tokenLists.flat());
}

function dedupe(refs: TokenRef[]): TokenRef[] {
  const seen = new Map<string, TokenRef>();
  for (const r of refs) seen.set(r.token, r);
  return Array.from(seen.values());
}
