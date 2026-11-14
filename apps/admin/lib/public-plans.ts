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
  // Limits, all -1 = unlimited. Live from platform_config/plans so the
  // feature lines below always match what the admin Plans page set.
  maxUsers: number
  maxBusinesses: number
  maxCustomers: number
  maxProducts: number
  maxSalesPerDay: number
  maxAccounts: number
}

export type PublicPlanPrices = Record<PublicTier, PublicPlanPrice>

export const DEFAULT_PUBLIC_PRICES: PublicPlanPrices = {
  starter:  { priceMonthly: 0,     priceYearly: 0,      maxUsers: 1,  maxBusinesses: 1, maxCustomers: 20, maxProducts: 30, maxSalesPerDay: 10, maxAccounts: 1 },
  growth:   { priceMonthly: 6000,  priceYearly: 60000,  maxUsers: 3,  maxBusinesses: 1, maxCustomers: -1, maxProducts: -1, maxSalesPerDay: -1, maxAccounts: 3 },
  business: { priceMonthly: 15000, priceYearly: 150000, maxUsers: 10, maxBusinesses: 5, maxCustomers: -1, maxProducts: -1, maxSalesPerDay: -1, maxAccounts: -1 },
}

export interface PublicPlanCopy {
  name: string
  tagline: string
}

export const PLAN_COPY: Record<PublicTier, PublicPlanCopy> = {
  starter:  { name: 'Bure (Starter)', tagline: 'Kwa anayeanza biashara. Bure milele.' },
  growth:   { name: 'Growth',         tagline: 'Kwa biashara inayokua kila siku.' },
  business: { name: 'Business',       tagline: 'Kwa biashara yenye matawi na wafanyakazi.' },
}

const unlimited = (n: number) => n === -1

/** Swahili feature lines for a plan card, built from its live limits. */
export function planFeatures(tier: PublicTier, p: PublicPlanPrice): string[] {
  const users = unlimited(p.maxUsers) ? 'Watumiaji bila kikomo' : `Hadi watumiaji ${p.maxUsers}`
  const businesses = unlimited(p.maxBusinesses)
    ? 'Biashara bila kikomo'
    : p.maxBusinesses === 1 ? 'biashara 1' : `hadi biashara ${p.maxBusinesses}`
  const accounts = unlimited(p.maxAccounts)
    ? 'Akaunti za fedha bila kikomo'
    : `Akaunti ${p.maxAccounts} za fedha (M-Pesa, benki, taslimu)`

  if (tier === 'starter') {
    const stock = unlimited(p.maxProducts) && unlimited(p.maxCustomers)
      ? 'Bidhaa na wateja bila kikomo'
      : `Hadi bidhaa ${unlimited(p.maxProducts) ? 'bila kikomo' : p.maxProducts} na wateja ${unlimited(p.maxCustomers) ? 'bila kikomo' : p.maxCustomers}`
    return [
      'Mauzo na risiti za kidigitali',
      stock,
      unlimited(p.maxSalesPerDay) ? 'Mauzo bila kikomo' : `Mauzo ${p.maxSalesPerDay} kwa siku`,
      'Inafanya kazi bila intaneti',
      `${users}, ${businesses}`,
    ]
  }
  if (tier === 'growth') {
    return [
      'Kila kitu kwenye Bure',
      'Bidhaa, wateja na mauzo bila kikomo',
      'Mapato, matumizi na madeni',
      'Ripoti kamili za faida na hasara',
      'Kuingiza miamala ya M-Pesa',
      'SMS za kukumbusha madeni',
      accounts,
      `${users}, ${businesses}`,
    ]
  }
  return [
    'Kila kitu kwenye Growth',
    unlimited(p.maxBusinesses) ? 'Biashara bila kikomo kwenye akaunti moja' : `Hadi biashara ${p.maxBusinesses} kwenye akaunti moja`,
    'Matawi mengi (multi-location)',
    accounts,
    'Kupakua ripoti zote (exports)',
    `${users} wenye majukumu`,
    'Msaada wa kipaumbele',
  ]
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
