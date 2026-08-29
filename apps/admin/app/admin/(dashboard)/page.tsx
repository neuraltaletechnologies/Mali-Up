'use client'

import { PageHeader } from '@/components/ui/page-header'
import { KPICard } from '@/components/ui/kpi-card'
import { StatusDot } from '@/components/ui/status-dot'
import { MRRTrendChart } from '@/components/charts/mrr-trend-chart'
import { TierDonut } from '@/components/charts/tier-donut'
import { AcquisitionChart } from '@/components/charts/acquisition-chart'
import { ConversionFunnel } from '@/components/charts/conversion-funnel'
import { KPIRowSkeleton, ChartSkeleton, Skeleton, RevalidatingBar } from '@/components/ui/skeleton'
import { fetchAnalytics, fetchSystemHealth, fetchGrowth } from '@/lib/admin-api'
import { useAdminFetch } from '@/hooks/use-admin-fetch'
import { formatTZSCompact, timeAgo } from '@/lib/format'
import {
  Building2, Users, DollarSign, AlertCircle, RefreshCw,
  TrendingUp, TrendingDown, Minus, Download, Trash2,
} from 'lucide-react'
import Link from 'next/link'
import { useCallback } from 'react'

export default function DashboardPage() {
  const {
    data,
    loading: analyticsLoading,
    revalidating: analyticsRefreshing,
    error,
    refetch: refetchAnalytics,
  } = useAdminFetch(useCallback(() => fetchAnalytics(), []), {
    key: 'analytics',
    pollingInterval: 120_000,
    minStaleMs: 120_000,
  })

  const {
    data: healthData,
    loading: healthLoading,
    revalidating: healthRefreshing,
  } = useAdminFetch(useCallback(() => fetchSystemHealth(), []), {
    key: 'system-health',
    pollingInterval: 60_000,
    minStaleMs: 60_000,
  })

  const {
    data: growth,
    loading: growthLoading,
    revalidating: growthRefreshing,
  } = useAdminFetch(useCallback(() => fetchGrowth(), []), {
    key: 'growth',
    pollingInterval: 1_800_000, // Play reports only refresh daily
    minStaleMs: 600_000,
  })

  const total = data?.planDistribution.reduce((s, d) => s + d.value, 0) ?? 0

  return (
    <div>
      <PageHeader
        title="Platform Dashboard"
        description={analyticsLoading ? 'Loading…' : 'Real-time health of the Mali Up platform'}
      >
        <button
          onClick={refetchAnalytics}
          disabled={analyticsLoading || analyticsRefreshing}
          className="inline-flex items-center gap-1.5 rounded-md border border-[var(--line)] bg-[var(--surface)] px-3 py-1.5 text-[12px] text-[var(--ink-muted)] hover:text-[var(--ink)] disabled:opacity-40 transition-colors"
        >
          <RefreshCw className={`h-3.5 w-3.5 ${analyticsRefreshing ? 'animate-spin' : ''}`} />
          Refresh
        </button>
      </PageHeader>

      {/* KPI Row */}
      {analyticsLoading
        ? <KPIRowSkeleton count={4} />
        : (
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
            <KPICard label="Total Businesses" value={(data?.totalBusinesses ?? 0).toLocaleString()} icon={<Building2 className="h-4 w-4" />} mono={false} />
            <KPICard label="Total Users" value={(data?.totalUsers ?? 0).toLocaleString()} icon={<Users className="h-4 w-4" />} mono={false} />
            <KPICard label="Active Businesses" value={(data?.activeBusinesses ?? 0).toLocaleString()} icon={<Building2 className="h-4 w-4" />} mono={false} />
            <KPICard label="Monthly Recurring Revenue" value={`TZS ${formatTZSCompact(data?.mrr ?? 0)}`} icon={<DollarSign className="h-4 w-4" />} />
          </div>
        )
      }

      {/* Error — only on first-load failure */}
      {error && !data && (
        <div className="mb-6 flex items-center gap-3 rounded-lg border border-[var(--status-bad)] bg-[var(--status-bad-bg)] p-4 text-[var(--status-bad)]">
          <AlertCircle className="h-4 w-4 shrink-0" />
          <span className="text-[13px]">{error}</span>
        </div>
      )}

      {/* Charts */}
      {analyticsRefreshing && <RevalidatingBar />}
      {analyticsLoading
        ? (
          <div className="grid grid-cols-1 lg:grid-cols-5 gap-4 mb-6">
            <div className="lg:col-span-3"><ChartSkeleton height="h-64" /></div>
            <div className="lg:col-span-2"><ChartSkeleton height="h-64" /></div>
          </div>
        )
        : data && (
          <div className="grid grid-cols-1 lg:grid-cols-5 gap-4 mb-6">
            <div className="lg:col-span-3 rounded-lg border border-[var(--line)] bg-[var(--surface)] p-5">
              <div className="mb-4">
                <h2 className="text-[14px] font-semibold text-[var(--ink)]">MRR Trend</h2>
                <p className="text-[12px] text-[var(--ink-muted)]">Cumulative over last 12 months</p>
              </div>
              <MRRTrendChart data={data.mrrTrend} />
            </div>
            <div className="lg:col-span-2 rounded-lg border border-[var(--line)] bg-[var(--surface)] p-5">
              <div className="mb-4">
                <h2 className="text-[14px] font-semibold text-[var(--ink)]">Plan Distribution</h2>
                <p className="text-[12px] text-[var(--ink-muted)]">{total.toLocaleString()} businesses by tier</p>
              </div>
              {data.planDistribution.length > 0
                ? <TierDonut data={data.planDistribution} total={total} />
                : <p className="text-[13px] text-[var(--ink-faint)] pt-8 text-center">No data yet</p>
              }
            </div>
          </div>
        )
      }

      {/* ── Growth & Retention ── */}
      <div className="mt-8 mb-3 flex items-center gap-3">
        <span className="text-[11px] uppercase tracking-widest font-semibold text-[var(--ink-faint)]">
          Growth &amp; Retention
        </span>
        <div className="flex-1 h-px bg-[var(--line)]" />
        {growth?.play.available && (
          <span className="text-[11px] text-[var(--ink-faint)]">
            Play data to {growth.play.lastReportDate}
          </span>
        )}
      </div>

      {growthRefreshing && <RevalidatingBar />}

      {growthLoading ? (
        <>
          <KPIRowSkeleton count={4} />
          <div className="grid grid-cols-1 lg:grid-cols-5 gap-4 mb-6">
            <div className="lg:col-span-3"><ChartSkeleton height="h-56" /></div>
            <div className="lg:col-span-2"><ChartSkeleton height="h-56" /></div>
          </div>
        </>
      ) : growth && (
        <>
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
            {growth.play.available ? (
              <>
                <GrowthStat
                  label="Installs (30d)"
                  value={growth.play.installs30d.toLocaleString()}
                  deltaPct={growth.play.installsDeltaPct}
                  icon={<Download className="h-4 w-4" />}
                />
                <GrowthStat
                  label="Uninstalls (30d)"
                  value={growth.play.uninstalls30d.toLocaleString()}
                  deltaPct={growth.play.uninstallsDeltaPct}
                  invert
                  icon={<Trash2 className="h-4 w-4" />}
                />
              </>
            ) : (
              <>
                <GrowthStat label="Active device installs" value="—" deltaPct={null} icon={<Download className="h-4 w-4" />} />
                <GrowthStat label="Uninstalls (30d)" value="—" deltaPct={null} invert icon={<Trash2 className="h-4 w-4" />} />
              </>
            )}
            <GrowthStat
              label="Active businesses (≤30d)"
              value={(growth.usage.active7d + growth.usage.dormant30d).toLocaleString()}
              deltaPct={null}
              sublabel={`of ${growth.totalBusinesses.toLocaleString()} total`}
              icon={<Users className="h-4 w-4" />}
            />
            <GrowthStat
              label="Free → Paid conversion"
              value={`${growth.conversionRatePct}%`}
              deltaPct={growth.conversionDeltaPct}
              sublabel={`${growth.payingBusinesses.toLocaleString()} paying`}
              icon={<TrendingUp className="h-4 w-4" />}
            />
          </div>

          <div className="grid grid-cols-1 lg:grid-cols-5 gap-4 mb-6">
            {/* Acquisition — installs vs uninstalls */}
            <div className="lg:col-span-3 rounded-lg border border-[var(--line)] bg-[var(--surface)] p-5">
              <div className="mb-4">
                <h2 className="text-[14px] font-semibold text-[var(--ink)]">Installs vs Uninstalls</h2>
                <p className="text-[12px] text-[var(--ink-muted)]">Google Play, last 90 days</p>
              </div>
              {growth.play.available && growth.play.dailySeries.length > 0 ? (
                <AcquisitionChart data={growth.play.dailySeries} />
              ) : (
                <div className="rounded-md border border-dashed border-[var(--line)] p-5 text-[12px] text-[var(--ink-muted)]">
                  <p className="font-medium text-[var(--ink)] mb-2">Connect Google Play Console</p>
                  <p className="mb-2">
                    Install / uninstall numbers come from Play Console&apos;s exported CSV reports. To turn this on:
                  </p>
                  <ol className="list-decimal ml-4 space-y-1">
                    <li>Play Console → Download reports → Statistics → copy the Cloud Storage URI.</li>
                    <li>Set <code className="text-[var(--accent)]">PLAY_REPORTS_BUCKET</code> (the <code>pubsite_prod_…</code> id) and <code className="text-[var(--accent)]">PLAY_PACKAGE_NAME</code>.</li>
                    <li>Grant the service account read access to that bucket.</li>
                  </ol>
                  {growth.play.available === false && (
                    <p className="mt-2 text-[var(--ink-faint)]">Current status: {growth.play.reason}</p>
                  )}
                </div>
              )}
            </div>

            {/* Usage breakdown */}
            <div className="lg:col-span-2 rounded-lg border border-[var(--line)] bg-[var(--surface)] p-5">
              <div className="mb-4">
                <h2 className="text-[14px] font-semibold text-[var(--ink)]">Are installers using it?</h2>
                <p className="text-[12px] text-[var(--ink-muted)]">Businesses by last activity</p>
              </div>
              <UsageBreakdown usage={growth.usage} />
              {growth.activeButFree > 0 && (
                <div className="mt-4 rounded-md border border-[var(--status-warn)] bg-[var(--status-warn-bg)] px-3 py-2.5 text-[12px] text-[var(--status-warn)]">
                  {growth.activeButFree.toLocaleString()} active {growth.activeButFree === 1 ? 'business is' : 'businesses are'} still on the free plan — the pool most likely to convert.
                </div>
              )}
            </div>
          </div>

          {/* Conversion funnel */}
          <div className="rounded-lg border border-[var(--line)] bg-[var(--surface)] p-5 mb-6">
            <div className="mb-4">
              <h2 className="text-[14px] font-semibold text-[var(--ink)]">Conversion Funnel</h2>
              <p className="text-[12px] text-[var(--ink-muted)]">
                {growth.play.available
                  ? 'From Play install through to a paying business'
                  : 'From signup through to a paying business (connect Play for the install step)'}
              </p>
            </div>
            <ConversionFunnel steps={growth.funnel} />
          </div>
        </>
      )}

      {/* Health + Recent signups */}
      <div className="grid grid-cols-1 lg:grid-cols-5 gap-4">
        <div className="lg:col-span-3 rounded-lg border border-[var(--line)] bg-[var(--surface)] p-5">
          <div className="flex items-center justify-between mb-4">
            <div>
              <h2 className="text-[14px] font-semibold text-[var(--ink)]">System Health</h2>
              <p className="text-[12px] text-[var(--ink-muted)]">Firebase services</p>
            </div>
            <Link href="/admin/system" className="text-[12px] text-[var(--accent)] hover:underline">View all →</Link>
          </div>
          {healthRefreshing && <RevalidatingBar />}
          <div className="flex flex-col divide-y divide-[var(--line)]">
            {healthLoading
              ? Array.from({ length: 5 }).map((_, i) => (
                <div key={i} className="py-2.5 flex items-center justify-between">
                  <Skeleton className="h-3 w-32" />
                  <Skeleton className="h-3 w-24" />
                </div>
              ))
              : (healthData?.services ?? []).slice(0, 6).map((svc) => (
                <div key={svc.name} className="flex items-center justify-between py-2">
                  <StatusDot
                    status={svc.status === 'healthy' ? 'good' : svc.status === 'degraded' ? 'warn' : 'bad'}
                    label={svc.displayName}
                  />
                  <div className="flex items-center gap-4">
                    <span className="text-[12px] text-[var(--ink-muted)] font-mono">{svc.p95Latency}ms p95</span>
                    <span className="text-[12px] text-[var(--ink-faint)] font-mono">{svc.uptime.toFixed(2)}%</span>
                  </div>
                </div>
              ))
            }
          </div>
        </div>

        <div className="lg:col-span-2 rounded-lg border border-[var(--line)] bg-[var(--surface)] p-5">
          <div className="mb-4">
            <h2 className="text-[14px] font-semibold text-[var(--ink)]">Recent Signups</h2>
            <p className="text-[12px] text-[var(--ink-muted)]">Latest 10 new users</p>
          </div>
          {analyticsLoading
            ? Array.from({ length: 5 }).map((_, i) => (
              <div key={i} className="flex items-center justify-between py-2.5 border-b border-[var(--line)] last:border-0">
                <Skeleton className="h-3 w-36" />
                <Skeleton className="h-3 w-16" />
              </div>
            ))
            : (
              <div className="flex flex-col gap-0">
                {(data?.recentSignups ?? []).length === 0 && (
                  <p className="text-[13px] text-[var(--ink-faint)]">No users yet</p>
                )}
                {(data?.recentSignups ?? []).map((u) => (
                  <Link
                    key={u.uid}
                    href={`/admin/users/${u.uid}`}
                    className="flex items-start justify-between gap-3 py-2.5 border-b border-[var(--line)] last:border-0 hover:text-[var(--accent)] transition-colors group"
                  >
                    <div className="flex-1 min-w-0">
                      <span className="text-[12.5px] text-[var(--ink)] group-hover:text-[var(--accent)] leading-snug block truncate">{u.name}</span>
                      {u.businessName && (
                        <span className="text-[11px] text-[var(--ink-faint)] block truncate">{u.businessName}</span>
                      )}
                    </div>
                    <span className="text-[11px] text-[var(--ink-faint)] whitespace-nowrap shrink-0 pt-0.5">{timeAgo(u.createdAt)}</span>
                  </Link>
                ))}
              </div>
            )
          }
        </div>
      </div>
    </div>
  )
}

