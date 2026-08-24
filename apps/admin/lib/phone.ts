// Phone-number helpers for the admin app.
//
// The mobile app stores `phone` (on both the user doc and `ownerPhone` on the
// business doc) as digits-only, with the country code the user picked at
// onboarding already embedded — e.g. Tanzania -> "255755032343", Kenya ->
// "254712345678". See PhoneNumberUtils.canonical() in the mobile app
// (apps/mobile-app/lib/core/utils/phone_number_utils.dart). Nothing here may
// assume a fixed country code — the admin app must not hardcode +255.

export interface Country {
  flag: string
  name: string
  dial: string // e.g. '+255'
  iso: string
}

// Mirrors the country list in the mobile app's onboarding phone entry
// screen (apps/mobile-app/lib/features/onboarding/presentation/screens/phone_entry_screen.dart)
// so a stored number can be split back into the same country + local digits
// the user originally chose.
export const COUNTRIES: Country[] = [
  { flag: '🇹🇿', name: 'Tanzania', dial: '+255', iso: 'TZ' },
  { flag: '🇰🇪', name: 'Kenya', dial: '+254', iso: 'KE' },
  { flag: '🇺🇬', name: 'Uganda', dial: '+256', iso: 'UG' },
  { flag: '🇷🇼', name: 'Rwanda', dial: '+250', iso: 'RW' },
  { flag: '🇧🇮', name: 'Burundi', dial: '+257', iso: 'BI' },
  { flag: '🇪🇹', name: 'Ethiopia', dial: '+251', iso: 'ET' },
  { flag: '🇸🇸', name: 'South Sudan', dial: '+211', iso: 'SS' },
  { flag: '🇸🇴', name: 'Somalia', dial: '+252', iso: 'SO' },
  { flag: '🇩🇯', name: 'Djibouti', dial: '+253', iso: 'DJ' },
  { flag: '🇪🇷', name: 'Eritrea', dial: '+291', iso: 'ER' },
  { flag: '🇲🇼', name: 'Malawi', dial: '+265', iso: 'MW' },
  { flag: '🇿🇲', name: 'Zambia', dial: '+260', iso: 'ZM' },
  { flag: '🇿🇼', name: 'Zimbabwe', dial: '+263', iso: 'ZW' },
  { flag: '🇲🇿', name: 'Mozambique', dial: '+258', iso: 'MZ' },
  { flag: '🇲🇬', name: 'Madagascar', dial: '+261', iso: 'MG' },
  { flag: '🇧🇼', name: 'Botswana', dial: '+267', iso: 'BW' },
  { flag: '🇳🇦', name: 'Namibia', dial: '+264', iso: 'NA' },
  { flag: '🇿🇦', name: 'South Africa', dial: '+27', iso: 'ZA' },
  { flag: '🇸🇿', name: 'Eswatini', dial: '+268', iso: 'SZ' },
  { flag: '🇱🇸', name: 'Lesotho', dial: '+266', iso: 'LS' },
  { flag: '🇳🇬', name: 'Nigeria', dial: '+234', iso: 'NG' },
  { flag: '🇬🇭', name: 'Ghana', dial: '+233', iso: 'GH' },
  { flag: '🇸🇳', name: 'Senegal', dial: '+221', iso: 'SN' },
  { flag: '🇨🇮', name: "Côte d'Ivoire", dial: '+225', iso: 'CI' },
  { flag: '🇨🇲', name: 'Cameroon', dial: '+237', iso: 'CM' },
  { flag: '🇨🇩', name: 'DR Congo', dial: '+243', iso: 'CD' },
  { flag: '🇨🇬', name: 'Congo', dial: '+242', iso: 'CG' },
  { flag: '🇦🇴', name: 'Angola', dial: '+244', iso: 'AO' },
  { flag: '🇸🇩', name: 'Sudan', dial: '+249', iso: 'SD' },
  { flag: '🇪🇬', name: 'Egypt', dial: '+20', iso: 'EG' },
  { flag: '🇱🇾', name: 'Libya', dial: '+218', iso: 'LY' },
  { flag: '🇹🇳', name: 'Tunisia', dial: '+216', iso: 'TN' },
  { flag: '🇩🇿', name: 'Algeria', dial: '+213', iso: 'DZ' },
  { flag: '🇲🇦', name: 'Morocco', dial: '+212', iso: 'MA' },
  { flag: '🇲🇷', name: 'Mauritania', dial: '+222', iso: 'MR' },
  { flag: '🇲🇱', name: 'Mali', dial: '+223', iso: 'ML' },
  { flag: '🇧🇫', name: 'Burkina Faso', dial: '+226', iso: 'BF' },
  { flag: '🇳🇪', name: 'Niger', dial: '+227', iso: 'NE' },
  { flag: '🇹🇩', name: 'Chad', dial: '+235', iso: 'TD' },
  { flag: '🇬🇦', name: 'Gabon', dial: '+241', iso: 'GA' },
  { flag: '🇲🇺', name: 'Mauritius', dial: '+230', iso: 'MU' },
  { flag: '🇬🇧', name: 'United Kingdom', dial: '+44', iso: 'GB' },
  { flag: '🇺🇸', name: 'United States', dial: '+1', iso: 'US' },
  { flag: '🇨🇦', name: 'Canada', dial: '+1', iso: 'CA' },
  { flag: '🇩🇪', name: 'Germany', dial: '+49', iso: 'DE' },
  { flag: '🇫🇷', name: 'France', dial: '+33', iso: 'FR' },
  { flag: '🇮🇹', name: 'Italy', dial: '+39', iso: 'IT' },
  { flag: '🇪🇸', name: 'Spain', dial: '+34', iso: 'ES' },
  { flag: '🇵🇹', name: 'Portugal', dial: '+351', iso: 'PT' },
  { flag: '🇳🇱', name: 'Netherlands', dial: '+31', iso: 'NL' },
  { flag: '🇨🇭', name: 'Switzerland', dial: '+41', iso: 'CH' },
  { flag: '🇸🇪', name: 'Sweden', dial: '+46', iso: 'SE' },
  { flag: '🇳🇴', name: 'Norway', dial: '+47', iso: 'NO' },
  { flag: '🇩🇰', name: 'Denmark', dial: '+45', iso: 'DK' },
  { flag: '🇵🇱', name: 'Poland', dial: '+48', iso: 'PL' },
  { flag: '🇮🇳', name: 'India', dial: '+91', iso: 'IN' },
  { flag: '🇨🇳', name: 'China', dial: '+86', iso: 'CN' },
  { flag: '🇯🇵', name: 'Japan', dial: '+81', iso: 'JP' },
  { flag: '🇰🇷', name: 'South Korea', dial: '+82', iso: 'KR' },
  { flag: '🇦🇺', name: 'Australia', dial: '+61', iso: 'AU' },
  { flag: '🇳🇿', name: 'New Zealand', dial: '+64', iso: 'NZ' },
  { flag: '🇧🇷', name: 'Brazil', dial: '+55', iso: 'BR' },
  { flag: '🇦🇷', name: 'Argentina', dial: '+54', iso: 'AR' },
  { flag: '🇲🇽', name: 'Mexico', dial: '+52', iso: 'MX' },
  { flag: '🇦🇪', name: 'UAE', dial: '+971', iso: 'AE' },
  { flag: '🇸🇦', name: 'Saudi Arabia', dial: '+966', iso: 'SA' },
  { flag: '🇶🇦', name: 'Qatar', dial: '+974', iso: 'QA' },
  { flag: '🇹🇷', name: 'Turkey', dial: '+90', iso: 'TR' },
]

