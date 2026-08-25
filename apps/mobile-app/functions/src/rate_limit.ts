import {HttpsError} from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import * as crypto from "crypto";

/**
 * Generic Firestore-transaction-backed fixed-window rate limiter, shared by
 * every callable in this project except requestOtpAllowance (otp_rate_limit.ts
 * has its own two-window phone+IP logic, left as-is since it already shipped
 * and works). A Firestore transaction makes each check atomic — two
 * concurrent calls for the same key can never both slip through under the
 * same count, unlike the get-then-put KV limiter used on the admin side
 * (apps/admin/lib/rate-limit.ts), which is fine for throttling an internal
 * dashboard but not for anything with a real per-call cost.
 *
 * Each caller picks its own `collection` so its counters live in their own
 * Firestore collection — firestore.rules denies all client read/write to
 * every collection here via the default-deny fallback, same as
 * otp_rate_limits, so a client can never reset or inspect its own count.
 */

interface WindowCounter {
  windowStart: number;
  count: number;
}

function hashKey(value: string): string {
  return crypto.createHash("sha256").update(value).digest("hex");
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
 * Throws HttpsError("resource-exhausted", ...) once `key` has made `max`
 * calls within `windowMs`; otherwise records this call and returns
 * normally. Call this BEFORE doing the expensive/costly work — a denied
 * attempt must not itself consume another slot once the caller retries.
 */
export async function enforceRateLimit(opts: {
  collection: string;
  key: string;
  windowMs: number;
  max: number;
  message?: string;
}): Promise<void> {
  const db = admin.firestore();
  const ref = db.collection(opts.collection).doc(hashKey(opts.key));
  const now = Date.now();

  await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const data = snap.data() as WindowCounter | undefined;

    if (data && data.count >= opts.max && now - data.windowStart < opts.windowMs) {
      throw new HttpsError(
        "resource-exhausted",
        opts.message ?? "Too many requests. Please wait before trying again.",
      );
    }

    const window = bumpWindow(data, now, opts.windowMs);
    tx.set(ref, {...window, updatedAt: now}, {merge: true});
  });
}
