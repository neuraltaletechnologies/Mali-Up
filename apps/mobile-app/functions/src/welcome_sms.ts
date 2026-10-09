import {onCall, HttpsError} from "firebase-functions/v2/https";
import {onSchedule} from "firebase-functions/v2/scheduler";
import {defineSecret} from "firebase-functions/params";
import * as admin from "firebase-admin";

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
 * 3. Existing users: Automatically sends the welcome SMS to existing users
 *    already registered in Firestore who haven't received it yet.
 * 4. Multi-country support: Sends to any phone number supported by Beem Africa
 *    (canonical digits-only format).
 */

const BEEM_API_KEY = defineSecret("BEEM_API_KEY");
const BEEM_SECRET_KEY = defineSecret("BEEM_SECRET_KEY");

const BEEM_SMS_SEND_URL = "https://apisms.beem.africa/v1/send";
const BEEM_SMS_TEMPLATES_URL = "https://apisms.beem.africa/public/v1/sms-templates";

export const WELCOME_TEMPLATE_NAME = "Maelezo ya mteja mpya";
export const DEFAULT_WELCOME_TEMPLATE =
  "Habari!! {name} Tumekukalibishe kishupavu zaidi na Ofa ya Free plan kwenye account yako Kwa huduma ya kukuhamishia taarifa zako zote kwenye App, msadaa au changamoto yoyote Piga +255-653-520-829";

// 5 minutes delay after user creation
const WELCOME_SMS_DELAY_MS = 5 * 60 * 1000;

// In-memory cache for the Beem template (cached for 5 minutes)
let cachedTemplate: {text: string; fetchedAt: number} | null = null;
const TEMPLATE_CACHE_TTL_MS = 5 * 60 * 1000;

function beemAuthHeader(): string {
  return "Basic " + Buffer.from(`${BEEM_API_KEY.value()}:${BEEM_SECRET_KEY.value()}`).toString("base64");
}

function digitsOnly(phone: unknown): string {
  return String(phone ?? "").replace(/\D/g, "");
}

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

/**
 * Sends a single SMS message via Beem Africa SMS API.
 */
export async function sendBeemSms(
  phone: string,
  message: string,
  sourceAddr?: string,
): Promise<{success: boolean; error?: string; responseData?: unknown}> {
  const formattedDest = digitsOnly(phone);
  if (formattedDest.length < 9 || formattedDest.length > 15) {
    return {success: false, error: `Invalid destination phone number: ${phone}`};
  }

  const senderId =
    sourceAddr ||
    process.env.BEEM_SMS_SENDER_ID ||
    "INFO";

  try {
    const payload = {
      source_addr: senderId,
      schedule_time: "",
      encoding: 0,
      message: message,
      recipients: [
        {
          recipient_id: 1,
          dest_addr: formattedDest,
        },
      ],
    };

    const response = await fetch(BEEM_SMS_SEND_URL, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": beemAuthHeader(),
      },
      body: JSON.stringify(payload),
    });

    const responseBody = await response.json().catch(() => ({}));

    if (!response.ok) {
      console.error("[WelcomeSMS] Beem SMS send failed", response.status, responseBody);
      return {
        success: false,
        error: `Beem HTTP ${response.status}: ${JSON.stringify(responseBody)}`,
        responseData: responseBody,
      };
    }

    return {success: true, responseData: responseBody};
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : String(err);
    console.error("[WelcomeSMS] Network error sending SMS via Beem:", err);
    return {success: false, error: msg};
  }
}

export interface WelcomeSmsBatchResult {
  totalScanned: number;
  sentCount: number;
  skippedTooYoung: number;
  skippedAlreadySent: number;
  failedCount: number;
  details: Array<{uid: string; phone: string; status: string; error?: string}>;
}

/**
 * Processes users needing the welcome SMS:
 * - Checks users with welcomeSmsSent !== true.
 * - If user account is >= 5 minutes old (or existing user with null createdAt), sends the SMS.
 * - If user account is < 5 minutes old, skips for now (will be picked up on next schedule).
 * - Updates user document with welcomeSmsSent = true to ensure idempotency.
 */
