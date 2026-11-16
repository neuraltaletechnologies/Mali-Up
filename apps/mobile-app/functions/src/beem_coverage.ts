/**
 * Which phone numbers Beem Africa's OTP/SMS can actually reach.
 *
 * Beem only delivers to (some) African networks. A number outside that
 * footprint (e.g. a Saudi +966 user) gets a pinId back from Beem but never
 * receives the SMS, so the OTP step locks them out of the app forever. For
 * those numbers onboarding skips the SMS entirely (sendBeemOtp in
 * beem_otp.ts), and every other SMS path (welcome, invites, campaigns, the
 * admin console's apps/admin/lib/beem-coverage.ts) records them as
 * "not covered" instead of spending Beem credit on a text that won't arrive.
 *
 * Beem publishes no per-country list (only "20–25+ African countries"), so
 * this default is a best-effort list of its known markets. Override it
 * without a code change via BEEM_COUNTRY_CODES in functions/.env
 * (comma-separated dial codes, e.g. "255,254,256"). ITU country calling
 * codes are prefix-free, so a plain startsWith match is unambiguous.
 */
const DEFAULT_BEEM_COUNTRY_CODES = [
  "255", // Tanzania (home market)
  "254", // Kenya
  "256", // Uganda
  "250", // Rwanda
  "257", // Burundi
  "243", // DR Congo
  "211", // South Sudan
  "251", // Ethiopia
  "260", // Zambia
  "265", // Malawi
  "258", // Mozambique
  "263", // Zimbabwe
  "27", // South Africa
  "234", // Nigeria
  "233", // Ghana
];

function configuredCountryCodes(): string[] {
  const raw = process.env.BEEM_COUNTRY_CODES?.trim();
  if (!raw) return DEFAULT_BEEM_COUNTRY_CODES;
  const codes = raw.split(",").map((c) => c.replace(/\D/g, "")).filter((c) => c.length > 0);
  return codes.length > 0 ? codes : DEFAULT_BEEM_COUNTRY_CODES;
}

/** Failure reason recorded for numbers outside Beem's coverage. */
export const BEEM_NOT_COVERED_REASON = "Country not covered by Beem";

/** `phone` is canonical digits-only, country code first (e.g. 255712345678). */
export function isBeemReachable(phone: string): boolean {
  return configuredCountryCodes().some((code) => phone.startsWith(code));
}