// ── Growth section helpers ──────────────────────────────────────────────────

function GrowthStat({
  label, value, deltaPct, sublabel, invert = false, icon,
}: {
  label: string
  value: string
  deltaPct: number | null
  sublabel?: string
  /** When true, a rising number is bad (e.g. uninstalls) — flips the colour. */
  invert?: boolean
  icon?: React.ReactNode
}) {
  const up = deltaPct !== null && deltaPct > 0
  const down = deltaPct !== null && deltaPct < 0
  const flat = deltaPct === 0
  const good = invert ? down : up
  const bad = invert ? up : down

  return (
    <div
      className="rounded-lg border border-[var(--line)] bg-[var(--surface)] p-5 flex flex-col gap-3"
      style={{ boxShadow: 'var(--card-shadow)' }}
    >
      <div className="flex items-center justify-between">
        <span className="text-[11px] font-semibold uppercase tracking-widest text-[var(--ink-muted)]">{label}</span>
        {icon && <span className="text-[var(--ink-faint)]">{icon}</span>}
      </div>
      <div className="text-[26px] font-semibold leading-none font-mono text-[var(--ink)]">{value}</div>
      <div className="flex items-center gap-1 text-[12px] font-medium">
        {deltaPct === null ? (
          <span className="text-[var(--ink-faint)] font-normal">{sublabel ?? 'no prior data'}</span>
        ) : (
          <>
            <span
              className={
                good ? 'text-[var(--status-good)] flex items-center gap-1'
                  : bad ? 'text-[var(--status-bad)] flex items-center gap-1'
                    : 'text-[var(--ink-muted)] flex items-center gap-1'
              }
            >
              {up && <TrendingUp className="h-3.5 w-3.5" />}
              {down && <TrendingDown className="h-3.5 w-3.5" />}
              {flat && <Minus className="h-3.5 w-3.5" />}
              {up ? '+' : ''}{deltaPct}%
            </span>
            <span className="text-[var(--ink-faint)] font-normal">{sublabel ?? 'vs prior 30d'}</span>
          </>
        )}
      </div>
    </div>
  )
}

