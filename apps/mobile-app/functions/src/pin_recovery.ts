import {onCall, HttpsError} from "firebase-functions/v2/https";
import {defineSecret} from "firebase-functions/params";
import * as admin from "firebase-admin";
import * as crypto from "crypto";
import {enforceRateLimit} from "./rate_limit";

/**
 * PIN recovery — the one flow that lets a user who forgot their login PIN
 * regain access.
 *
 * Why this exists as three custom callables instead of Firebase's built-in
 * password reset:
 *  - Every Mali Up account's Firebase Auth email is the derived
 *    `<phone>@mali.up` (see lib/core/utils/phone_number_utils.dart) — a domain
 *    that cannot receive mail. `FirebaseAuth.sendPasswordResetEmail` therefore
 *    either bounces or (with email-enumeration protection on) silently sends
 *    nothing. The user's real email lives only in Firestore `users/{uid}.email`.
 *  - The Auth password is a deterministic HMAC of phone + PIN
 *    (`buildAuthPasswordFromPin`, lib/features/auth/presentation/utils/pin_auth_password.dart).
 *    A stock reset that sets an arbitrary password would still leave
 *    `loginWithPin` broken — recovery has to end by setting the password to
 *    exactly `buildAuthPasswordFromPin(phone, newPin)`.
 *
 * Flow:
 *  1. `requestPinReset({phone, language})` — looks the user up by phone, mints a
 *     one-time token, stores its SHA-256 hash in `pin_reset_tokens/{hash}`
 *     (Admin-SDK-only, see firestore.rules), and emails the real address a
 *     magic link `${PIN_RECOVERY_LINK_BASE}?token=<token>` via Resend.
 *  2. The link is an Android App Link (assetlinks.json on maliup.neuraltale.com)
 *     that opens the app's PinResetScreen. `validatePinResetToken({token})`
 *     confirms the token and returns the canonical phone (the client needs it to
 *     derive the new password).
 *  3. `confirmPinReset({token, newPassword})` — `newPassword` is the
 *     client-computed `buildAuthPasswordFromPin(phone, newPin)` (the pepper/HMAC
 *     stay client-side so pin_auth_password.dart remains the single source of
 *     truth; the server only shape-checks it). Burns the token in a transaction
 *     and calls `admin.auth().updateUser(uid, {password})`. The Auth email is
 *     deliberately left as `<phone>@mali.up` — `loginWithPin` still signs in
 *     against it.
 *
 * All three are callable WITHOUT auth — recovery happens pre-sign-in, exactly
 * like `requestOtpAllowance` (otp_rate_limit.ts). Every entry point is
 * rate-limited by phone and/or caller IP before it does any work.
 *
 * Token cleanup: set a Firestore TTL policy on `pin_reset_tokens.expiresAt`
 * (Console → Firestore → TTL). See PIN_RECOVERY.md.
 */

const RESEND_API_KEY = defineSecret("RESEND_API_KEY");

// Plain (non-secret) env vars — `functions/.env` on deploy, `.env.local` for the
// emulator. Committed template: `.env.example`.
const LINK_BASE =
  process.env.PIN_RECOVERY_LINK_BASE || "https://maliup.neuraltale.com/reset-pin";
const EMAIL_FROM =
  process.env.PIN_RECOVERY_EMAIL_FROM || "Mali Up <security@neuraltale.com>";

const TOKEN_TTL_MS = 30 * 60 * 1000;
const MAX_CONFIRM_ATTEMPTS = 5;

// ─── Phone helpers — mirror lib/core/utils/phone_number_utils.dart ────────────

/** Canonical digits-only international number (Tanzania is the default market). */
function canonicalPhone(input: string): string {
  let digits = input.replace(/\D/g, "");
  if (digits.startsWith("00")) digits = digits.slice(2);
  if (digits.startsWith("0")) return `255${digits.slice(1)}`;
  if (digits.length === 9) return `255${digits}`;
  return digits;
}

