'use client'

import { PageHeader } from '@/components/ui/page-header'
import { KPICard } from '@/components/ui/kpi-card'
import { StatusDot } from '@/components/ui/status-dot'
import { MRRTrendChart } from '@/components/charts/mrr-trend-chart'
import { TierDonut } from '@/components/charts/tier-donut'
import { KPIRowSkeleton, ChartSkeleton, Skeleton, RevalidatingBar } from '@/components/ui/skeleton'
import { fetchAnalytics, fetchSystemHealth } from '@/lib/admin-api'
import { useAdminFetch } from '@/hooks/use-admin-fetch'
import { formatTZSCompact, timeAgo } from '@/lib/format'
import { Building2, Users, DollarSign, AlertCircle, RefreshCw } from 'lucide-react'
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
