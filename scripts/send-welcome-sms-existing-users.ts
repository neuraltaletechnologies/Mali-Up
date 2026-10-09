/**
 * Script to send the Beem Africa Welcome SMS ("Maelezo ya mteja mpya") to
 * existing users in Firestore.
 *
 * Usage:
 *   # Dry run (shows which users would receive it, without sending SMS):
 *   npx ts-node send-welcome-sms-existing-users.ts --dry-run
 *
 *   # Live run:
 *   npx ts-node send-welcome-sms-existing-users.ts
 *
 * Requirements:
 *   BEEM_API_KEY and BEEM_SECRET_KEY environment variables or passed via flags:
 *   BEEM_API_KEY=xxx BEEM_SECRET_KEY=yyy npx ts-node send-welcome-sms-existing-users.ts
 */

import * as admin from "firebase-admin";

const TEMPLATE_NAME = "Maelezo ya mteja mpya";
const DEFAULT_TEMPLATE =
  "Habari!! {name} Tumekukalibishe kishupavu zaidi na Ofa ya Free plan kwenye account yako Kwa huduma ya kukuhamishia taarifa zako zote kwenye App, msadaa au changamoto yoyote Piga +255-653-520-829";

const BEEM_SMS_SEND_URL = "https://apisms.beem.africa/v1/send";
const BEEM_SMS_TEMPLATES_URL = "https://apisms.beem.africa/public/v1/sms-templates";

// Initialize Firebase Admin if not already initialized
if (admin.apps.length === 0) {
  admin.initializeApp();
}
const db = admin.firestore();

function getArg(flag: string): string | null {
  const idx = process.argv.indexOf(flag);
  if (idx !== -1 && idx + 1 < process.argv.length) {
    return process.argv[idx + 1];
  }
  return null;
}

const isDryRun = process.argv.includes("--dry-run");
const apiKey = process.env.BEEM_API_KEY || getArg("--api-key");
const secretKey = process.env.BEEM_SECRET_KEY || getArg("--secret-key");
const senderId = process.env.BEEM_SMS_SENDER_ID || getArg("--sender-id") || "INFO";

function digitsOnly(phone: unknown): string {
  return String(phone ?? "").replace(/\D/g, "");
}

function getAuthHeader(): string {
  return "Basic " + Buffer.from(`${apiKey}:${secretKey}`).toString("base64");
}

async function fetchBeemTemplate(): Promise<string> {
  if (!apiKey || !secretKey) {
    console.warn("⚠️ BEEM_API_KEY or BEEM_SECRET_KEY missing. Using fallback template.");
    return DEFAULT_TEMPLATE;
  }

  try {
    const res = await fetch(BEEM_SMS_TEMPLATES_URL, {
      method: "GET",
      headers: {
        Authorization: getAuthHeader(),
        "Content-Type": "application/json",
      },
    });

    if (res.ok) {
      const json = (await res.json()) as {
        data?: Array<{sms_title?: string; message?: string}>;
      };
      const templates = json.data ?? [];
      const match = templates.find((t) => {
        const title = (t.sms_title ?? "").toLowerCase().trim();
        return (
          title === TEMPLATE_NAME.toLowerCase().trim() ||
          title.includes(TEMPLATE_NAME.toLowerCase().trim())
        );
      });

      if (match?.message) {
        console.log(`✅ Found live template from Beem Africa: "${match.sms_title}"`);
        return match.message;
      }
    }
    console.warn(
      `⚠️ Could not fetch template "${TEMPLATE_NAME}" from Beem. Using default template.`,
    );
  } catch (e) {
    console.warn(`⚠️ Error fetching template from Beem: ${e}. Using default template.`);
  }

  return DEFAULT_TEMPLATE;
}

function formatMessage(template: string, name: string): string {
  const cleanName = name.trim() || "Mteja";
  return template.replace(/\{\{?name\}\}?/gi, cleanName);
}

