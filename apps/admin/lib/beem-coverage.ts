/**
 * Which phone numbers Beem Africa SMS can actually reach. Mirrors
 * apps/mobile-app/functions/src/beem_coverage.ts — keep the two lists (and
 * the BEEM_COUNTRY_CODES env var in both places) in sync.
 *
 * Beem publishes no per-country list (only "20–25+ African countries"), so
 * this default is a best-effort list of its known markets. Override it with
 * BEEM_COUNTRY_CODES (comma-separated dial codes, e.g. "255,254,256").
 * ITU country calling codes are prefix-free, so startsWith is unambiguous.
 *
 * Numbers outside the list are never sent to Beem: it would accept them and
 * the text would never arrive, while still costing credit.
 */
const DEFAULT_BEEM_COUNTRY_CODES = [
  '255', // Tanzania (home market)
  '254', // Kenya
  '256', // Uganda
  '250', // Rwanda
  '257', // Burundi
  '243', // DR Congo
  '211', // South Sudan
  '251', // Ethiopia
  '260', // Zambia
  '265', // Malawi
  '258', // Mozambique
  '263', // Zimbabwe
  '27', // South Africa
  '234', // Nigeria
  '233', // Ghana
]

export const BEEM_NOT_COVERED_REASON = 'Country not covered by Beem'

function configuredCountryCodes(): string[] {
  const raw = process.env.BEEM_COUNTRY_CODES?.trim()
  if (!raw) return DEFAULT_BEEM_COUNTRY_CODES
  const codes = raw.split(',').map((c) => c.replace(/\D/g, '')).filter((c) => c.length > 0)
  return codes.length > 0 ? codes : DEFAULT_BEEM_COUNTRY_CODES
}

/** `phone` is normalized digits-only, country code first (e.g. 255712345678). */
export function isBeemReachable(phone: string): boolean {
  return configuredCountryCodes().some((code) => phone.startsWith(code))
}
