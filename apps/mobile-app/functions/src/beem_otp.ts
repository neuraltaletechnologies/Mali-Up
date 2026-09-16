import {onCall, HttpsError} from "firebase-functions/v2/https";
import {defineSecret} from "firebase-functions/params";
import * as admin from "firebase-admin";
import {enforceRateLimit} from "./rate_limit";

/**
 * Phone OTP verification for first-time registration (new owner + team
 * member first PIN setup — see security_setup_screen.dart / team_member_
 * setup_screen.dart), using Beem Africa's dedicated OTP product. Beem
 * generates, delivers and verifies the actual code server-side on its own
 * infrastructure — this file only proxies the two calls with our credentials
 * attached (never shipped in the app binary) and records a short-lived
 * "this phone was verified" marker that createNewUserAccount /
 * createTeamMemberAccount consume before creating the Firebase Auth account.
 *
 * Endpoints verified against https://docs.beem.africa/guides/otp (and the
 * request/response field names against Beem's own official Laravel SDK,
 * bryceandy/laravel-beem, src/Traits/Otp/HandlesOtp.php) — not guessed:
 *   POST https://apiotp.beem.africa/v1/request  { appId, msisdn } -> { data: { pinId, message: { code, message }, pinExpiryTimeInMinutes, expiresInSeconds } }
 *   POST https://apiotp.beem.africa/v1/verify   { pinId, pin }    -> { data: { message: { code, message } } }  (code 117 = verified)
 * Auth: `Authorization: Basic base64(BEEM_API_KEY:BEEM_SECRET_KEY)`, same
 * Secret Manager pattern as CLICKPESA_CLIENT_ID/CLICKPESA_API_KEY.
 */

const BEEM_API_KEY = defineSecret("BEEM_API_KEY");
const BEEM_SECRET_KEY = defineSecret("BEEM_SECRET_KEY");

const BEEM_OTP_BASE_URL = "https://apiotp.beem.africa/v1";
const BEEM_VERIFIED_SUCCESS_CODE = 117;

// How long a verified phone stays usable to complete registration — long
// enough to cover the rest of onboarding (business details were already
// filled in before this step) without leaving a stale marker around.
const OTP_VERIFIED_TTL_MS = 30 * 60 * 1000;

function beemAuthHeader(): string {
  return "Basic " + Buffer.from(`${BEEM_API_KEY.value()}:${BEEM_SECRET_KEY.value()}`).toString("base64");
}

/** Strips everything but digits — defensive re-derivation even though the
 * client always sends PhoneNumberUtils.canonical(phone) already. */
function digitsOnly(phone: unknown): string {
  return String(phone ?? "").replace(/\D/g, "");
}

/**
 * When called by a signed-in user (the "already-registered account must
 * re-verify" path — see PinLoginScreen), the phone being sent/verified must
 * be the phone already on that account's own users/{uid} doc. Without this,
 * a signed-in user could verify any phone they personally control and have
 * it count as proof of ownership of their *account's* registered number,
 * which defeats the point of re-verifying existing accounts. Pre-auth calls
 * (first-time registration, before the Firebase Auth account exists) skip
 * this — there's no account yet to compare against.
 */
async function assertOwnPhoneIfAuthenticated(uid: string | undefined, phone: string): Promise<void> {
  if (!uid) return;
  const snap = await admin.firestore().collection("users").doc(uid).get();
  if (snap.data()?.phone !== phone) {
    throw new HttpsError("permission-denied", "Phone number does not match your account.");
  }
}

interface SendOtpRequest {
  phone: string;
}

interface SendOtpResponse {
  pinId: string;
  expiresInSeconds: number;
}

/**
 * Requests a Beem OTP be sent to `phone`. Callable without auth — this runs
 * pre-sign-in, before the Firebase Auth account exists, mirroring the
 * pre-auth phone lookup already allowed in firestore.rules (isLimitedLookup).
 */
export const sendBeemOtp = onCall<SendOtpRequest>(
  {region: "us-central1", secrets: [BEEM_API_KEY, BEEM_SECRET_KEY]},
  async (request): Promise<SendOtpResponse> => {
    const phone = digitsOnly(request.data?.phone);
    if (phone.length < 9 || phone.length > 15) {
      throw new HttpsError("invalid-argument", "A valid phone number is required.");
    }
    await assertOwnPhoneIfAuthenticated(request.auth?.uid, phone);

    const appId = process.env.BEEM_OTP_APP_ID;
    if (!appId) {
      console.error("[BeemOtp] BEEM_OTP_APP_ID is not configured");
      throw new HttpsError("internal", "OTP is not configured.");
    }

    // Every send costs real Beem SMS credit — same cost concern as the old
    // Firebase-phone-auth OTP gate (see otp_rate_limit.ts, now unused). Two
    // independent windows per phone (short burst + daily cap) plus one per
    // caller IP, all via the shared transaction-backed limiter.
    await enforceRateLimit({
      collection: "beem_otp_send_rate_limits_phone_short",
      key: phone,
      windowMs: 15 * 60 * 1000,
      max: 3,
      message: "Too many verification code requests. Please wait a few minutes and try again.",
    });
    await enforceRateLimit({
      collection: "beem_otp_send_rate_limits_phone_daily",
      key: phone,
      windowMs: 24 * 60 * 60 * 1000,
      max: 8,
      message: "Too many verification code requests for this number today. Please try again tomorrow.",
    });
    const ip = request.rawRequest.ip ?? "unknown";
    await enforceRateLimit({
      collection: "beem_otp_send_rate_limits_ip",
      key: ip,
      windowMs: 60 * 60 * 1000,
      max: 20,
      message: "Too many verification code requests. Please wait before trying again.",
    });

    const response = await fetch(`${BEEM_OTP_BASE_URL}/request`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": beemAuthHeader(),
      },
      body: JSON.stringify({appId, msisdn: phone}),
    });

    if (!response.ok) {
      console.error("[BeemOtp] request failed", response.status, await response.text());
      throw new HttpsError("internal", "Could not send the verification code. Please try again.");
    }

    const body = (await response.json()) as {
      data?: {pinId?: string; message?: {code?: number; message?: string}; expiresInSeconds?: number};
    };
    const pinId = body.data?.pinId;
    if (!pinId) {
      console.error("[BeemOtp] request succeeded with no pinId", body);
      throw new HttpsError("internal", "Could not send the verification code. Please try again.");
    }

    return {
      pinId,
      expiresInSeconds: body.data?.expiresInSeconds ?? 5 * 60,
    };
  },
);

