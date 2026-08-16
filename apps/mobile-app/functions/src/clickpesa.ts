import {onCall, HttpsError} from "firebase-functions/v2/https";
import {defineSecret} from "firebase-functions/params";
import * as admin from "firebase-admin";

/**
 * ClickPesa payment gateway integration for Mali Up plan upgrades.
 *
 * All ClickPesa API calls happen here, server-side, using secrets that never
 * ship inside the mobile app binary. The mobile client only ever talks to
 * these two callables — it never sees the ClickPesa API key and it can never
 * write `plan`/`planExpiresAt`/`lastPayment` on its own user doc directly
 * (see firestore.rules). Plan activation happens exclusively in
 * `verifyClickPesaPayment`, via the Admin SDK, after this function has
 * independently confirmed payment with ClickPesa and cross-checked the
 * amount against what was actually quoted.
 */

const CLICKPESA_CLIENT_ID = defineSecret("CLICKPESA_CLIENT_ID");
const CLICKPESA_API_KEY = defineSecret("CLICKPESA_API_KEY");

const CLICKPESA_BASE_URL = "https://api.clickpesa.com/v2";

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

function clickPesaHeaders(): Record<string, string> {
  return {
    "Content-Type": "application/json",
    "Accept": "application/json",
    "Authorization": `Bearer ${CLICKPESA_API_KEY.value()}`,
    "X-Client-Id": CLICKPESA_CLIENT_ID.value(),
  };
}

interface CreatePaymentRequest {
  tier: PayableTier;
  returnUrl?: string;
}

interface CreatePaymentResponse {
  paymentId: string;
  paymentUrl: string;
  reference: string;
  amount: number;
  currency: string;
}

/**
 * Creates a ClickPesa payment for the caller's chosen plan. The amount is
 * always derived server-side from the current admin-configured price —
 * the client only says which tier it wants.
 */
export const createClickPesaPayment = onCall<CreatePaymentRequest>(
  {region: "us-central1", secrets: [CLICKPESA_CLIENT_ID, CLICKPESA_API_KEY]},
  async (request): Promise<CreatePaymentResponse> => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Sign in required.");
    }
    const uid = request.auth.uid;

    const tier = request.data?.tier;
    if (tier !== "growth" && tier !== "business") {
      throw new HttpsError("invalid-argument", "tier must be 'growth' or 'business'.");
    }

    const {pricePerCycle, cycleMonths} = await getPlanPricing(tier);

    const db = admin.firestore();
    const userSnap = await db.collection("users").doc(uid).get();
    const userData = userSnap.data() ?? {};
    const phone =
      typeof userData.phone === "string" && userData.phone ? userData.phone : "+255000000000";
    const email = request.auth.token.email ?? "";
    const name = typeof userData.name === "string" && userData.name ? userData.name : "Mali Up User";

    // Short, still-unique-enough reference: tier + ms timestamp + uid prefix.
    const reference = `MALIUP-${tier.toUpperCase()}-${Date.now().toString().slice(-8)}-${uid.slice(0, 6)}`;
    const returnUrl =
      typeof request.data?.returnUrl === "string" ? request.data.returnUrl : undefined;

    const response = await fetch(`${CLICKPESA_BASE_URL}/payments`, {
      method: "POST",
      headers: clickPesaHeaders(),
      body: JSON.stringify({
        amount: pricePerCycle,
        currency: "TZS",
        reference,
        description: `Mali Up ${tier.toUpperCase()} plan upgrade`,
        customer: {phone, email, name},
        metadata: {tier, userId: uid, paymentRef: reference},
        ...(returnUrl ? {returnUrl} : {}),
      }),
    });

    if (!response.ok) {
      console.error("[ClickPesa] create-payment failed", response.status, await response.text());
      throw new HttpsError("internal", "Failed to create payment.");
    }

    const data = (await response.json()) as {id: string; paymentUrl?: string; url?: string};
    const paymentUrl = data.paymentUrl ?? data.url;
    if (!data.id || !paymentUrl) {
      throw new HttpsError("internal", "ClickPesa returned an unexpected response.");
    }

    // Server-side record of what this payment is *supposed* to be for —
    // verifyClickPesaPayment checks the real ClickPesa status against this,
    // not against anything the client claims.
    await db.collection("clickpesa_payments").doc(data.id).set({
      uid,
      tier,
      cycleMonths,
      amount: pricePerCycle,
      currency: "TZS",
      reference,
      status: "pending",
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return {
      paymentId: data.id,
      paymentUrl,
      reference,
      amount: pricePerCycle,
      currency: "TZS",
    };
  },
);

interface VerifyPaymentRequest {
  paymentId: string;
}

interface VerifyPaymentResponse {
  status: "completed" | "pending" | "failed";
  tier?: PayableTier;
  planExpiresAt?: string; // ISO 8601
}

/**
 * Checks a ClickPesa payment's real status and, the first time it is seen as
 * completed, activates the plan on the caller's own user doc via the Admin
 * SDK. Safe to call repeatedly (the mobile client polls this instead of
 * ClickPesa directly) — already-completed payments short-circuit without
 * re-charging or re-writing anything, and a Firestore transaction guards
 * against two concurrent calls double-activating the same payment.
 */
export const verifyClickPesaPayment = onCall<VerifyPaymentRequest>(
  {region: "us-central1", secrets: [CLICKPESA_CLIENT_ID, CLICKPESA_API_KEY]},
  async (request): Promise<VerifyPaymentResponse> => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Sign in required.");
    }
    const uid = request.auth.uid;

    const paymentId = request.data?.paymentId;
    if (!paymentId || typeof paymentId !== "string") {
      throw new HttpsError("invalid-argument", "paymentId is required.");
    }

    const db = admin.firestore();
    const paymentRef = db.collection("clickpesa_payments").doc(paymentId);
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

    const response = await fetch(`${CLICKPESA_BASE_URL}/payments/${paymentId}`, {
      headers: clickPesaHeaders(),
    });
    if (!response.ok) {
      console.error("[ClickPesa] verify failed", response.status, await response.text());
      throw new HttpsError("internal", "Failed to verify payment.");
    }
    const data = (await response.json()) as {status?: string; amount?: number | string};
    const status = String(data.status ?? "").toLowerCase();

    if (status === "failed" || status === "cancelled" || status === "expired") {
      await paymentRef.set({status: "failed"}, {merge: true});
      return {status: "failed"};
    }
    if (status !== "completed" && status !== "paid") {
      return {status: "pending"};
    }

    const chargedAmount =
      typeof data.amount === "number" ? data.amount : Number(data.amount);
    if (!Number.isFinite(chargedAmount) || chargedAmount !== paymentDoc.amount) {
      console.error("[ClickPesa] amount mismatch — refusing to activate", {
        paymentId,
        chargedAmount,
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
            reference: paymentDoc.reference,
            amount: paymentDoc.amount,
            currency: paymentDoc.currency ?? "TZS",
            paymentId,
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