async function sendSms(destAddr: string, message: string): Promise<boolean> {
  const formattedDest = digitsOnly(destAddr);
  if (formattedDest.length < 9) {
    console.error(`❌ Invalid destination phone: ${destAddr}`);
    return false;
  }

  try {
    const res = await fetch(BEEM_SMS_SEND_URL, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: getAuthHeader(),
      },
      body: JSON.stringify({
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
      }),
    });

    const body = await res.json().catch(() => ({}));
    if (!res.ok) {
      console.error(`❌ Beem SMS error (${res.status}):`, body);
      return false;
    }

    return true;
  } catch (e) {
    console.error(`❌ Network error sending SMS:`, e);
    return false;
  }
}

async function sleep(ms: number) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function run() {
  console.log("==================================================");
  console.log(" Mali Up — Beem Welcome SMS to Existing Users");
  console.log(` Mode: ${isDryRun ? "DRY-RUN (Simulated)" : "LIVE SEND"}`);
  console.log("==================================================");

  if (!isDryRun && (!apiKey || !secretKey)) {
    console.error(
      "❌ Error: Please provide BEEM_API_KEY and BEEM_SECRET_KEY as environment variables or arguments.",
    );
    process.exit(1);
  }

  const templateText = await fetchBeemTemplate();
  console.log(`\nTemplate content:\n"${templateText}"\n`);

  console.log("Fetching users from Firestore...");
  const usersSnap = await db.collection("users").get();
  console.log(`Found ${usersSnap.size} total user documents.\n`);

  let eligibleCount = 0;
  let sentCount = 0;
  let skippedCount = 0;
  let errorCount = 0;

  for (const doc of usersSnap.docs) {
    const data = doc.data();

    if (data.welcomeSmsSent === true || data.welcomeSmsStatus === "sent") {
      skippedCount++;
      continue;
    }

    const phone = digitsOnly(data.phone);
    if (!phone || phone.length < 9) {
      skippedCount++;
      continue;
    }

    eligibleCount++;
    const recipientName =
      (data.firstName as string | undefined)?.trim() ||
      (data.name as string | undefined)?.trim()?.split(" ")[0] ||
      "Mteja";

    const personalized = formatMessage(templateText, recipientName);

    console.log(
      `[#${eligibleCount}] User ${doc.id} | Phone: ${phone} | Name: ${recipientName}`,
    );

    if (isDryRun) {
      console.log(`   [DRY-RUN] Preview message: "${personalized}"`);
    } else {
      const ok = await sendSms(phone, personalized);
      if (ok) {
        await doc.ref.update({
          welcomeSmsSent: true,
          welcomeSmsStatus: "sent",
          welcomeSmsSentAt: admin.firestore.FieldValue.serverTimestamp(),
          welcomeSmsPhone: phone,
          welcomeSmsRecipientName: recipientName,
          welcomeSmsMessagePreview: personalized.substring(0, 80),
        });
        sentCount++;
        console.log(`   ✅ Sent successfully!`);
      } else {
        errorCount++;
        await doc.ref.update({
          welcomeSmsStatus: "failed",
          welcomeSmsAttempts: admin.firestore.FieldValue.increment(1),
          welcomeSmsLastAttemptAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        console.log(`   ❌ Failed to send.`);
      }

      // Small delay between SMS sends to prevent throttling
      await sleep(250);
    }
  }

  console.log("\n==================================================");
  console.log(" Summary:");
  console.log(` Total scanned: ${usersSnap.size}`);
  console.log(` Skipped (already received or invalid phone): ${skippedCount}`);
  console.log(` Eligible: ${eligibleCount}`);
  if (!isDryRun) {
    console.log(` Sent: ${sentCount}`);
    console.log(` Failed: ${errorCount}`);
  }
  console.log("==================================================");
}

run().catch((err) => {
  console.error("Fatal error:", err);
  process.exit(1);
});
