import {onDocumentCreated} from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";

/**
 * Fans an admin-composed notification out to FCM device tokens.
 *
 * The admin console (apps/admin "Notifications" page) only ever creates the
 * `admin_broadcasts/{id}` doc via the Admin SDK — all send/fan-out logic
 * lives here so retries/resends can be added later without touching the
 * admin app. Device tokens live at `users/{uid}/fcm_tokens/{token}`
 * (doc id = the token itself), registered by
 * lib/core/services/push_notification_service.dart on the mobile client.
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
}

interface TokenRef {
  token: string;
  ref: FirebaseFirestore.DocumentReference;
}

const MULTICAST_BATCH_SIZE = 500;

// FCM error codes meaning the token is permanently dead — safe to delete
// instead of re-sending to it next time.
const STALE_TOKEN_ERROR_CODES = new Set([
  "messaging/registration-token-not-registered",
  "messaging/invalid-argument",
]);

export const sendAdminBroadcast = onDocumentCreated(
  {document: "admin_broadcasts/{broadcastId}", region: "us-central1"},
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const data = snap.data() as BroadcastDoc;
    const db = admin.firestore();

    // Swahili-first: prefer the Swahili copy when the admin supplied one.
    const title = (data.titleSw && data.titleSw.trim()) || data.titleEn;
    const body = (data.bodySw && data.bodySw.trim()) || data.bodyEn;

    let recipients: TokenRef[] = [];
    try {
      recipients = await resolveTokens(db, data.audience);
    } catch (error) {
      console.error("[sendAdminBroadcast] failed to resolve recipients", error);
      await snap.ref.update({
        status: "failed",
        sentAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      return;
    }

    if (recipients.length === 0) {
      await snap.ref.update({
        status: "sent",
        sentAt: admin.firestore.FieldValue.serverTimestamp(),
        targetCount: 0,
        sentCount: 0,
        failureCount: 0,
      });
      return;
    }

    let sentCount = 0;
    let failureCount = 0;
    const staleRefs: FirebaseFirestore.DocumentReference[] = [];

    for (let i = 0; i < recipients.length; i += MULTICAST_BATCH_SIZE) {
      const batch = recipients.slice(i, i + MULTICAST_BATCH_SIZE);
      const response = await admin.messaging().sendEachForMulticast({
        tokens: batch.map((r) => r.token),
        notification: {title, body},
        data: {
          category: data.category ?? "general",
          broadcastId: event.params.broadcastId,
          ...(data.route ? {route: data.route} : {}),
        },
        android: {notification: {channelId: "mali_up_alerts"}},
      });

      sentCount += response.successCount;
      failureCount += response.failureCount;
      response.responses.forEach((r, idx) => {
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

    await snap.ref.update({
      status: "sent",
      sentAt: admin.firestore.FieldValue.serverTimestamp(),
      targetCount: recipients.length,
      sentCount,
      failureCount,
    });
  },
);

/** All device tokens for the given audience, deduped by token string. */
async function resolveTokens(
  db: FirebaseFirestore.Firestore,
  audience: BroadcastAudience,
): Promise<TokenRef[]> {
  if (audience.kind === "all") {
    const snap = await db.collectionGroup("fcm_tokens").get();
    return dedupe(snap.docs.map((d) => ({token: d.id, ref: d.ref})));
  }

  const businessIds = audience.businessIds ?? [];
  const ownerUids = new Set<string>();
  await Promise.all(
    businessIds.map(async (businessId) => {
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
