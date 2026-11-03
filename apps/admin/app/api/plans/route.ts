import { NextResponse } from 'next/server'
import { restFirestore } from '@/lib/firestore-rest'
import { withCache } from '@/lib/api-cache'
import { DEFAULT_PUBLIC_PRICES, type PublicPlanPrices, type PublicTier } from '@/lib/public-plans'

// Public (unauthenticated) read of the self-serve plan prices for the
// marketing site's pricing section and /pay checkout. platform_config/plans
// is already world-readable in firestore.rules — this only narrows it to the
// price fields the site shows, and caches it so a landing-page visit never
// costs its own Firestore read.

const TIERS: PublicTier[] = ['starter', 'growth', 'business']

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
    result[tier] = {
      priceMonthly: tier === 'starter' ? 0 : positive(raw.priceMonthly, fallback.priceMonthly) || fallback.priceMonthly,
      priceYearly:  tier === 'starter' ? 0 : positive(raw.priceYearly, fallback.priceYearly) || fallback.priceYearly,
      maxUsers:     typeof raw.maxUsers === 'number' ? raw.maxUsers : fallback.maxUsers,
    }
  }
  return result
}

export async function GET() {
  try {
    const prices = await withCache('public-plan-prices', 5 * 60_000, fetchPrices)
    return NextResponse.json(
      { prices },
      { headers: { 'Cache-Control': 'public, max-age=300, stale-while-revalidate=600' } },
    )
  } catch (err) {
    console.error('[GET /api/plans]', err)
    return NextResponse.json({ prices: DEFAULT_PUBLIC_PRICES })
  }
}