const DEFAULT_COUNTRY = COUNTRIES[0] // Tanzania — the app's default market

/** Longest dial code first, so e.g. '+254' is matched before a shorter code
 *  that happens to also prefix the digit string. */
const BY_DIAL_LENGTH_DESC = [...COUNTRIES].sort((a, b) => b.dial.length - a.dial.length)

export function digitsOnly(input: string): string {
  return input.replace(/\D/g, '')
}

/**
 * Normalises loose input (e.g. an admin retyping a number, or a legacy
 * TZ-only local number) into the canonical digits-only form the mobile app
 * writes. Mirrors PhoneNumberUtils.canonical() in the mobile app: a bare
 * 9-digit or leading-0 number is treated as Tanzanian (the app's default
 * market); anything that already carries a country code is left alone.
 */
export function canonicalPhone(input: string): string {
  let digits = digitsOnly(input)
  if (digits.startsWith('00')) digits = digits.slice(2)
  if (digits.startsWith('0')) return `255${digits.slice(1)}`
  if (digits.length === 9) return `255${digits}`
  return digits
}

/** Adds the leading '+' for E.164 display — does NOT assume any country,
 *  since the stored digits already carry whichever country code the user
 *  picked at onboarding. */
export function toE164(raw: string | null | undefined): string {
  const digits = digitsOnly(raw ?? '')
  return digits ? `+${digits}` : ''
}

/**
 * Splits a canonical (or already '+'-prefixed) international number back
 * into the country the user chose and the local digits after their dial
 * code — used to prefill the country-aware edit form. Falls back to
 * Tanzania when no known dial code matches, so old/malformed records stay
 * editable instead of erroring out.
 */
export function splitPhone(raw: string | null | undefined): { country: Country; local: string } {
  const digits = digitsOnly(raw ?? '')
  for (const c of BY_DIAL_LENGTH_DESC) {
    const code = c.dial.slice(1)
    if (digits.startsWith(code)) {
      return { country: c, local: digits.slice(code.length) }
    }
  }
  return { country: DEFAULT_COUNTRY, local: digits }
}

/** Builds the canonical digits-only phone (country dial + local digits, no
 *  '+'), matching PhoneNumberUtils.canonical() in the mobile app. */
export function buildPhone(country: Country, local: string): string {
  const localDigits = digitsOnly(local).replace(/^0+/, '')
  return `${digitsOnly(country.dial)}${localDigits}`
}

/** Inserts thin spacing into an E.164 number for readability, without
 *  assuming any particular dial-code length: "+255 755 032 343". */
export function formatPhoneDisplay(raw: string | null | undefined): string {
  const digits = digitsOnly(raw ?? '')
  if (!digits) return ''
  const { country, local } = splitPhone(digits)
  const groups = local.match(/.{1,3}/g) ?? []
  return [country.dial, ...groups].join(' ')
}
