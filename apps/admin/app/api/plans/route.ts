import { NextResponse } from 'next/server'
import { restFirestore } from '@/lib/firestore-rest'
import { withCache } from '@/lib/api-cache'
import { DEFAULT_PUBLIC_PRICES } from '@/lib/public-plans'
import { loadPublicPrices } from '@/lib/public-plans-server'
import { mergeTrialConfig } from '@/lib/trial-config'

// Public (unauthenticated) read of the self-serve plan prices for the
// marketing site's pricing section and /pay checkout. platform_config/plans
// is already world-readable in firestore.rules — this only narrows it to the
// price fields the site shows, and caches it so a landing-page visit never
// costs its own Firestore read.

// Only the public bits of platform_config/trial — whether new signups get a
// free trial and how long — for the site's "N days free" messaging.
async function fetchTrial(): Promise<{ enabled: boolean; days: number; tier: string }> {
  const snap = await restFirestore.collection('platform_config').doc('trial').get()
  const c = mergeTrialConfig(snap.data())
  return { enabled: c.enabled, days: c.days, tier: c.tier }
}

export async function GET() {
  try {
    const [prices, trial] = await Promise.all([
      loadPublicPrices(),
      withCache('public-trial', 60_000, fetchTrial).catch(() => null),
    ])
    return NextResponse.json(
      { prices, trial },
      { headers: { 'Cache-Control': 'public, max-age=60, stale-while-revalidate=120' } },
    )
  } catch (err) {
    console.error('[GET /api/plans]', err)
    return NextResponse.json({ prices: DEFAULT_PUBLIC_PRICES })
  }
}
