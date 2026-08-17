import {onCall, HttpsError} from "firebase-functions/v2/https";
import {defineSecret} from "firebase-functions/params";
import * as admin from "firebase-admin";
import * as crypto from "crypto";

/**
 * ClickPesa payment gateway integration for Mali Up plan upgrades, using
 * ClickPesa's USSD-Push API: the user picks a plan, we push a mobile-money
 * prompt straight to their phone (M-Pesa/Tigo Pesa/Airtel Money/HaloPesa),
 * they enter their PIN on the phone itself, and the plan activates the
 * moment ClickPesa confirms the charge. No browser hop involved.
 *
 * Endpoints and payload shapes below are verified against
 * https://docs.clickpesa.com (generate-token, initiate-ussd-push-request,
 * querying-for-payments) — not guessed. All ClickPesa API calls happen here,
 * server-side, using secrets that never ship inside the mobile app binary.
 * The mobile client only ever talks to these two callables — it never sees
 * the ClickPesa API key and it can never write
 * `plan`/`planExpiresAt`/`lastPayment` on its own user doc directly (see
 * firestore.rules). Plan activation happens exclusively in
 * `verifyClickPesaPayment`, via the Admin SDK, after this function has
 * independently confirmed payment with ClickPesa and cross-checked the
 * amount against what was actually quoted.
 */

const CLICKPESA_CLIENT_ID = defineSecret("CLICKPESA_CLIENT_ID");
const CLICKPESA_API_KEY = defineSecret("CLICKPESA_API_KEY");

const CLICKPESA_BASE_URL = "https://api.clickpesa.com/third-parties";

type PayableTier = "growth" | "business";

// Mirrors lib/core/services/plan_service.dart's `_fallbackLimits` — used only
// when platform_config/plans is unreachable or missing a field.
const FALLBACK_PRICING: Record<PayableTier, {pricePerCycle: number; cycleMonths: number}> = {
  growth: {pricePerCycle: 30000, cycleMonths: 6},
  business: {pricePerCycle: 40000, cycleMonths: 6},
};

interface PlanPricing {
  pricePerCycle: number;
  cycleMonths: number;
}

/**
 * Reads the *current* admin-configured price for a tier from
 * platform_config/plans (the same doc the app's paywall reads to display
 * pricing), falling back to the hardcoded defaults if the doc/field is
 * missing. The price actually charged always comes from here — never from
 * a client-supplied amount — so a user cannot ask ClickPesa to charge less
 * than the real price by tampering with the app.
 */
async function getPlanPricing(tier: PayableTier): Promise<PlanPricing> {
  const fallback = FALLBACK_PRICING[tier];
  try {
    const snap = await admin.firestore().collection("platform_config").doc("plans").get();
    const raw = snap.data()?.[tier];
    if (raw && typeof raw === "object") {
      const pricePerCycle =
        typeof raw.pricePerCycle === "number" ? raw.pricePerCycle : fallback.pricePerCycle;
      const cycleMonths =
        typeof raw.cycleMonths === "number" ? raw.cycleMonths : fallback.cycleMonths;
      if (pricePerCycle > 0 && cycleMonths > 0) return {pricePerCycle, cycleMonths};
    }
  } catch (err) {
    console.error("[ClickPesa] Failed to load plan pricing, using fallback", err);
  }
  return fallback;
}

// ── ClickPesa auth token (module-level cache, reused across warm Cloud
// Functions instances — the token is valid for 1 hour) ──────────────────────
let cachedToken: {token: string; expiresAt: number} | null = null;

async function getClickPesaToken(): Promise<string> {
  const now = Date.now();
  if (cachedToken && cachedToken.expiresAt > now) return cachedToken.token;

  const response = await fetch(`${CLICKPESA_BASE_URL}/generate-token`, {
    method: "POST",
    headers: {
      "client-id": CLICKPESA_CLIENT_ID.value(),
      "api-key": CLICKPESA_API_KEY.value(),
    },
  });
  if (!response.ok) {
    console.error("[ClickPesa] generate-token failed", response.status, await response.text());
    throw new HttpsError("internal", "Failed to authenticate with payment provider.");
  }
  const data = (await response.json()) as {success?: boolean; token?: string};
  if (!data.token) {
    throw new HttpsError("internal", "Payment provider returned no token.");
  }
  // Refresh a few minutes early so a call never lands right at the edge of
  // expiry.
  cachedToken = {token: data.token, expiresAt: now + 50 * 60 * 1000};
  return data.token;
}

/** Recursively sorts object keys — required before hashing, per ClickPesa's
 * checksum spec (order-independent canonical form). */
function canonicalize(value: unknown): unknown {
  if (value === null || typeof value !== "object") return value;
  if (Array.isArray(value)) return value.map(canonicalize);
  return Object.keys(value as Record<string, unknown>)
    .sort()
    .reduce((acc: Record<string, unknown>, key) => {
      acc[key] = canonicalize((value as Record<string, unknown>)[key]);
      return acc;
    }, {});
}

