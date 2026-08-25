import {onCall, HttpsError} from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import * as crypto from "crypto";

/**
 * Server-side gate in front of Firebase Phone Auth's SMS send.
 *
 * The client's 60-second resend countdown (PhoneAuthService) is UI only —
 * anything that calls `FirebaseAuth.verifyPhoneNumber` directly, bypassing
 * the app, ignores it completely. Every SMS OTP costs real money per send
 * (Tanzania is a paid-tier country, not covered by any free MAU quota), so
 * an unthrottled resend loop is a direct line from a script to our Firebase
 * bill. The client now calls `requestOtpAllowance` here BEFORE calling
 * verifyPhoneNumber; only a Firestore-side counter — not the client — decides
 * whether the SMS actually gets sent.
 *
 * Two independent windows, both enforced atomically in one transaction:
 *  - per phone number: guards one number being hammered (the direct cost driver).
 *  - per caller IP: guards one source spraying OTP requests across many
 *    numbers. The threshold is deliberately loose — Tanzanian mobile carriers
 *    commonly NAT many genuine users behind one public IP, and a false
 *    positive here blocks real signups. Tune via the constants below once
 *    real traffic patterns are visible in the `otp_rate_limits_ip` collection.
 *
 * Both counter collections are written only via the Admin SDK (this
 * function) — firestore.rules denies all client read/write to them via the
 * default-deny fallback, so a client cannot reset or inspect its own count.
 */

const PHONE_WINDOW_MS = 15 * 60 * 1000; // 15 minutes
const PHONE_WINDOW_MAX = 3; // OTP sends per phone per window
const PHONE_DAILY_WINDOW_MS = 24 * 60 * 60 * 1000;
const PHONE_DAILY_MAX = 8; // hard daily cap per phone, survives short-window resets

const IP_WINDOW_MS = 60 * 60 * 1000; // 1 hour
const IP_WINDOW_MAX = 20; // OTP sends per IP per window — intentionally generous, see above

interface RequestOtpAllowanceRequest {
  phone: string;
}

interface RequestOtpAllowanceResponse {
  allowed: true;
}

function hashKey(value: string): string {
  return crypto.createHash("sha256").update(value).digest("hex");
}

/** Fixed-window counter shared by both the phone and IP checks. */
interface WindowCounter {
  windowStart: number;
  count: number;
}

function bumpWindow(
  existing: WindowCounter | undefined,
  now: number,
  windowMs: number,
): WindowCounter {
  if (!existing || now - existing.windowStart >= windowMs) {
    return {windowStart: now, count: 1};
  }
  return {windowStart: existing.windowStart, count: existing.count + 1};
}

/**
 * Called by PhoneAuthService.sendOTP immediately before verifyPhoneNumber.
 * Deliberately callable without auth — OTP requests happen pre-sign-in for
 * both registration and login, mirroring the pre-auth phone lookups already
 * allowed in firestore.rules (isLimitedLookup).
 */
export const requestOtpAllowance = onCall<RequestOtpAllowanceRequest>(
  {region: "us-central1"},
  async (request): Promise<RequestOtpAllowanceResponse> => {
    const phone = request.data?.phone;
    if (!phone || typeof phone !== "string" || phone.length < 8 || phone.length > 20) {
      throw new HttpsError("invalid-argument", "A valid phone number is required.");
    }

    // request.rawRequest.ip is the immediate peer — Cloud Functions v2 runs
    // behind Google's front end, which already strips/normalizes this to the
    // real caller, so it isn't client-spoofable the way an X-Forwarded-For
    // header would be.
    const ip = request.rawRequest.ip ?? "unknown";

    const db = admin.firestore();
    const phoneRef = db.collection("otp_rate_limits").doc(hashKey(phone));
    const ipRef = db.collection("otp_rate_limits_ip").doc(hashKey(ip));
    const now = Date.now();

    await db.runTransaction(async (tx) => {
      const [phoneSnap, ipSnap] = await Promise.all([tx.get(phoneRef), tx.get(ipRef)]);
      const phoneData = phoneSnap.data() as
        | {short?: WindowCounter; daily?: WindowCounter}
        | undefined;
      const ipData = ipSnap.data() as WindowCounter | undefined;

      const shortWindow = bumpWindow(phoneData?.short, now, PHONE_WINDOW_MS);
      const dailyWindow = bumpWindow(phoneData?.daily, now, PHONE_DAILY_WINDOW_MS);
      const ipWindow = bumpWindow(ipData, now, IP_WINDOW_MS);

      // Reject BEFORE writing the bumped counters, so a denied attempt
      // doesn't itself consume another slot once the caller retries.
      if (
        (phoneData?.short && phoneData.short.count >= PHONE_WINDOW_MAX &&
          now - phoneData.short.windowStart < PHONE_WINDOW_MS) ||
        (phoneData?.daily && phoneData.daily.count >= PHONE_DAILY_MAX &&
          now - phoneData.daily.windowStart < PHONE_DAILY_WINDOW_MS) ||
        (ipData && ipData.count >= IP_WINDOW_MAX && now - ipData.windowStart < IP_WINDOW_MS)
      ) {
        throw new HttpsError(
          "resource-exhausted",
          "Too many verification code requests. Please wait before trying again.",
        );
      }

      tx.set(phoneRef, {short: shortWindow, daily: dailyWindow, updatedAt: now}, {merge: true});
      tx.set(ipRef, {...ipWindow, updatedAt: now}, {merge: true});
    });

    return {allowed: true};
  },
);