export async function processPendingWelcomeSmsQueue(
  batchLimit = 50,
): Promise<WelcomeSmsBatchResult> {
  const db = admin.firestore();
  const now = Date.now();

  const result: WelcomeSmsBatchResult = {
    totalScanned: 0,
    sentCount: 0,
    skippedTooYoung: 0,
    skippedAlreadySent: 0,
    failedCount: 0,
    details: [],
  };

  // Fetch the latest template dynamically from Beem once per batch
  const templateText = await getWelcomeTemplateText();

  // Query users collection in batches
  const usersSnap = await db.collection("users").limit(200).get();
  result.totalScanned = usersSnap.size;

  for (const doc of usersSnap.docs) {
    if (result.sentCount >= batchLimit) {
      break;
    }

    const data = doc.data();

    // Skip if already sent or abandoned after 3 failed attempts
    if (data.welcomeSmsSent === true || data.welcomeSmsStatus === "sent") {
      result.skippedAlreadySent++;
      continue;
    }

    if (data.welcomeSmsStatus === "abandoned") {
      continue;
    }

    const rawPhone = data.phone;
    const phone = digitsOnly(rawPhone);
    if (!phone || phone.length < 9) {
      continue;
    }

    // Check account age: 5 minutes after creation
    const createdAtTimestamp = data.createdAt as FirebaseFirestore.Timestamp | undefined;
    if (createdAtTimestamp) {
      const createdAtMs = createdAtTimestamp.toMillis();
      const ageMs = now - createdAtMs;
      if (ageMs < WELCOME_SMS_DELAY_MS) {
        // User created less than 5 minutes ago — wait until next run
        result.skippedTooYoung++;
        continue;
      }
    }
    // Note: If createdAtTimestamp is missing/null, this is an existing user created before
    // this timestamp field was introduced, so we immediately send to them as requested!

    // Atomically claim this user to prevent concurrent double-sends
    let claimed = false;
    try {
      await db.runTransaction(async (tx) => {
        const freshSnap = await tx.get(doc.ref);
        const freshData = freshSnap.data() || {};
        if (freshData.welcomeSmsSent === true || freshData.welcomeSmsStatus === "in_progress") {
          return;
        }
        tx.update(doc.ref, {
          welcomeSmsStatus: "in_progress",
          welcomeSmsLastAttemptAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        claimed = true;
      });
    } catch {
      claimed = false;
    }

    if (!claimed) {
      continue;
    }

    // Determine recipient name for placeholder
    const recipientName =
      (data.firstName as string | undefined)?.trim() ||
      (data.name as string | undefined)?.trim()?.split(" ")[0] ||
      "Mteja";

    const message = formatWelcomeMessage(templateText, recipientName);

    // Dispatch SMS via Beem
    const sendResult = await sendBeemSms(phone, message);

    if (sendResult.success) {
      await doc.ref.update({
        welcomeSmsSent: true,
        welcomeSmsStatus: "sent",
        welcomeSmsSentAt: admin.firestore.FieldValue.serverTimestamp(),
        welcomeSmsPhone: phone,
        welcomeSmsRecipientName: recipientName,
        welcomeSmsMessagePreview: message.substring(0, 80),
      });

      result.sentCount++;
      result.details.push({uid: doc.id, phone, status: "sent"});
      console.log(`[WelcomeSMS] Successfully sent welcome SMS to user ${doc.id} (${phone})`);
    } else {
      const attempts = (data.welcomeSmsAttempts as number | undefined || 0) + 1;
      const status = attempts >= 3 ? "abandoned" : "failed";

      await doc.ref.update({
        welcomeSmsStatus: status,
        welcomeSmsAttempts: attempts,
        welcomeSmsError: sendResult.error || "Unknown error",
        welcomeSmsLastAttemptAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      result.failedCount++;
      result.details.push({
        uid: doc.id,
        phone,
        status: status,
        error: sendResult.error,
      });
      console.error(
        `[WelcomeSMS] Failed to send welcome SMS to user ${doc.id} (${phone}): ${sendResult.error}`,
      );
    }
  }

  return result;
}

/**
 * Scheduled Cloud Function running every 5 minutes.
 * Automatically inspects users and sends the welcome SMS to:
 * 1. New users who reached 5 minutes since registration.
 * 2. Existing users already in the app who haven't received it yet.
 */
export const processPendingWelcomeSms = onSchedule(
  {
    schedule: "every 5 minutes",
    region: "us-central1",
    secrets: [BEEM_API_KEY, BEEM_SECRET_KEY],
  },
  async () => {
    console.log("[WelcomeSMS] Starting scheduled welcome SMS check...");
    const result = await processPendingWelcomeSmsQueue(50);
    console.log("[WelcomeSMS] Scheduled welcome SMS check finished:", result);
  },
);

interface TriggerWelcomeSmsBatchRequest {
  limit?: number;
}

/**
 * Callable Cloud Function allowing admins or background scripts to trigger
 * the welcome SMS batch immediately without waiting for the 5-minute cron.
 */
export const triggerWelcomeSmsBatch = onCall<TriggerWelcomeSmsBatchRequest>(
  {
    region: "us-central1",
    secrets: [BEEM_API_KEY, BEEM_SECRET_KEY],
  },
  async (request): Promise<WelcomeSmsBatchResult> => {
    const limit = Math.min(Math.max(Number(request.data?.limit) || 50, 1), 200);
    console.log(`[WelcomeSMS] Manual trigger for up to ${limit} users`);
    return await processPendingWelcomeSmsQueue(limit);
  },
);