/** Every exact value the number may be stored as across schema generations. */
function phoneLookupVariants(input: string): string[] {
  const raw = input.replace(/\D/g, "");
  const canon = canonicalPhone(input);
  const variants = new Set<string>();
  if (canon) {
    variants.add(canon);
    variants.add(`+${canon}`);
  }
  if (raw) {
    variants.add(raw);
    variants.add(`+${raw}`);
  }
  if (canon.startsWith("255") && canon.length > 3) {
    const local = canon.slice(3);
    variants.add(local);
    variants.add(`0${local}`);
  }
  return [...variants];
}

async function findUserByPhone(
  phone: string,
): Promise<FirebaseFirestore.QueryDocumentSnapshot | null> {
  const db = admin.firestore();
  const variants = phoneLookupVariants(phone);
  if (variants.length === 0) return null;
  for (const field of ["phone", "phoneNumber"]) {
    const snap = await db
      .collection("users")
      .where(field, "in", variants)
      .limit(1)
      .get();
    if (!snap.empty) return snap.docs[0];
  }
  return null;
}

// ─── Misc helpers ────────────────────────────────────────────────────────────

function sha256(value: string): string {
  return crypto.createHash("sha256").update(value).digest("hex");
}

/** Mirrors `_maskEmail` in pin_login_screen.dart so the UI copy stays identical. */
function maskEmail(email: string): string {
  if (!email.includes("@")) return email;
  const [user, domain] = email.split("@");
  if (user.length <= 2) return `${"*".repeat(user.length)}@${domain}`;
  return `${user[0]}${"*".repeat(user.length - 2)}${user[user.length - 1]}@${domain}`;
}

function looksLikeDerivedPassword(value: unknown): value is string {
  return (
    typeof value === "string" &&
    value.length >= 20 &&
    value.length <= 200 &&
    !/\s/.test(value) &&
    value.startsWith("Mu2#")
  );
}

// ─── Email ───────────────────────────────────────────────────────────────────

async function sendRecoveryEmail(
  to: string,
  firstName: string,
  link: string,
  language: "sw" | "en",
): Promise<void> {
  const sw = language === "sw";
  const hi = firstName
    ? sw
      ? `Habari ${firstName},`
      : `Hi ${firstName},`
    : sw
      ? "Habari,"
      : "Hi,";
  const subject = sw ? "Weka upya PIN yako ya Mali Up" : "Reset your Mali Up PIN";
  const intro = sw
    ? "Tumepokea ombi la kuweka upya PIN yako ya kuingia Mali Up. Bofya kitufe " +
      "hapa chini ili kuendelea."
    : "We received a request to reset your Mali Up login PIN. Tap the button " +
      "below to continue.";
  const cta = sw ? "Weka upya PIN yangu" : "Reset my PIN";
  const expiry = sw
    ? "Kiungo hiki kitakoma kufanya kazi baada ya dakika 30."
    : "This link stops working after 30 minutes.";
  const ignore = sw
    ? "Kama hukuomba hili, puuza barua pepe hii — PIN yako haitabadilika."
    : "If you didn't request this, ignore this email — your PIN won't change.";

  const html =
    `<!doctype html><html><body style="margin:0;background:#f4f5f7;padding:24px;` +
    `font-family:-apple-system,Segoe UI,Roboto,Helvetica,Arial,sans-serif;color:#0D1B3E">` +
    `<table role="presentation" width="100%" cellpadding="0" cellspacing="0"><tr><td align="center">` +
    `<table role="presentation" width="440" cellpadding="0" cellspacing="0" ` +
    `style="background:#ffffff;border-radius:16px;padding:32px">` +
    `<tr><td style="font-size:20px;font-weight:800;padding-bottom:16px">Mali Up</td></tr>` +
    `<tr><td style="font-size:15px;line-height:1.6;padding-bottom:8px">${hi}</td></tr>` +
    `<tr><td style="font-size:15px;line-height:1.6;padding-bottom:24px">${intro}</td></tr>` +
    `<tr><td style="padding-bottom:24px">` +
    `<a href="${link}" style="display:inline-block;background:#0D1B3E;color:#ffffff;` +
    `text-decoration:none;font-weight:700;font-size:15px;padding:14px 28px;border-radius:12px">` +
    `${cta}</a></td></tr>` +
    `<tr><td style="font-size:13px;line-height:1.6;color:#6b7280;padding-bottom:8px">${expiry}</td></tr>` +
    `<tr><td style="font-size:13px;line-height:1.6;color:#6b7280">${ignore}</td></tr>` +
    `</table></td></tr></table></body></html>`;

  const text = `${hi}\n\n${intro}\n\n${link}\n\n${expiry}\n${ignore}`;

  const response = await fetch("https://api.resend.com/emails", {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${RESEND_API_KEY.value()}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({from: EMAIL_FROM, to, subject, html, text}),
  });

  if (!response.ok) {
    console.error(
      "[pin_recovery] Resend send failed",
      response.status,
      await response.text(),
    );
    throw new HttpsError(
      "internal",
      "Could not send the recovery email. Please try again.",
    );
  }
}

