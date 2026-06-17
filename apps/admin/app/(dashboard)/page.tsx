import { PageHeader } from '@/components/ui/page-header'
import { KPICard } from '@/components/ui/kpi-card'
import { StatusDot } from '@/components/ui/status-dot'
import { MRRTrendChart } from '@/components/charts/mrr-trend-chart'
import { TierDonut } from '@/components/charts/tier-donut'
import { mockDashboardKPIs, mockServices } from '@/lib/mock-data'
import { formatTZS, formatTZSCompact, timeAgo } from '@/lib/format'
import { Building2, Users, DollarSign, TrendingUp, Headphones } from 'lucide-react'
import Link from 'next/link'

export default function DashboardPage() {
  const kpi = mockDashboardKPIs
  const total = kpi.planDistribution.reduce((s, d) => s + d.value, 0)

  return (
    <div>
      <PageHeader
        title="Platform Dashboard"
        description="Real-time health of the Mali Up platform"
      />

      {/* Row 1 — KPI cards */}
      <div className="grid grid-cols-5 gap-4 mb-6">
        <KPICard
          label="Total Businesses"
          value={kpi.totalBusinesses.toLocaleString()}
          delta={8.4}
          deltaLabel="vs last month"
          icon={<Building2 className="h-4 w-4" />}
          mono={false}
        />
        <KPICard
          label="Active Today"
          value={kpi.activeToday.toLocaleString()}
          delta={12.1}
          deltaLabel="vs yesterday"
          icon={<Users className="h-4 w-4" />}
          mono={false}
        />
        <KPICard
          label="Monthly Recurring Revenue"
          value={`TZS ${formatTZSCompact(kpi.mrr)}`}
          delta={2.4}
          deltaLabel="vs last month"
          icon={<DollarSign className="h-4 w-4" />}
        />
        <KPICard
          label="Lifetime AUM (UTT AMIS)"
          value={`TZS ${formatTZSCompact(kpi.lifetimeAUM)}`}
          delta={3.1}
          deltaLabel="vs last month"
          icon={<TrendingUp className="h-4 w-4" />}
        />
        <KPICard
          label="Open Tickets"
          value={kpi.openTickets.toString()}
          icon={<Headphones className="h-4 w-4" />}
          mono={false}
        />
      </div>

      {/* Row 2 — Charts */}
      <div className="grid grid-cols-5 gap-4 mb-6">
        {/* MRR Trend */}
        <div className="col-span-3 rounded-lg border border-[var(--line)] bg-[var(--surface)] p-5">
          <div className="mb-4">
            <h2 className="text-[14px] font-semibold text-[var(--ink)]">MRR Trend</h2>
            <p className="text-[12px] text-[var(--ink-muted)]">Last 12 months</p>
          </div>
          <MRRTrendChart data={kpi.mrrTrend} />
        </div>

        {/* Plan distribution */}
        <div className="col-span-2 rounded-lg border border-[var(--line)] bg-[var(--surface)] p-5">
          <div className="mb-4">
            <h2 className="text-[14px] font-semibold text-[var(--ink)]">Plan Distribution</h2>
            <p className="text-[12px] text-[var(--ink-muted)]">Businesses by tier</p>
          </div>
          <TierDonut data={kpi.planDistribution} total={total} />
        </div>
      </div>

      {/* Row 3 — System status + Activity feed */}
      <div className="grid grid-cols-5 gap-4">
        {/* System status */}
        <div className="col-span-3 rounded-lg border border-[var(--line)] bg-[var(--surface)] p-5">
          <div className="flex items-center justify-between mb-4">
            <div>
              <h2 className="text-[14px] font-semibold text-[var(--ink)]">System Health</h2>
              <p className="text-[12px] text-[var(--ink-muted)]">All microservices</p>
            </div>
            <Link href="/system" className="text-[12px] text-[var(--accent)] hover:underline">
              View all →
            </Link>
          </div>
          <div className="flex flex-col divide-y divide-[var(--line)]">
            {mockServices.map((svc) => (
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
            ))}
          </div>
        </div>

        {/* Live activity */}
        <div className="col-span-2 rounded-lg border border-[var(--line)] bg-[var(--surface)] p-5">
          <div className="mb-4">
            <h2 className="text-[14px] font-semibold text-[var(--ink)]">Live Activity</h2>
            <p className="text-[12px] text-[var(--ink-muted)]">Last 15 platform events</p>
          </div>
          <div className="flex flex-col gap-0">
            {kpi.recentActivity.map((event) => (
              <div
                key={event.id}
                className="flex items-start justify-between gap-3 py-2.5 border-b border-[var(--line)] last:border-0"
              >
                <span className="text-[12.5px] text-[var(--ink)] leading-snug flex-1">{event.text}</span>
                <span className="text-[11px] text-[var(--ink-faint)] whitespace-nowrap shrink-0 pt-0.5">
                  {timeAgo(event.time)}
                </span>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  )
}
