import {onCall, onRequest, HttpsError} from "firebase-functions/v2/https";
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
  // ClickPesa's response already includes the "Bearer " prefix in the token
  // string itself (e.g. `"token": "Bearer eyJhbGc..."`) — strip it here so
  // every caller can uniformly do `Authorization: Bearer ${token}` without
  // ending up with a malformed doubled-up "Bearer Bearer ..." header (which
  // ClickPesa's API silently rejects with a 401, not a helpful error).
  const rawToken = data.token.replace(/^Bearer\s+/i, "");
  // Refresh a few minutes early so a call never lands right at the edge of
  // expiry.
  cachedToken = {token: rawToken, expiresAt: now + 50 * 60 * 1000};
  return rawToken;
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

    // Alphanumeric only, and ClickPesa caps this at 20 characters — base36
    // the timestamp to keep it compact: "MP" + tier initial (1) + ms epoch
    // in base36 (~8) + a slice of the uid (4) = ~15 chars, comfortably under
    // the limit while staying unique and still traceable back to the user.
    const orderReference = `MP${tier === "growth" ? "G" : "B"}${Date.now()
      .toString(36)}${uid.slice(0, 4)}`
      .toUpperCase()
      .replace(/[^A-Z0-9]/g, "")
      .slice(0, 20);

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
        // ClickPesa's 400s cover several unrelated cases (bad phone number,
        // a payment method not enabled on this application, etc.) — surface
        // its actual message instead of guessing, so this doesn't keep
        // sending users to check their phone number for a merchant-account
        // configuration problem that has nothing to do with them.
        let providerMessage: string | undefined;
        try {
          providerMessage = (JSON.parse(text) as {message?: string}).message;
        } catch {
          // Non-JSON body — fall through to the generic message below.
        }
        throw new HttpsError(
          "invalid-argument",
          providerMessage
            ? `Payment could not be started: ${providerMessage}`
            : "ClickPesa rejected the request — check the phone number.",
        );
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

// Minimum time between two real ClickPesa status checks for the *same*
// still-pending payment. Exists so a burst of duplicate webhook deliveries,
// or a client that somehow polls too fast, can't multiply into repeated
// ClickPesa API calls for one payment — see the module doc for why every
// call here is precious (ClickPesa's free/pre-KYC tier caps at 100/day).
const MIN_RECHECK_INTERVAL_MS = 5_000;

/**
 * The one place that ever calls ClickPesa to find out if a payment went
 * through, and the one place that ever activates a plan off that answer.
 * Both `verifyClickPesaPayment` (client poll, used as a fallback — see below)
 * and `clickpesaWebhook` (ClickPesa's own push notification, the primary
 * mechanism) call this after doing their own access checks; it doesn't know
 * or care which one called it.
 *
 * Deliberately never trusts anything from a caller except which
 * `orderReference` to look at — the webhook handler in particular receives
 * an unauthenticated POST that could be replayed or forged, but that's
 * harmless here: whatever a webhook claims, this function always re-derives
 * the real status itself from an authenticated GET using our own server-held
 * token, never from the request body. A forged webhook can make us re-check
 * a payment early; it can't make us activate one that ClickPesa doesn't
 * independently confirm.
 */
