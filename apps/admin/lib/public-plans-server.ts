import { restFirestore } from '@/lib/firestore-rest'
import { withCache } from '@/lib/api-cache'
import { DEFAULT_PUBLIC_PRICES, type PublicPlanPrice, type PublicPlanPrices, type PublicTier } from '@/lib/public-plans'

// Server-only: live public plan prices + limits from platform_config/plans
// (the doc the admin Plans page edits and ClickPesa charges from). Shared by
// /api/plans and the homepage's structured data so both always match.

const TIERS: PublicTier[] = ['starter', 'growth', 'business']
const LIMIT_FIELDS = ['maxUsers', 'maxBusinesses', 'maxCustomers', 'maxProducts', 'maxSalesPerDay', 'maxAccounts'] as const

function positive(value: unknown, fallback: number): number {
  return typeof value === 'number' && value >= 0 ? value : fallback
}

async function fetchPrices(): Promise<PublicPlanPrices> {
  const snap = await restFirestore.collection('platform_config').doc('plans').get()
  const data = (snap.data() ?? {}) as Record<string, Record<string, unknown> | undefined>
  const result = { ...DEFAULT_PUBLIC_PRICES }
  for (const tier of TIERS) {
    const raw = data[tier]
    if (!raw) continue
    const fallback = DEFAULT_PUBLIC_PRICES[tier]
    const next: PublicPlanPrice = {
      ...fallback,
      priceMonthly: tier === 'starter' ? 0 : positive(raw.priceMonthly, fallback.priceMonthly) || fallback.priceMonthly,
      priceYearly:  tier === 'starter' ? 0 : positive(raw.priceYearly, fallback.priceYearly) || fallback.priceYearly,
    }
    for (const f of LIMIT_FIELDS) {
      if (typeof raw[f] === 'number') next[f] = raw[f] as number
    }
    result[tier] = next
  }
  return result
}

/** Cached 60s; falls back to the defaults if Firestore can't be read. */
export async function loadPublicPrices(): Promise<PublicPlanPrices> {
  try {
    return await withCache('public-plan-prices', 60_000, fetchPrices)
  } catch (err) {
    console.error('[public-plans] could not read platform_config/plans', err)
    return DEFAULT_PUBLIC_PRICES
  }
}