// ─── Callables ───────────────────────────────────────────────────────────────

interface RequestPinResetData {
  phone?: string;
  language?: string;
}

type RequestPinResetResponse =
  | {status: "no_email"}
  | {status: "sent"; maskedEmail: string};

/**
 * Step 1 — send the magic link. Returns `no_email` (indistinguishable from "no
 * account") when there is nothing deliverable to send to, so probing this can't
 * confirm more than the onboarding phone-lookup screen already does.
 */
export const requestPinReset = onCall<RequestPinResetData>(
  {region: "us-central1", secrets: [RESEND_API_KEY]},
  async (request): Promise<RequestPinResetResponse> => {
    const phone = request.data?.phone;
    if (
      !phone ||
      typeof phone !== "string" ||
      phone.length < 8 ||
      phone.length > 20
    ) {
      throw new HttpsError("invalid-argument", "A valid phone number is required.");
    }
    const language: "sw" | "en" = request.data?.language === "en" ? "en" : "sw";
    const ip = request.rawRequest.ip ?? "unknown";

    // Cost/abuse guard BEFORE any work — each success sends a real email.
    await enforceRateLimit({
      collection: "pin_reset_rate_limits_phone",
      key: canonicalPhone(phone),
      windowMs: 15 * 60 * 1000,
      max: 3,
      message: "Too many PIN recovery requests. Please wait before trying again.",
    });
    await enforceRateLimit({
      collection: "pin_reset_rate_limits_ip",
      key: ip,
      windowMs: 60 * 60 * 1000,
      max: 10,
      message: "Too many PIN recovery requests. Please wait before trying again.",
    });

    const userDoc = await findUserByPhone(phone);
    const email =
      (userDoc?.data()?.email as string | undefined)?.trim().toLowerCase() ?? "";
    if (!userDoc || !email || email.endsWith("@mali.up")) {
      return {status: "no_email"};
    }

    const data = userDoc.data() ?? {};
    const firstName =
      (data.firstName as string | undefined)?.trim() ||
      (data.name as string | undefined)?.trim()?.split(/\s+/)[0] ||
      "";

    const token = crypto.randomBytes(32).toString("base64url");
    const now = Date.now();

    await admin
      .firestore()
      .collection("pin_reset_tokens")
      .doc(sha256(token))
      .set({
        uid: userDoc.id,
        phone: canonicalPhone(phone),
        email,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        expiresAt: admin.firestore.Timestamp.fromMillis(now + TOKEN_TTL_MS),
        used: false,
        attempts: 0,
      });

    const link = `${LINK_BASE}?token=${encodeURIComponent(token)}`;
    await sendRecoveryEmail(email, firstName, link, language);

    return {status: "sent", maskedEmail: maskEmail(email)};
  },
);

