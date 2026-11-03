import {onDocumentCreated} from "firebase-functions/v2/firestore";
import {onSchedule} from "firebase-functions/v2/scheduler";
import {onTaskDispatched} from "firebase-functions/v2/tasks";
import * as admin from "firebase-admin";
import {getFunctions} from "firebase-admin/functions";
import {BEEM_API_KEY, BEEM_SECRET_KEY, beemAuthHeader, digitsOnly, sendBeemSms} from "./beem_sms";
import {retryPendingInviteSms} from "./invite_sms";

/**
 * Beem Africa Welcome SMS Integration.
 *
 * Requirements:
 * 1. 5 minutes after a user account has been created in the app, automatically
 *    send an SMS using the Beem SMS template named "Maelezo ya mteja mpya":
 *    "Habari!! {name} Tumekukalibishe kishupavu zaidi na Ofa ya Free plan kwenye
 *    account yako Kwa huduma ya kukuhamishia taarifa zako zote kwenye App,
 *    msadaa au changamoto yoyote Piga +255-653-520-829"
 * 2. Dynamic template syncing: Whenever the template is updated in the Beem
 *    Africa dashboard, the updated text is fetched and used automatically.
 * 3. Multi-country support: Sends to any phone number supported by Beem Africa
 *    (canonical digits-only format).
 *
 * Flow (event-driven, so idle hours cost no Firestore reads):
 *   users/{uid} created → onUserCreatedWelcomeSms queues a Cloud Task delayed
 *   5 minutes → sendWelcomeSms sends it. processPendingWelcomeSms runs hourly
 *   over recently created users only, as a retry / safety net.
 */

const REGION = "us-central1";

const BEEM_SMS_TEMPLATES_URL = "https://apisms.beem.africa/public/v1/sms-templates";

export const WELCOME_TEMPLATE_NAME = "Maelezo ya mteja mpya";
export const DEFAULT_WELCOME_TEMPLATE =
  "Habari!! {name} Tumekukalibishe kishupavu zaidi na Ofa ya Free plan kwenye account yako Kwa huduma ya kukuhamishia taarifa zako zote kwenye App, msadaa au changamoto yoyote Piga +255-653-520-829";

// 5 minutes delay after user creation
const WELCOME_SMS_DELAY_MS = 5 * 60 * 1000;
// Cloud Tasks may fire a few seconds early relative to Firestore's clock.
const CLOCK_SKEW_TOLERANCE_MS = 30 * 1000;
// An "in_progress" claim older than this belongs to a run that crashed.
const STALE_CLAIM_MS = 15 * 60 * 1000;
// The hourly sweep only looks at users created within this window.
const SWEEP_LOOKBACK_MS = 3 * 24 * 60 * 60 * 1000;
const MAX_SEND_ATTEMPTS = 3;

// In-memory cache for the Beem template (cached for 5 minutes)
let cachedTemplate: {text: string; fetchedAt: number} | null = null;
const TEMPLATE_CACHE_TTL_MS = 5 * 60 * 1000;

/**
 * Fetches the "Maelezo ya mteja mpya" template dynamically from Beem Africa.
 * If the template is edited in the Beem dashboard, this automatically returns
 * the updated content. Falls back to DEFAULT_WELCOME_TEMPLATE if the template
 * API is unreachable or the template is not found.
 */
export async function getWelcomeTemplateText(): Promise<string> {
  const now = Date.now();
  if (cachedTemplate && now - cachedTemplate.fetchedAt < TEMPLATE_CACHE_TTL_MS) {
    return cachedTemplate.text;
  }

  try {
    const response = await fetch(BEEM_SMS_TEMPLATES_URL, {
      method: "GET",
      headers: {
        "Authorization": beemAuthHeader(),
        "Content-Type": "application/json",
      },
    });

    if (response.ok) {
      const body = (await response.json()) as {
        data?: Array<{sms_title?: string; message?: string}>;
      };

      const templates = body.data ?? [];
      const targetNormalized = WELCOME_TEMPLATE_NAME.toLowerCase().trim();

      const matched = templates.find((t) => {
        const title = (t.sms_title ?? "").toLowerCase().trim();
        return title === targetNormalized || title.includes(targetNormalized);
      });

      if (matched?.message) {
        cachedTemplate = {
          text: matched.message,
          fetchedAt: now,
        };
        return matched.message;
      } else {
        console.warn(
          `[WelcomeSMS] Template "${WELCOME_TEMPLATE_NAME}" not found in Beem response. Using fallback.`,
        );
      }
    } else {
      console.warn(
        `[WelcomeSMS] Could not fetch templates from Beem (HTTP ${response.status}). Using fallback.`,
      );
    }
  } catch (err) {
    console.error("[WelcomeSMS] Error fetching Beem SMS template:", err);
  }

  // Use fallback if fetch failed or template not found
  cachedTemplate = {
    text: DEFAULT_WELCOME_TEMPLATE,
    fetchedAt: now,
  };
  return DEFAULT_WELCOME_TEMPLATE;
}

