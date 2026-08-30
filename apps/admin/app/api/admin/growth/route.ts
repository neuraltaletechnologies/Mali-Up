import { NextResponse } from 'next/server'
import { restFirestore as adminFirestore } from '@/lib/firestore-rest'
import { requireAdminSession } from '@/lib/api-guard'
import { withCache } from '@/lib/api-cache'
import { toMs, weeklyCounts, deltaPct } from '@/lib/analytics-shared'
import { getPlayInstallStats, windowTotals } from '@/lib/play-reports'
import type { GrowthOverview, GrowthFunnelStep } from '@/types'

const DAY_MS = 24 * 60 * 60 * 1000
const WEEKS = 12

function normalisePlan(raw: unknown): string {
  const p = String(raw ?? '').toLowerCase()
  if (['growth', 'business', 'enterprise', 'lifetime'].includes(p)) return p
  return 'starter'
}

export async function GET() {
  const denied = await requireAdminSession()
  if (denied) return denied

  try {
    // Play data only changes once a day; a 30-min cache keeps the CSV fetch
    // off the hot path without going stale.
    const body = await withCache('growth', 30 * 60_000, computeGrowth)
    return NextResponse.json(body)
  } catch (err) {
    console.error('[GET /api/admin/growth]', err)
    return NextResponse.json({ error: 'Failed to fetch growth analytics' }, { status: 500 })
  }
}

async function computeGrowth(): Promise<GrowthOverview> {
  const now = Date.now()
  const cutoff90 = now - 90 * DAY_MS

  const [userCountSnap, recentUsersSnap, bizSnap, play] = await Promise.all([
    adminFirestore.collection('users').count().get(),
    adminFirestore
      .collection('users')
      .where('createdAt', '>=', new Date(cutoff90))
      .orderBy('createdAt', 'asc')
      .get(),
    adminFirestore.collectionGroup('businesses').get(),
    getPlayInstallStats(),
  ])

  const totalUsers = userCountSnap.data().count

  // ── Signup trend (weekly, last 12 weeks) ────────────────────────────────
  const signupMs = recentUsersSnap.docs
    .map((d) => toMs(d.data().createdAt))
    .filter((ms) => ms > 0)
  const signupTrend = weeklyCounts(signupMs, WEEKS)

  // ── Businesses ─────────────────────────────────────────────────────────
  type BizRow = { plan: string; createdAtMs: number; updatedAtMs: number }
  const bizRows: BizRow[] = bizSnap.docs.map((doc) => {
    const d = doc.data()
    return {
      plan: normalisePlan(d.plan),
      createdAtMs: toMs(d.createdAt),
      updatedAtMs: toMs(d.updatedAt) || toMs(d.createdAt),
    }
  })

  const totalBusinesses = bizRows.length
  const businessTrend = weeklyCounts(
    bizRows.map((b) => b.createdAtMs).filter((ms) => ms > 0),
    WEEKS,
  )

  // ── Usage buckets (proxy for "is the installer actually using it") ──────
  const active7Cut = now - 7 * DAY_MS
  const active30Cut = now - 30 * DAY_MS
  let active7d = 0
  let dormant30d = 0
  let inactive = 0
  for (const b of bizRows) {
    if (b.updatedAtMs >= active7Cut) active7d += 1
    else if (b.updatedAtMs >= active30Cut) dormant30d += 1
    else inactive += 1
  }
  const activeBusinesses = active7d + dormant30d

  // ── Free vs paid ──────────────────────────────────────────────────────
  const payingBusinesses = bizRows.filter((b) => b.plan !== 'starter').length
  const freeBusinesses = totalBusinesses - payingBusinesses
  const activeButFree = bizRows.filter(
    (b) => b.plan === 'starter' && b.updatedAtMs >= active30Cut,
  ).length

  const conversionRatePct = totalBusinesses > 0
    ? Math.round((payingBusinesses / totalBusinesses) * 1000) / 10
    : 0

  // Approximate prior conversion using only the cohort that already existed
  // 30 days ago (we keep no historical plan snapshots, so a business's
  // *current* plan is the best proxy for its plan back then).
  const cohort30 = bizRows.filter((b) => b.createdAtMs > 0 && b.createdAtMs <= active30Cut)
  const priorRate = cohort30.length > 0
    ? (cohort30.filter((b) => b.plan !== 'starter').length / cohort30.length) * 100
    : 0
  const conversionDeltaPct = cohort30.length > 0
    ? deltaPct(conversionRatePct, priorRate)
    : null

  // ── Play install/uninstall windows ────────────────────────────────────
  let playOut: GrowthOverview['play']
  if (play.available) {
    const w = windowTotals(play.dailySeries, 30)
    playOut = {
      available: true,
      dailySeries: play.dailySeries,
      activeDeviceInstalls: play.activeDeviceInstalls,
      totalUserInstalls: play.totalUserInstalls,
      lastReportDate: play.lastReportDate,
      installs30d: w.installs,
      uninstalls30d: w.uninstalls,
      installsDeltaPct: deltaPct(w.installs, w.prevInstalls),
      uninstallsDeltaPct: deltaPct(w.uninstalls, w.prevUninstalls),
    }
  } else {
    playOut = { available: false, reason: play.reason }
  }

  // ── Conversion funnel ─────────────────────────────────────────────────
  const funnel: GrowthFunnelStep[] = []
  const push = (label: string, count: number) => {
    const prev = funnel[funnel.length - 1]
    funnel.push({
      label,
      count,
      pctOfPrev: prev && prev.count > 0 ? Math.round((count / prev.count) * 100) : null,
    })
  }
  if (playOut.available && playOut.totalUserInstalls > 0) {
    push('Play Store installs', playOut.totalUserInstalls)
  }
  push('Signed up', totalUsers)
  push('Created a business', totalBusinesses)
  push('Active (≤30d)', activeBusinesses)
  push('Paying', payingBusinesses)

  return {
    play: playOut,
    totalUsers,
    totalBusinesses,
    signupTrend,
    businessTrend,
    usage: { active7d, dormant30d, inactive },
    activeButFree,
    payingBusinesses,
    freeBusinesses,
    conversionRatePct,
    conversionDeltaPct,
    funnel,
  }
}
