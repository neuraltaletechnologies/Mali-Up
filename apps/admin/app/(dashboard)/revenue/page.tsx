import { PageHeader } from '@/components/ui/page-header'
import { KPICard } from '@/components/ui/kpi-card'
import { MRRTrendChart } from '@/components/charts/mrr-trend-chart'
import { mockDashboardKPIs } from '@/lib/mock-data'
import { formatTZS, formatTZSCompact } from '@/lib/format'

const WATERFALL = [
  { label: 'New MRR', value: 1_200_000, color: 'var(--status-good)' },
  { label: 'Expansion', value: 450_000, color: 'var(--status-good)' },
  { label: 'Contraction', value: -180_000, color: 'var(--status-bad)' },
  { label: 'Churned', value: -320_000, color: 'var(--status-bad)' },
  { label: 'Net MRR Change', value: 1_150_000, color: 'var(--navy)' },
]

const maxAbs = Math.max(...WATERFALL.map((w) => Math.abs(w.value)))

export default function RevenuePage() {
  const kpi = mockDashboardKPIs

  return (
    <div>
      <PageHeader
        title="Revenue Analytics"
        description="Platform financial performance"
      />

      <div className="grid grid-cols-4 gap-4 mb-6">
        <KPICard label="Current MRR" value={`TZS ${formatTZSCompact(kpi.mrr)}`} delta={2.4} deltaLabel="vs last month" />
        <KPICard label="Lifetime AUM (UTT AMIS)" value={`TZS ${formatTZSCompact(kpi.lifetimeAUM)}`} delta={3.1} />
        <KPICard label="Est. Annual Revenue" value={`TZS ${formatTZSCompact(kpi.mrr * 12)}`} />
        <KPICard label="Avg Revenue / Business" value={formatTZS(Math.round(kpi.mrr / 847))} />
      </div>

      <div className="grid grid-cols-5 gap-4">
        {/* MRR Trend */}
        <div className="col-span-3 rounded-lg border border-[var(--line)] bg-[var(--surface)] p-5">
          <h2 className="text-[14px] font-semibold text-[var(--ink)] mb-1">MRR Trend</h2>
          <p className="text-[12px] text-[var(--ink-muted)] mb-4">Last 12 months</p>
          <MRRTrendChart data={kpi.mrrTrend} />
        </div>

        {/* MRR Waterfall */}
        <div className="col-span-2 rounded-lg border border-[var(--line)] bg-[var(--surface)] p-5">
          <h2 className="text-[14px] font-semibold text-[var(--ink)] mb-1">MRR Movement</h2>
          <p className="text-[12px] text-[var(--ink-muted)] mb-5">This month's changes</p>
          <div className="flex flex-col gap-3">
            {WATERFALL.map(({ label, value, color }) => (
              <div key={label} className="flex items-center gap-3">
                <span className="w-28 text-[12px] text-[var(--ink-muted)] shrink-0">{label}</span>
                <div className="flex-1 h-6 rounded flex items-center overflow-hidden bg-[var(--canvas)]">
                  <div
                    className="h-full rounded transition-all"
                    style={{
                      width: `${(Math.abs(value) / maxAbs) * 100}%`,
                      background: color,
                      opacity: 0.85,
                    }}
                  />
                </div>
                <span
                  className="font-mono text-[12px] w-28 text-right shrink-0"
                  style={{ color: value < 0 ? 'var(--status-bad)' : color }}
                >
                  {value >= 0 ? '+' : ''}TZS {formatTZSCompact(Math.abs(value))}
                </span>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  )
}