/**
 * Replaces name placeholders ({name}, {{name}}, {NAME}, etc.) with the user's name.
 */
export function formatWelcomeMessage(template: string, name: string): string {
  const cleanName = name.trim() || "Mteja";
  return template.replace(/\{\{?name\}\}?/gi, cleanName);
}

type WelcomeSmsOutcome = "sent" | "failed" | "abandoned" | "skipped";

/**
 * Claims, sends and records the welcome SMS for one user. Safe to call more
 * than once for the same user (task retries, the sweep and the task racing
 * each other): the claim transaction lets only one caller send.
 */
async function sendWelcomeSmsToUser(
  ref: FirebaseFirestore.DocumentReference,
): Promise<WelcomeSmsOutcome> {
  const db = admin.firestore();
  const now = Date.now();

  // Atomically claim this user to prevent concurrent double-sends. All
  // eligibility checks run on the fresh transactional read.
  let claimed: FirebaseFirestore.DocumentData | null = null;
  try {
    await db.runTransaction(async (tx) => {
      claimed = null;
      const snap = await tx.get(ref);
      const data = snap.data();
      if (!data || !isWelcomeSmsCandidate(data)) return;

      // Not 5 minutes old yet — the delayed task or the next sweep sends it.
      const createdAt = data.createdAt as FirebaseFirestore.Timestamp | undefined;
      if (createdAt && now - createdAt.toMillis() < WELCOME_SMS_DELAY_MS - CLOCK_SKEW_TOLERANCE_MS) {
        return;
      }

      // Another run is sending right now. A claim older than
      // STALE_CLAIM_MS means that run crashed, so take it over.
      if (data.welcomeSmsStatus === "in_progress") {
        const lastAttempt = data.welcomeSmsLastAttemptAt as FirebaseFirestore.Timestamp | undefined;
        if (lastAttempt && now - lastAttempt.toMillis() < STALE_CLAIM_MS) return;
      }

      tx.update(ref, {
        welcomeSmsStatus: "in_progress",
        welcomeSmsLastAttemptAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      claimed = data;
    });
  } catch (err) {
    console.error(`[WelcomeSMS] Could not claim user ${ref.id}:`, err);
    return "skipped";
  }

  const data = claimed as FirebaseFirestore.DocumentData | null;
  if (!data) return "skipped";

  const phone = digitsOnly(data.phone);
  const recipientName =
    (data.firstName as string | undefined)?.trim() ||
    (data.name as string | undefined)?.trim()?.split(" ")[0] ||
    "Mteja";

  const message = formatWelcomeMessage(await getWelcomeTemplateText(), recipientName);
  const sendResult = await sendBeemSms(phone, message);

  if (sendResult.success) {
    await ref.update({
      welcomeSmsSent: true,
      welcomeSmsStatus: "sent",
      welcomeSmsSentAt: admin.firestore.FieldValue.serverTimestamp(),
      welcomeSmsPhone: phone,
      welcomeSmsRecipientName: recipientName,
      welcomeSmsMessagePreview: message.substring(0, 80),
    });
    console.log(`[WelcomeSMS] Successfully sent welcome SMS to user ${ref.id} (${phone})`);
    return "sent";
  }

  const attempts = (data.welcomeSmsAttempts as number | undefined || 0) + 1;
  const status = attempts >= MAX_SEND_ATTEMPTS ? "abandoned" : "failed";
  await ref.update({
    welcomeSmsStatus: status,
    welcomeSmsAttempts: attempts,
    welcomeSmsError: sendResult.error || "Unknown error",
    welcomeSmsLastAttemptAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  console.error(
    `[WelcomeSMS] Failed to send welcome SMS to user ${ref.id} (${phone}): ${sendResult.error}`,
  );
  return status;
}

/** True when the user still needs the welcome SMS and has a usable phone. */
function isWelcomeSmsCandidate(data: FirebaseFirestore.DocumentData): boolean {
  // Staff get the invitation SMS (invite_sms.ts) instead; the welcome text
  // is about the owner's Free plan.
  if (data.isTeamMember === true) return false;
  if (data.welcomeSmsSent === true || data.welcomeSmsStatus === "sent") return false;
  if (data.welcomeSmsStatus === "abandoned") return false;
  return digitsOnly(data.phone).length >= 9;
}

/**
 * Fires once when a user document is created and schedules the welcome SMS
 * for 5 minutes later via a Cloud Task, so nothing polls the users
 * collection while there are no signups.
 */
export const onUserCreatedWelcomeSms = onDocumentCreated(
  {document: "users/{uid}", region: REGION},
  async (event) => {
    const data = event.data?.data();
    if (!data || !isWelcomeSmsCandidate(data)) return;

    const uid = event.params.uid;
    try {
      await getFunctions()
        .taskQueue<WelcomeSmsTaskData>(`locations/${REGION}/functions/sendWelcomeSms`)
        .enqueue(
          {uid},
          {
            scheduleDelaySeconds: WELCOME_SMS_DELAY_MS / 1000,
            // Firestore triggers are at-least-once; a fixed task id stops a
            // redelivered event from queueing a second task.
            id: `welcome-${uid}`,
          },
        );
    } catch (err) {
      // Duplicate id (redelivered event) or Cloud Tasks unavailable. Either
      // way the hourly sweep picks the user up if the SMS never went out.
      console.warn(`[WelcomeSMS] Could not enqueue welcome SMS for user ${uid}:`, err);
    }
  },
);

interface WelcomeSmsTaskData {
  uid: string;
}

/**
 * Cloud Task handler queued by onUserCreatedWelcomeSms. Only Cloud Tasks can
 * invoke it, unlike an onCall function.
 */
export const sendWelcomeSms = onTaskDispatched<WelcomeSmsTaskData>(
  {
    region: REGION,
    secrets: [BEEM_API_KEY, BEEM_SECRET_KEY],
    retryConfig: {maxAttempts: 3, minBackoffSeconds: 60},
    rateLimits: {maxConcurrentDispatches: 10},
  },
  async (request) => {
    const uid = String(request.data?.uid ?? "");
    if (!uid) return;
    await sendWelcomeSmsToUser(admin.firestore().collection("users").doc(uid));
  },
);

/**
 * Hourly safety net. Retries failed sends, takes over claims left behind by
 * a crashed run, and covers users whose task was never queued. Reads only
 * users created in the last SWEEP_LOOKBACK_MS, never the whole collection.
 * Also retries failed staff invitation SMS (invite_sms.ts).
 */
export const processPendingWelcomeSms = onSchedule(
  {
    schedule: "every 60 minutes",
    region: REGION,
    secrets: [BEEM_API_KEY, BEEM_SECRET_KEY],
  },
  async () => {
    const cutoff = admin.firestore.Timestamp.fromMillis(Date.now() - SWEEP_LOOKBACK_MS);
    const snap = await admin.firestore()
      .collection("users")
      .where("createdAt", ">=", cutoff)
      .orderBy("createdAt")
      .get();

    const counts: Record<WelcomeSmsOutcome, number> = {sent: 0, failed: 0, abandoned: 0, skipped: 0};
    for (const doc of snap.docs) {
      if (!isWelcomeSmsCandidate(doc.data())) continue;
      counts[await sendWelcomeSmsToUser(doc.ref)]++;
    }
    console.log(`[WelcomeSMS] Sweep scanned ${snap.size} recent users:`, counts);

    // Shares this job (and its Beem secrets) to stay within Cloud
    // Scheduler's 3 free jobs.
    console.log("[InviteSMS] Retry sweep:", await retryPendingInviteSms());
  },
);
