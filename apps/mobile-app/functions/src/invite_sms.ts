import {onDocumentCreated, onDocumentUpdated} from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";
import {BEEM_API_KEY, BEEM_SECRET_KEY, sendBeemSms} from "./beem_sms";

/**
 * Staff invitation SMS.
 *
 * When an owner adds a team member (team_screen.dart) or an admin bulk-adds
 * staff (admin quick-setup), a `pendingInvites/{id}` doc is written. This
 * texts the invited person so they know to install the app and sign in with
 * that phone number — onboarding then finds the invite by phone and routes
 * them to team-member setup.
 *
 * Failed sends are retried by retryPendingInviteSms, which runs inside the
 * hourly welcome SMS sweep (no extra Cloud Scheduler job).
 */

const REGION = "us-central1";

// The landing page links to the Play Store. Using it instead of the 66-char
// Play Store URL keeps most invites inside a single SMS part.
const APP_LINK = process.env.INVITE_SMS_APP_LINK || "https://maliup.neuraltale.com";

// One GSM-7 SMS part. Longer messages are billed as 2+ parts.
const SINGLE_SMS_MAX_CHARS = 160;

const MAX_SEND_ATTEMPTS = 3;
// An "in_progress" claim older than this belongs to a run that crashed.
const STALE_CLAIM_MS = 15 * 60 * 1000;
// Don't text about invites older than this — the owner has likely sorted it
// out in person by then.
const RETRY_WINDOW_MS = 3 * 24 * 60 * 60 * 1000;

// Mirrors TeamRole.labelSw in lib/features/team/domain/models/team_member.dart.
// `custom` is left out on purpose: the message then omits the role.
const ROLE_LABEL_SW: Record<string, string> = {
  manager: "Meneja",
  accountant: "Mhasibu",
  cashier: "Keshia",
  stockClerk: "Msimamizi wa Bidhaa",
};

type InviteSmsOutcome = "sent" | "failed" | "abandoned" | "skipped";

/**
 * Mirrors PhoneNumberUtils.canonical in the app. Admin quick-setup stores the
 * phone as typed (e.g. "0712…"), so normalise before sending.
 */
function canonicalPhone(input: unknown): string {
  let digits = String(input ?? "").replace(/\D/g, "");
  if (digits.startsWith("00")) digits = digits.substring(2);
  if (digits.startsWith("0")) return `255${digits.substring(1)}`;
  if (digits.length === 9) return `255${digits}`;
  return digits;
}

export function formatInviteMessage(invite: FirebaseFirestore.DocumentData): string {
  const firstName = String(invite.fullName ?? "").trim().split(/\s+/)[0] || "Mpendwa";
  const businessName = String(invite.businessName ?? "").trim();
  const role = ROLE_LABEL_SW[String(invite.role ?? "")];

  const build = (biz: string, r: string | undefined) =>
    `Habari ${firstName}! Umealikwa kujiunga na ${biz ? `timu ya ${biz}` : "timu"}` +
    `${r ? ` kama ${r}` : ""}. Pakua Mali Up: ${APP_LINK} kisha ingia kwa namba hii ya simu.`;

  // Drop the role, then the business name, until it fits one SMS part.
  const candidates = [build(businessName, role), build(businessName, undefined), build("", undefined)];
  return candidates.find((m) => m.length <= SINGLE_SMS_MAX_CHARS) ?? candidates[candidates.length - 1];
}

/** True while the invite is still open and hasn't been texted successfully. */
function isInviteSmsCandidate(invite: FirebaseFirestore.DocumentData): boolean {
  if (invite.status !== "pending") return false;
  if (invite.inviteSmsStatus === "sent" || invite.inviteSmsStatus === "abandoned") return false;
  return canonicalPhone(invite.phoneNumber).length >= 9;
}

/**
 * Claims, sends and records the invitation SMS for one invite. The claim
 * transaction makes it safe against redelivered trigger events and the
 * retry sweep running at the same time.
 */
