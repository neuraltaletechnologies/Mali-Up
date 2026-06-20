'use client'

import { PageHeader } from '@/components/ui/page-header'
import { KPICard } from '@/components/ui/kpi-card'
import { MRRTrendChart } from '@/components/charts/mrr-trend-chart'
import { Skeleton } from '@/components/ui/skeleton'
import { fetchAnalytics } from '@/lib/admin-api'
import { useAdminFetch } from '@/hooks/use-admin-fetch'
import { formatTZS, formatTZSCompact } from '@/lib/format'
import { AlertCircle } from 'lucide-react'

// Plan fees in TZS — kept in sync with firestore-mappers
const PLAN_FEES: Record<string, number> = {
  starter: 0,
  growth: 49_000,
  business: 120_000,
  enterprise: 350_000,
  lifetime: 0,
}

export default function RevenuePage() {
  const { data, loading, error } = useAdminFetch(() => fetchAnalytics())

  if (loading) {
    return (
      <div>
        <PageHeader title="Revenue Analytics" description="Loading…" />
        <div className="grid grid-cols-4 gap-4 mb-6">
          {Array.from({ length: 4 }).map((_, i) => (
            <Skeleton key={i} className="h-24 w-full rounded-lg" />
          ))}
        </div>
        <Skeleton className="h-72 w-full rounded-lg" />
      </div>
    )
  }

  if (error || !data) {
    return (
      <div>
        <PageHeader title="Revenue Analytics" description="Failed to load" />
        <div className="mt-8 flex items-center gap-3 rounded-lg border border-[var(--status-bad)] bg-[var(--status-bad-bg)] p-4 text-[var(--status-bad)]">
          <AlertCircle className="h-4 w-4 shrink-0" />
          <span className="text-[13px]">{error ?? 'Unknown error'}</span>
        </div>
      </div>
    )
  }

  // Compute per-plan breakdown
  const planBreakdown = data.planDistribution
    .filter((p) => PLAN_FEES[p.name.toLowerCase()] > 0)
    .map((p) => ({
      ...p,
      fee: PLAN_FEES[p.name.toLowerCase()] ?? 0,
      contribution: (PLAN_FEES[p.name.toLowerCase()] ?? 0) * p.value,
    }))

  const maxContribution = Math.max(...planBreakdown.map((p) => p.contribution), 1)
  const avgRevenuePerBusiness = data.totalBusinesses > 0
    ? Math.round(data.mrr / data.totalBusinesses)
    : 0

  return (
    <div>
      <PageHeader
        title="Revenue Analytics"
        description="Platform financial performance"
      />

      {/* KPI row */}
      <div className="grid grid-cols-4 gap-4 mb-6">
        <KPICard
          label="Current MRR"
          value={`TZS ${formatTZSCompact(data.mrr)}`}
          deltaLabel="monthly recurring"
        />
        <KPICard
          label="Est. Annual Revenue"
          value={`TZS ${formatTZSCompact(data.mrr * 12)}`}
        />
        <KPICard
          label="Avg Revenue / Business"
          value={avgRevenuePerBusiness > 0 ? formatTZS(avgRevenuePerBusiness) : '—'}
        />
        <KPICard
          label="Paying Businesses"
          value={planBreakdown.reduce((s, p) => s + p.value, 0).toLocaleString()}
          mono={false}
        />
      </div>

      <div className="grid grid-cols-5 gap-4">
        {/* MRR trend */}
        <div className="col-span-3 rounded-lg border border-[var(--line)] bg-[var(--surface)] p-5">
          <h2 className="text-[14px] font-semibold text-[var(--ink)] mb-1">MRR Trend</h2>
          <p className="text-[12px] text-[var(--ink-muted)] mb-4">Cumulative over last 12 months</p>
          <MRRTrendChart data={data.mrrTrend} />
        </div>

        {/* Per-plan revenue breakdown */}
        <div className="col-span-2 rounded-lg border border-[var(--line)] bg-[var(--surface)] p-5">
          <h2 className="text-[14px] font-semibold text-[var(--ink)] mb-1">Revenue by Plan</h2>
          <p className="text-[12px] text-[var(--ink-muted)] mb-5">Monthly contribution per tier</p>

          {planBreakdown.length === 0 ? (
            <p className="text-[13px] text-[var(--ink-faint)] pt-4">No paid businesses yet.</p>
          ) : (
            <div className="flex flex-col gap-4">
              {planBreakdown.map(({ name, value, fee, contribution, color }) => (
                <div key={name} className="flex items-center gap-3">
                  <div className="w-24 shrink-0">
                    <div className="text-[12px] font-medium text-[var(--ink)]">{name}</div>
                    <div className="text-[11px] text-[var(--ink-faint)]">{value} biz × {formatTZSCompact(fee)}</div>
                  </div>
                  <div className="flex-1 h-6 rounded overflow-hidden bg-[var(--canvas)]">
                    <div
                      className="h-full rounded transition-all"
                      style={{
                        width: `${(contribution / maxContribution) * 100}%`,
                        background: color,
                        opacity: 0.85,
                      }}
                    />
                  </div>
                  <span className="font-mono text-[12px] w-24 text-right shrink-0 text-[var(--ink)]">
                    TZS {formatTZSCompact(contribution)}
                  </span>
                </div>
              ))}

              {/* Total */}
              <div className="pt-3 border-t border-[var(--line)] flex items-center justify-between">
                <span className="text-[12px] font-semibold text-[var(--ink)]">Total MRR</span>
                <span className="font-mono text-[13px] font-semibold text-[var(--ink)]">
                  TZS {formatTZSCompact(data.mrr)}
                </span>
              </div>
            </div>
          )}
        </div>
      </div>

      {/* Plan counts table */}
      {data.planDistribution.length > 0 && (
        <div className="mt-4 rounded-lg border border-[var(--line)] bg-[var(--surface)] p-5">
          <h2 className="text-[14px] font-semibold text-[var(--ink)] mb-4">Plan Distribution Detail</h2>
          <div className="grid grid-cols-5 gap-3">
            {data.planDistribution.map(({ name, value, color }) => {
              const fee = PLAN_FEES[name.toLowerCase()] ?? 0
              return (
                <div key={name} className="rounded-md border border-[var(--line)] p-3">
                  <div className="flex items-center gap-2 mb-2">
                    <span className="h-2 w-2 rounded-full shrink-0" style={{ background: color }} />
                    <span className="text-[12px] font-medium text-[var(--ink)]">{name}</span>
                  </div>
                  <div className="text-[22px] font-mono font-semibold text-[var(--ink)]">
                    {value.toLocaleString()}
                  </div>
                  <div className="text-[11px] text-[var(--ink-faint)] mt-0.5">
                    {fee > 0 ? `TZS ${formatTZSCompact(fee)}/mo` : 'Free'}
                  </div>
                </div>
              )
            })}
          </div>
        </div>
      )}
    </div>
  )
}
