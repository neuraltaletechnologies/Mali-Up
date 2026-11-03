// Public, client-safe view of the three self-serve plans shown on the
// marketing site's pricing section and the /pay checkout. Prices come live
// from platform_config/plans via /api/plans (the same doc ClickPesa charges
// from — see functions/src/clickpesa.ts), so these defaults only show while
// that request is in flight or if it fails. Keep them in step with
// DEFAULT_PLANS in app/api/admin/plans/route.ts.

export type PublicTier = 'starter' | 'growth' | 'business'
export type PaidTier = Exclude<PublicTier, 'starter'>
export type BillingCycle = 'monthly' | 'yearly'

export interface PublicPlanPrice {
  priceMonthly: number
  priceYearly: number
  maxUsers: number // -1 = unlimited
}

export type PublicPlanPrices = Record<PublicTier, PublicPlanPrice>

export const DEFAULT_PUBLIC_PRICES: PublicPlanPrices = {
  starter:  { priceMonthly: 0,    priceYearly: 0,     maxUsers: 1 },
  growth:   { priceMonthly: 6000, priceYearly: 60000, maxUsers: 3 },
  business: { priceMonthly: 8000, priceYearly: 80000, maxUsers: 10 },
}

export interface PublicPlanCopy {
  name: string
  tagline: string
  features: string[]
}

export const PLAN_COPY: Record<PublicTier, PublicPlanCopy> = {
  starter: {
    name: 'Bure (Starter)',
    tagline: 'Kwa anayeanza biashara. Bure milele.',
    features: [
      'Mauzo na risiti za kidigitali',
      'Hadi bidhaa 15 na wateja 20',
      'Mauzo 10 kwa siku',
      'Inafanya kazi bila intaneti',
      'Mtumiaji 1, biashara 1',
    ],
  },
  growth: {
    name: 'Growth',
    tagline: 'Kwa biashara inayokua kila siku.',
    features: [
      'Kila kitu kwenye Bure',
      'Bidhaa, wateja na mauzo bila kikomo',
      'Mapato, matumizi na madeni',
      'Ripoti kamili za faida na hasara',
      'Kuingiza miamala ya M-Pesa',
      'SMS za kukumbusha madeni',
      'Hadi watumiaji 3',
    ],
  },
  business: {
    name: 'Business',
    tagline: 'Kwa biashara yenye matawi na wafanyakazi.',
    features: [
      'Kila kitu kwenye Growth',
      'Matawi mengi (multi-location)',
      'Kupakua ripoti zote (exports)',
      'Hadi watumiaji 10 wenye majukumu',
      'Msaada wa kipaumbele',
    ],
  },
}

export function formatTZS(amount: number): string {
  return `TSh ${amount.toLocaleString('en-US')}`
}

export function priceFor(prices: PublicPlanPrices, tier: PublicTier, cycle: BillingCycle): number {
  return cycle === 'yearly' ? prices[tier].priceYearly : prices[tier].priceMonthly
}

/** Amount saved by paying yearly instead of 12 monthly payments (0 if none). */
export function yearlySaving(prices: PublicPlanPrices, tier: PublicTier): number {
  const { priceMonthly, priceYearly } = prices[tier]
  return Math.max(0, priceMonthly * 12 - priceYearly)
}