interface VerifyOtpRequest {
  phone: string;
  pinId: string;
  pin: string;
}

interface VerifyOtpResponse {
  verified: boolean;
}

/**
 * Verifies `pin` against `pinId` with Beem. Serves two callers:
 *  - Pre-auth (first-time registration, no Firebase Auth account yet): on
 *    success, records a short-lived marker at otp_verifications/{phone} that
 *    createNewUserAccount / createTeamMemberAccount must consume
 *    (consumeOtpVerification) before creating the account.
 *  - Authenticated (an already-registered account predating the Beem OTP
 *    rollout, re-verifying on login — see PinLoginScreen): on success,
 *    stamps users/{uid}.phoneVerified = true directly via the Admin SDK
 *    (firestore.rules blocks clients from setting that field themselves).
 *    No otp_verifications marker needed here — the account already exists,
 *    there's no subsequent creation step to gate.
 */
export const verifyBeemOtp = onCall<VerifyOtpRequest>(
  {region: "us-central1", secrets: [BEEM_API_KEY, BEEM_SECRET_KEY]},
  async (request): Promise<VerifyOtpResponse> => {
    const phone = digitsOnly(request.data?.phone);
    const pinId = String(request.data?.pinId ?? "").trim();
    const pin = String(request.data?.pin ?? "").trim();
    if (phone.length < 9 || phone.length > 15) {
      throw new HttpsError("invalid-argument", "A valid phone number is required.");
    }
    if (!pinId) {
      throw new HttpsError("invalid-argument", "pinId is required.");
    }
    if (!/^\d{4,8}$/.test(pin)) {
      throw new HttpsError("invalid-argument", "A valid verification code is required.");
    }
    await assertOwnPhoneIfAuthenticated(request.auth?.uid, phone);

    // Caps brute-forcing Beem's own (short) pin against a captured pinId.
    await enforceRateLimit({
      collection: "beem_otp_verify_rate_limits_phone",
      key: phone,
      windowMs: 10 * 60 * 1000,
      max: 5,
      message: "Too many attempts. Please request a new code and try again.",
    });

    const response = await fetch(`${BEEM_OTP_BASE_URL}/verify`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": beemAuthHeader(),
      },
      body: JSON.stringify({pinId, pin}),
    });

    // Beem responds 200 for a verified pin and (per its OpenAPI spec) 403 for
    // a rejected one — both share the same { data: { message: { code } } }
    // shape. Anything else (5xx, network failure) is a real transport error,
    // not a "wrong code", so it must not be reported to the user as one.
    if (!response.ok && response.status !== 403) {
      console.error("[BeemOtp] verify failed", response.status, await response.text());
      throw new HttpsError("internal", "Could not verify the code. Please try again.");
    }

    const body = (await response.json()) as {data?: {message?: {code?: number; message?: string}}};
    const verified = response.ok && body.data?.message?.code === BEEM_VERIFIED_SUCCESS_CODE;

    if (verified) {
      if (request.auth?.uid) {
        await admin
          .firestore()
          .collection("users")
          .doc(request.auth.uid)
          .set({phoneVerified: true}, {merge: true});
      } else {
        await admin
          .firestore()
          .collection("otp_verifications")
          .doc(phone)
          .set({
            verifiedAt: admin.firestore.FieldValue.serverTimestamp(),
            expiresAtMs: Date.now() + OTP_VERIFIED_TTL_MS,
          });
      }
    }

    return {verified};
  },
);

interface ConsumeOtpRequest {
  phone: string;
}

interface ConsumeOtpResponse {
  ok: true;
}

/**
 * Called by OnboardingRepository.createNewUserAccount / createTeamMemberAccount
 * immediately before creating the Firebase Auth account. Burns the
 * otp_verifications marker so it can't be reused, and fails closed if it's
 * missing or expired — Firebase Auth account creation itself is a direct
 * client SDK call with no server hook, so this is the one enforcement point
 * that a signed-in-but-unverified client can't route around without also
 * skipping this callable entirely (same trust boundary as the rest of the
 * onboarding flow's step guards, which are otherwise client-state-driven).
 */
export const consumeOtpVerification = onCall<ConsumeOtpRequest>(
  {region: "us-central1"},
  async (request): Promise<ConsumeOtpResponse> => {
    const phone = digitsOnly(request.data?.phone);
    if (phone.length < 9 || phone.length > 15) {
      throw new HttpsError("invalid-argument", "A valid phone number is required.");
    }

    const ref = admin.firestore().collection("otp_verifications").doc(phone);
    const snap = await ref.get();
    const expiresAtMs = snap.data()?.expiresAtMs as number | undefined;
    if (!snap.exists || !expiresAtMs || expiresAtMs < Date.now()) {
      throw new HttpsError(
        "failed-precondition",
        "Phone verification has expired. Please verify your number again.",
      );
    }

    await ref.delete();
    return {ok: true};
  },
);