/**
 * Computes ClickPesa's optional payload checksum: HMAC-SHA256 over the
 * canonicalized, whitespace-free JSON payload, keyed with the application's
 * checksum key. Returns null (caller omits the field) when no checksum key
 * is configured — checksum validation is opt-in per ClickPesa application
 * (Settings → Developers → Checksum in the ClickPesa dashboard). Deliberately
 * read from a plain (non-secret) env var, not `defineSecret`, so leaving it
 * unset never blocks deployment — set `CLICKPESA_CHECKSUM_KEY` in
 * `functions/.env` (or `.secret.local` for the emulator) only if checksum
 * validation is turned on for this application.
 */
function checksumFor(payload: Record<string, unknown>): string | null {
  const key = process.env.CLICKPESA_CHECKSUM_KEY;
  if (!key) return null;
  const serialized = JSON.stringify(canonicalize(payload));
  return crypto.createHmac("sha256", key).update(serialized).digest("hex");
}

/**
 * Normalizes a Tanzanian mobile number to ClickPesa's expected
 * "255XXXXXXXXX" form (12 digits, no leading +/0). Returns null for
 * anything that doesn't look like a real Tanzanian mobile money number —
 * callers must reject rather than silently push to a placeholder number.
 */
function normalizeTzPhone(raw: string): string | null {
  const digits = raw.replace(/\D/g, "");
  let normalized: string;
  if (digits.length === 12 && digits.startsWith("255")) {
    normalized = digits;
  } else if (digits.length === 10 && digits.startsWith("0")) {
    normalized = `255${digits.slice(1)}`;
  } else if (digits.length === 9) {
    normalized = `255${digits}`;
  } else {
    return null;
  }
  // Tanzanian mobile numbers start 06 or 07 after the country code.
  return /^255[67]\d{8}$/.test(normalized) ? normalized : null;
}

interface InitiatePaymentRequest {
  tier: PayableTier;
  phoneNumber: string;
}

interface InitiatePaymentResponse {
  orderReference: string;
  status: string;
  channel?: string;
}

/**
 * Pushes a USSD mobile-money payment prompt to the caller's phone for their
 * chosen plan. The amount is always derived server-side from the current
 * admin-configured price — the client only says which tier it wants and
 * which phone number to push to.
 */
export const initiateClickPesaPayment = onCall<InitiatePaymentRequest>(
  {region: "us-central1", secrets: [CLICKPESA_CLIENT_ID, CLICKPESA_API_KEY]},
  async (request): Promise<InitiatePaymentResponse> => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Sign in required.");
    }
    const uid = request.auth.uid;

    const tier = request.data?.tier;
    if (tier !== "growth" && tier !== "business") {
      throw new HttpsError("invalid-argument", "tier must be 'growth' or 'business'.");
    }
    const phoneNumber = normalizeTzPhone(String(request.data?.phoneNumber ?? ""));
    if (!phoneNumber) {
      throw new HttpsError(
        "invalid-argument",
        "A valid Tanzanian mobile money number (M-Pesa/Tigo Pesa/Airtel Money/HaloPesa) is required.",
      );
    }

    const {pricePerCycle, cycleMonths} = await getPlanPricing(tier);

    // Alphanumeric only, per ClickPesa's orderReference requirement.
    const orderReference = `MALIUP${tier.toUpperCase()}${Date.now().toString().slice(-8)}${uid
      .slice(0, 6)
      .toUpperCase()}`.replace(/[^A-Z0-9]/gi, "");

    const token = await getClickPesaToken();
    const body: Record<string, unknown> = {
      amount: String(pricePerCycle),
      currency: "TZS",
      orderReference,
      phoneNumber,
    };
    const checksum = checksumFor(body);
    if (checksum) body.checksum = checksum;

    const response = await fetch(`${CLICKPESA_BASE_URL}/payments/initiate-ussd-push-request`, {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${token}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(body),
    });

    if (!response.ok) {
      const text = await response.text();
      console.error("[ClickPesa] initiate-ussd-push failed", response.status, text);
      if (response.status === 409) {
        throw new HttpsError("already-exists", "A payment with this reference already exists.");
      }
      if (response.status === 400) {
        throw new HttpsError("invalid-argument", "ClickPesa rejected the request — check the phone number.");
      }
      throw new HttpsError("internal", "Failed to start payment.");
    }
    const data = (await response.json()) as {id?: string; status?: string; channel?: string};

    // Server-side record of what this payment is *supposed* to be for —
    // verifyClickPesaPayment checks the real ClickPesa status against this,
    // not against anything the client claims.
    await admin
      .firestore()
      .collection("clickpesa_payments")
      .doc(orderReference)
      .set({
        uid,
        tier,
        cycleMonths,
        amount: pricePerCycle,
        currency: "TZS",
        phoneNumber,
        clickPesaId: data.id ?? null,
        status: "pending",
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

    return {
      orderReference,
      status: data.status ?? "PROCESSING",
      channel: data.channel,
    };
  },
);