async function checkAndFinalizePayment(
  orderReference: string,
  paymentRef: FirebaseFirestore.DocumentReference,
  paymentDoc: FirebaseFirestore.DocumentData,
): Promise<VerifyPaymentResponse> {
  if (paymentDoc.status === "completed") {
    return {status: "completed", tier: paymentDoc.tier, planExpiresAt: paymentDoc.planExpiresAt};
  }
  if (paymentDoc.status === "failed") {
    return {status: "failed"};
  }

  const lastCheckedAtMs = paymentDoc.lastCheckedAtMs as number | undefined;
  if (lastCheckedAtMs && Date.now() - lastCheckedAtMs < MIN_RECHECK_INTERVAL_MS) {
    return {status: "pending"};
  }
  await paymentRef.set({lastCheckedAtMs: Date.now()}, {merge: true});

  const db = admin.firestore();
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
    channel?: string;
  }>;
  const payment = results[0];
  if (!payment) {
    return {status: "pending"};
  }

  const status = String(payment.status ?? "").toUpperCase();
  if (status === "FAILED") {
    await paymentRef.set(
      {status: "failed", channel: payment.channel ?? null},
      {merge: true},
    );
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

  const uid = paymentDoc.uid as string;
  const tier = paymentDoc.tier as PayableTier;
  const cycleMonths = paymentDoc.cycleMonths as number;
  const expiresAt = new Date(Date.now() + 30 * cycleMonths * 24 * 60 * 60 * 1000);
  const expiresAtIso = expiresAt.toISOString();
  const expiresAtTs = admin.firestore.Timestamp.fromDate(expiresAt);

  await db.runTransaction(async (tx) => {
    // All reads must happen before any writes in a Firestore transaction.
    const freshSnap = await tx.get(paymentRef);
    if (freshSnap.data()?.status === "completed") return; // concurrent call already activated it

    // A subscription belongs to the owner, not a single business — mirror
    // the plan onto every business this uid owns, exactly like the admin
    // portal's manual assignPlan does (app/api/admin/plans/assign). Without
    // this, businesses/{bizId}.plan — what admin analytics reads for plan
    // distribution and MRR — never reflects a ClickPesa-driven upgrade.
    const ownedBizSnap = await tx.get(
      db.collection("businesses").where("ownerUid", "==", uid),
    );

    const planFields = {
      plan: tier,
      planExpiresAt: expiresAtTs,
      subscriptionStatus: "active",
      planStartedAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    tx.set(
      paymentRef,
      {
        status: "completed",
        completedAt: admin.firestore.FieldValue.serverTimestamp(),
        planExpiresAt: expiresAtIso,
        channel: payment.channel ?? null,
      },
      {merge: true},
    );
    tx.set(
      db.collection("users").doc(uid),
      {
        ...planFields,
        lastPayment: {
          reference: orderReference,
          amount: paymentDoc.amount,
          currency: paymentDoc.currency ?? "TZS",
          paymentId: paymentDoc.clickPesaId ?? orderReference,
          channel: payment.channel ?? null,
          paidAt: admin.firestore.FieldValue.serverTimestamp(),
          provider: "clickpesa",
        },
      },
      {merge: true},
    );
    for (const bizDoc of ownedBizSnap.docs) {
      tx.set(bizDoc.ref, planFields, {merge: true});
    }
  });

  console.log(`[ClickPesa] Plan activated for user ${uid}: ${tier}`);
  return {status: "completed", tier, planExpiresAt: expiresAtIso};
}

/**
 * Client-side fallback poll — kept for when the ClickPesa webhook hasn't
 * been configured yet, or a delivery gets lost. The app should mostly rely
 * on watching the `clickpesa_payments/{orderReference}` Firestore doc
 * directly (free, instant, zero API calls) and only fall back to calling
 * this sparingly. See CLICKPESA_INTEGRATION.md for the webhook setup that
 * makes this the exception path rather than the primary mechanism.
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

    const paymentRef = admin.firestore().collection("clickpesa_payments").doc(orderReference);
    const paymentSnap = await paymentRef.get();
    if (!paymentSnap.exists) {
      throw new HttpsError("not-found", "Unknown payment.");
    }
    const paymentDoc = paymentSnap.data()!;
    if (paymentDoc.uid !== uid) {
      throw new HttpsError("permission-denied", "This payment does not belong to you.");
    }

    return checkAndFinalizePayment(orderReference, paymentRef, paymentDoc);
  },
);

/**
 * ClickPesa's webhook — configure this URL in the ClickPesa dashboard under
 * Settings → Developers → Application Webhooks, for the "PAYMENT RECEIVED"
 * and "PAYMENT FAILED" events (see CLICKPESA_INTEGRATION.md). This is the
 * primary way payment status reaches us now: instead of the app polling
 * ClickPesa every few seconds for up to two minutes per payment (the
 * previous design — see git history — which burns through the daily API
 * call quota almost immediately at any real volume), ClickPesa pushes a
 * single notification the moment a payment resolves, we re-verify it
 * ourselves in one call, and the app just watches the Firestore doc this
 * writes to — no polling, no extra API calls, near-instant UI update.
 *
 * Unauthenticated by necessity (ClickPesa calls this directly, not through
 * Firebase's callable protocol) — see `checkAndFinalizePayment`'s doc for
 * why that's safe. Always responds 2xx quickly, per ClickPesa's own
 * requirement, regardless of outcome, so a bad/duplicate/unrecognized
 * delivery doesn't trigger their retry logic into hammering us.
 */
export const clickpesaWebhook = onRequest(
  {region: "us-central1", secrets: [CLICKPESA_CLIENT_ID, CLICKPESA_API_KEY]},
  async (req, res) => {
    try {
      const body = req.body as
        | {data?: {orderReference?: string}; orderReference?: string}
        | undefined;
      const orderReference = body?.data?.orderReference ?? body?.orderReference;
      if (!orderReference || typeof orderReference !== "string") {
        res.status(200).send("ignored: no orderReference");
        return;
      }

      const paymentRef = admin.firestore().collection("clickpesa_payments").doc(orderReference);
      const paymentSnap = await paymentRef.get();
      if (!paymentSnap.exists) {
        // Unrecognized reference — could be a replay, a stale test event, or
        // an unrelated ClickPesa application sharing the same webhook URL by
        // mistake. Nothing to do; definitely don't spend a ClickPesa API
        // call looking it up.
        res.status(200).send("ignored: unknown payment");
        return;
      }

      await checkAndFinalizePayment(orderReference, paymentRef, paymentSnap.data()!);
      res.status(200).send("ok");
    } catch (err) {
      console.error("[ClickPesa] webhook handling failed", err);
      // Still 200 — see the function doc. The next webhook retry or the
      // client's fallback poll will pick it up; we don't want ClickPesa's
      // own retry behavior turning a transient error into a call storm.
      res.status(200).send("error logged");
    }
  },
);