function UsageBreakdown({ usage }: { usage: { active7d: number; dormant30d: number; inactive: number } }) {
  const total = usage.active7d + usage.dormant30d + usage.inactive
  const rows = [
    { label: 'Active (≤7 days)', value: usage.active7d, color: 'var(--status-good)' },
    { label: 'Dormant (8–30 days)', value: usage.dormant30d, color: 'var(--status-warn)' },
    { label: 'Inactive (30+ days)', value: usage.inactive, color: 'var(--ink-faint)' },
  ]

  if (total === 0) {
    return <p className="text-[13px] text-[var(--ink-faint)] pt-2">No businesses yet</p>
  }

  return (
    <div className="flex flex-col gap-3">
      <div className="flex h-3 w-full overflow-hidden rounded-full bg-[var(--canvas)]">
        {rows.map((r) => r.value > 0 && (
          <div key={r.label} style={{ width: `${(r.value / total) * 100}%`, background: r.color }} />
        ))}
      </div>
      {rows.map((r) => (
        <div key={r.label} className="flex items-center justify-between text-[12px]">
          <span className="inline-flex items-center gap-1.5 text-[var(--ink-muted)]">
            <span className="h-2 w-2 rounded-full shrink-0" style={{ background: r.color }} />
            {r.label}
          </span>
          <span className="font-mono text-[var(--ink)]">
            {r.value.toLocaleString()} ({Math.round((r.value / total) * 100)}%)
          </span>
        </div>
      ))}
    </div>
  )
}