async function sendInviteSms(ref: FirebaseFirestore.DocumentReference): Promise<InviteSmsOutcome> {
  const db = admin.firestore();
  const now = Date.now();

  let claimed: FirebaseFirestore.DocumentData | null = null;
  try {
    await db.runTransaction(async (tx) => {
      claimed = null;
      const snap = await tx.get(ref);
      const data = snap.data();
      if (!data || !isInviteSmsCandidate(data)) return;

      if (data.inviteSmsStatus === "in_progress") {
        const lastAttempt = data.inviteSmsLastAttemptAt as FirebaseFirestore.Timestamp | undefined;
        if (lastAttempt && now - lastAttempt.toMillis() < STALE_CLAIM_MS) return;
      }

      tx.update(ref, {
        inviteSmsStatus: "in_progress",
        inviteSmsLastAttemptAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      claimed = data;
    });
  } catch (err) {
    console.error(`[InviteSMS] Could not claim invite ${ref.id}:`, err);
    return "skipped";
  }

  const invite = claimed as FirebaseFirestore.DocumentData | null;
  if (!invite) return "skipped";

  const phone = canonicalPhone(invite.phoneNumber);
  const message = formatInviteMessage(invite);
  const sendResult = await sendBeemSms(phone, message);

  if (sendResult.success) {
    await ref.update({
      inviteSmsStatus: "sent",
      inviteSmsSentAt: admin.firestore.FieldValue.serverTimestamp(),
      inviteSmsPhone: phone,
    });
    console.log(`[InviteSMS] Sent invitation SMS for invite ${ref.id} (${phone})`);
    return "sent";
  }

  const attempts = (invite.inviteSmsAttempts as number | undefined || 0) + 1;
  const status = attempts >= MAX_SEND_ATTEMPTS ? "abandoned" : "failed";
  await ref.update({
    inviteSmsStatus: status,
    inviteSmsAttempts: attempts,
    inviteSmsError: sendResult.error || "Unknown error",
    inviteSmsLastAttemptAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  console.error(`[InviteSMS] Failed to send invitation SMS for invite ${ref.id} (${phone}): ${sendResult.error}`);
  return status;
}

export const onPendingInviteCreatedSms = onDocumentCreated(
  {
    document: "pendingInvites/{inviteId}",
    region: REGION,
    secrets: [BEEM_API_KEY, BEEM_SECRET_KEY],
  },
  async (event) => {
    if (!event.data) return;
    await sendInviteSms(event.data.ref);
  },
);

/**
 * The owner corrected a still-pending member's phone number (team_screen.dart
 * "edit details" updates pendingInvites.phoneNumber). The earlier SMS — sent,
 * failed or abandoned — went to the old number, so reset the SMS state and
 * text the new one with a fresh set of attempts.
 *
 * The reset write re-fires this trigger, but with the phone unchanged it
 * returns immediately.
 */
export const onPendingInvitePhoneChangedSms = onDocumentUpdated(
  {
    document: "pendingInvites/{inviteId}",
    region: REGION,
    secrets: [BEEM_API_KEY, BEEM_SECRET_KEY],
  },
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after || !event.data) return;
    if (after.status !== "pending") return;
    if (canonicalPhone(before.phoneNumber) === canonicalPhone(after.phoneNumber)) return;

    const ref = event.data.after.ref;
    const del = admin.firestore.FieldValue.delete();
    await ref.update({
      inviteSmsStatus: del,
      inviteSmsAttempts: del,
      inviteSmsError: del,
      inviteSmsPhone: del,
      inviteSmsSentAt: del,
      inviteSmsLastAttemptAt: del,
      // Restart the retry sweep's 3-day window for the new number.
      inviteSmsWindowStartAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    console.log(`[InviteSMS] Phone changed on invite ${ref.id}; re-sending to the new number`);
    await sendInviteSms(ref);
  },
);

/**
 * Retries invites whose SMS failed or whose sender crashed mid-send. The
 * query only matches invites that already had a problem, so it reads nothing
 * on a normal day. Called from the hourly welcome SMS sweep, which already
 * has the Beem secrets bound.
 */
export async function retryPendingInviteSms(): Promise<Record<InviteSmsOutcome, number>> {
  const counts: Record<InviteSmsOutcome, number> = {sent: 0, failed: 0, abandoned: 0, skipped: 0};
  const snap = await admin.firestore()
    .collection("pendingInvites")
    .where("inviteSmsStatus", "in", ["failed", "in_progress"])
    .get();

  const cutoff = Date.now() - RETRY_WINDOW_MS;
  for (const doc of snap.docs) {
    const windowStart = (doc.get("inviteSmsWindowStartAt") ?? doc.get("createdAt")) as
      FirebaseFirestore.Timestamp | undefined;
    if (windowStart && windowStart.toMillis() < cutoff) continue;
    counts[await sendInviteSms(doc.ref)]++;
  }
  return counts;
}
