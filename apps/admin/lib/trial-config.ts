// Mirrors platform_config/trial — read by the Cloud Functions in
// apps/mobile-app/functions/src/trial.ts (grant on signup, reminder push,
// end-date SMS) and by the app's welcome popup (trial_service.dart). Keep
// DEFAULT_TRIAL_CONFIG identical to the one in trial.ts so an unconfigured
// doc behaves the same everywhere.

export interface TrialConfig {
  enabled: boolean
  days: number
  tier: 'growth' | 'business'
  reminderDaysBefore: number
  welcomeTitleSw: string
  welcomeBodySw: string
  welcomeTitleEn: string
  welcomeBodyEn: string
  reminderTitleSw: string
  reminderBodySw: string
  reminderTitleEn: string
  reminderBodyEn: string
  expirySms: string
  payUrl: string
}

export const TRIAL_PLACEHOLDERS: { key: string; label: string }[] = [
  { key: '{name}', label: "Owner's first name" },
  { key: '{businessName}', label: 'Business name' },
  { key: '{days}', label: 'Trial length (days)' },
  { key: '{daysLeft}', label: 'Days left' },
  { key: '{endDate}', label: 'End date (dd/mm/yyyy)' },
  { key: '{priceMonthly}', label: 'Monthly price (push & SMS only)' },
  { key: '{priceYearly}', label: 'Yearly price (push & SMS only)' },
  { key: '{payUrl}', label: 'Payment link (push & SMS only)' },
]

export const DEFAULT_TRIAL_CONFIG: TrialConfig = {
  enabled: true,
  days: 7,
  tier: 'growth',
  reminderDaysBefore: 2,
  welcomeTitleSw: 'Zawadi yako ya siku {days}! 🎁',
  welcomeBodySw:
    'Hongera {name}! Tumekupa kifurushi cha Growth BURE kwa siku {days}. ' +
    'Tumia ripoti kamili, mtiririko wa fedha, madeni na mauzo bila kikomo. ' +
    'Kifurushi kitaisha tarehe {endDate} (siku {daysLeft} zimebaki).',
  welcomeTitleEn: 'Your {days}-day gift! 🎁',
  welcomeBodyEn:
    "Congratulations {name}! We've gifted you the Growth package FREE for {days} days. " +
    'Enjoy full reports, cash flow, debt tracking and unlimited sales. ' +
    'It ends on {endDate} ({daysLeft} days left).',
  reminderTitleSw: 'Siku {daysLeft} zimebaki ⏳',
  reminderBodySw:
    'Kifurushi chako cha Growth cha bure kinaisha tarehe {endDate}. ' +
    'Lipia sasa ({priceMonthly}/mwezi) uendelee kutumia vipengele vyote.',
  reminderTitleEn: '{daysLeft} days left ⏳',
  reminderBodyEn:
    'Your free Growth package ends on {endDate}. ' +
    'Pay now ({priceMonthly}/month) to keep every feature.',
  expirySms:
    'Habari {name}, kifurushi chako cha Growth cha siku {days} kimeisha leo {endDate}. ' +
    'Kuendelea: fungua Mali Up > Mipangilio > Mpango > chagua Growth > weka namba ya ' +
    'M-Pesa/Mixx/Airtel/Halopesa > thibitisha kwa PIN. Bei {priceMonthly}/mwezi au ' +
    '{priceYearly}/mwaka. Au lipia hapa: {payUrl} Msaada: +255653520829',
  payUrl: 'https://maliup.neuraltale.com/pay',
}

/** Merges a stored doc over the defaults, keeping only well-typed fields. */
export function mergeTrialConfig(raw: Record<string, unknown> | undefined): TrialConfig {
  const c: TrialConfig = { ...DEFAULT_TRIAL_CONFIG }
  const out = c as unknown as Record<string, unknown>
  for (const key of Object.keys(DEFAULT_TRIAL_CONFIG) as (keyof TrialConfig)[]) {
    const v = raw?.[key]
    const def = DEFAULT_TRIAL_CONFIG[key]
    if (typeof def === 'string' && typeof v === 'string' && v.trim()) out[key] = v
    else if (typeof def === 'number' && typeof v === 'number' && Number.isFinite(v)) out[key] = v
    else if (typeof def === 'boolean' && typeof v === 'boolean') out[key] = v
  }
  c.days = Math.min(Math.max(Math.round(c.days), 1), 90)
  c.reminderDaysBefore = Math.min(Math.max(Math.round(c.reminderDaysBefore), 1), c.days)
  if (c.tier !== 'growth' && c.tier !== 'business') c.tier = 'growth'
  return c
}

/** Same placeholder syntax as the app and Cloud Functions. */
export function fillTrialTemplate(template: string, vars: Record<string, string | number>): string {
  return template.replace(/\{\{?\s*(\w+)\s*\}\}?/g, (m, key: string) =>
    key in vars ? String(vars[key]) : m,
  )
}

export function formatTrialDate(d: Date): string {
  // East Africa Time (UTC+3), like the server.
  const eat = new Date(d.getTime() + 3 * 3600_000)
  const dd = String(eat.getUTCDate()).padStart(2, '0')
  const mm = String(eat.getUTCMonth() + 1).padStart(2, '0')
  return `${dd}/${mm}/${eat.getUTCFullYear()}`
}

/** A business plan value that means "on the free plan". */
export function isFreePlanValue(plan: unknown): boolean {
  const p = String(plan ?? '').trim().toLowerCase()
  return p === '' || p === 'trial' || p === 'starter' || p === 'free'
}