type ValidateTokenResponse =
  | {valid: false; reason: "invalid" | "used" | "expired"}
  | {valid: true; phone: string; maskedEmail: string};

/**
 * Step 2 — called by PinResetScreen on open. Returns the canonical phone so the
 * client can derive `buildAuthPasswordFromPin(phone, newPin)` locally.
 */
export const validatePinResetToken = onCall<{token?: string}>(
  {region: "us-central1"},
  async (request): Promise<ValidateTokenResponse> => {
    const token = request.data?.token;
    if (
      !token ||
      typeof token !== "string" ||
      token.length < 20 ||
      token.length > 200
    ) {
      throw new HttpsError("invalid-argument", "token is required.");
    }
    await enforceRateLimit({
      collection: "pin_reset_validate_rate_limits_ip",
      key: request.rawRequest.ip ?? "unknown",
      windowMs: 15 * 60 * 1000,
      max: 30,
    });

    const snap = await admin
      .firestore()
      .collection("pin_reset_tokens")
      .doc(sha256(token))
      .get();
    const data = snap.data();
    if (!data) return {valid: false, reason: "invalid"};
    if (data.used === true) return {valid: false, reason: "used"};
    if ((data.expiresAt as admin.firestore.Timestamp).toMillis() < Date.now()) {
      return {valid: false, reason: "expired"};
    }
    return {
      valid: true,
      phone: data.phone as string,
      maskedEmail: maskEmail(data.email as string),
    };
  },
);

/**
 * Step 3 — burn the token and set the new PIN-derived password. `newPassword`
 * is `buildAuthPasswordFromPin(phone, newPin)` computed on the client.
 */
export const confirmPinReset = onCall<{token?: string; newPassword?: string}>(
  {region: "us-central1"},
  async (request): Promise<{ok: true}> => {
    const token = request.data?.token;
    if (!token || typeof token !== "string") {
      throw new HttpsError("invalid-argument", "token is required.");
    }
    const newPassword = request.data?.newPassword;
    if (!looksLikeDerivedPassword(newPassword)) {
      throw new HttpsError("invalid-argument", "newPassword is malformed.");
    }

    await enforceRateLimit({
      collection: "pin_reset_validate_rate_limits_ip",
      key: request.rawRequest.ip ?? "unknown",
      windowMs: 15 * 60 * 1000,
      max: 30,
    });

    const db = admin.firestore();
    const ref = db.collection("pin_reset_tokens").doc(sha256(token));

    const uid = await db.runTransaction(async (tx) => {
      const data = (await tx.get(ref)).data();
      if (!data) {
        throw new HttpsError(
          "failed-precondition",
          "This reset link has expired. Please request a new one.",
        );
      }
      if (data.used === true) {
        throw new HttpsError(
          "failed-precondition",
          "This reset link has already been used. Please request a new one.",
        );
      }
      if ((data.expiresAt as admin.firestore.Timestamp).toMillis() < Date.now()) {
        throw new HttpsError(
          "failed-precondition",
          "This reset link has expired. Please request a new one.",
        );
      }
      if ((data.attempts ?? 0) >= MAX_CONFIRM_ATTEMPTS) {
        throw new HttpsError(
          "resource-exhausted",
          "Too many attempts. Please request a new recovery link.",
        );
      }
      tx.update(ref, {
        used: true,
        usedAt: admin.firestore.FieldValue.serverTimestamp(),
        attempts: (data.attempts ?? 0) + 1,
      });
      return data.uid as string;
    });

    try {
      await admin.auth().updateUser(uid, {password: newPassword});
    } catch (err) {
      console.error("[pin_recovery] updateUser failed", uid, err);
      // Let the same link be retried on a transient Auth failure — the attempts
      // counter still incremented, so this can't loop forever.
      await ref.update({used: false}).catch(() => {});
      throw new HttpsError(
        "internal",
        "Could not update your PIN. Please try again.",
      );
    }

    return {ok: true};
  },
);