interface VerifyPaymentRequest {
  orderReference: string;
}

interface VerifyPaymentResponse {
  status: "completed" | "pending" | "failed";
  tier?: PayableTier;
  planExpiresAt?: string; // ISO 8601
}

/**
 * Checks a ClickPesa payment's real status and, the first time it is seen as
 * completed, activates the plan on the caller's own user doc via the Admin
 * SDK. Safe to call repeatedly (the mobile client polls this while the user
 * confirms the PIN prompt on their phone) — already-completed payments
 * short-circuit without re-writing anything, and a Firestore transaction
 * guards against two concurrent calls double-activating the same payment.
 */
export const verifyClickPesaPayment = onCall<VerifyPaymentRequest>(
  {region: "us-central1", secrets: [CLICKPESA_CLIENT_ID, CLICKPESA_API_KEY]},
  async (request): Promise<VerifyPaymentResponse> => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Sign in required.");
    }
    const uid = request.auth.uid;

    const orderReference = request.data?.orderReference;
    if (!orderReference || typeof orderReference !== "string") {
      throw new HttpsError("invalid-argument", "orderReference is required.");
    }

    const db = admin.firestore();
    const paymentRef = db.collection("clickpesa_payments").doc(orderReference);
    const paymentSnap = await paymentRef.get();
    if (!paymentSnap.exists) {
      throw new HttpsError("not-found", "Unknown payment.");
    }
    const paymentDoc = paymentSnap.data()!;
    if (paymentDoc.uid !== uid) {
      throw new HttpsError("permission-denied", "This payment does not belong to you.");
    }

    if (paymentDoc.status === "completed") {
      return {
        status: "completed",
        tier: paymentDoc.tier,
        planExpiresAt: paymentDoc.planExpiresAt,
      };
    }
    if (paymentDoc.status === "failed") {
      return {status: "failed"};
    }

    const token = await getClickPesaToken();
    const response = await fetch(`${CLICKPESA_BASE_URL}/payments/${orderReference}`, {
      headers: {"Authorization": `Bearer ${token}`},
    });
    if (!response.ok) {
      console.error("[ClickPesa] query payment failed", response.status, await response.text());
      throw new HttpsError("internal", "Failed to check payment status.");
    }
    // ClickPesa returns an array of payment attempts for this orderReference.
    const results = (await response.json()) as Array<{
      status?: string;
      collectedAmount?: number | string;
    }>;
    const payment = results[0];
    if (!payment) {
      return {status: "pending"};
    }

    const status = String(payment.status ?? "").toUpperCase();
    if (status === "FAILED") {
      await paymentRef.set({status: "failed"}, {merge: true});
      return {status: "failed"};
    }
    if (status !== "SUCCESS" && status !== "SETTLED") {
      return {status: "pending"};
    }

    const collectedAmount =
      typeof payment.collectedAmount === "number"
        ? payment.collectedAmount
        : Number(payment.collectedAmount);
    if (!Number.isFinite(collectedAmount) || collectedAmount !== paymentDoc.amount) {
      console.error("[ClickPesa] amount mismatch — refusing to activate", {
        orderReference,
        collectedAmount,
        expected: paymentDoc.amount,
      });
      throw new HttpsError("failed-precondition", "Payment amount mismatch.");
    }

    const tier = paymentDoc.tier as PayableTier;
    const cycleMonths = paymentDoc.cycleMonths as number;
    const expiresAt = new Date(Date.now() + 30 * cycleMonths * 24 * 60 * 60 * 1000);
    const expiresAtIso = expiresAt.toISOString();

    await db.runTransaction(async (tx) => {
      const freshSnap = await tx.get(paymentRef);
      if (freshSnap.data()?.status === "completed") return; // concurrent call already activated it

      tx.set(
        paymentRef,
        {
          status: "completed",
          completedAt: admin.firestore.FieldValue.serverTimestamp(),
          planExpiresAt: expiresAtIso,
        },
        {merge: true},
      );
      tx.set(
        db.collection("users").doc(uid),
        {
          plan: tier,
          planExpiresAt: admin.firestore.Timestamp.fromDate(expiresAt),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          lastPayment: {
            reference: orderReference,
            amount: paymentDoc.amount,
            currency: paymentDoc.currency ?? "TZS",
            paymentId: paymentDoc.clickPesaId ?? orderReference,
            paidAt: admin.firestore.FieldValue.serverTimestamp(),
            provider: "clickpesa",
          },
        },
        {merge: true},
      );
    });

    console.log(`[ClickPesa] Plan activated for user ${uid}: ${tier}`);
    return {status: "completed", tier, planExpiresAt: expiresAtIso};
  },
);
