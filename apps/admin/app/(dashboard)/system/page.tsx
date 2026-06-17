import { PageHeader } from '@/components/ui/page-header'
import { StatusDot } from '@/components/ui/status-dot'
import { ServiceSparkline } from '@/components/charts/service-sparkline'
import { mockServices } from '@/lib/mock-data'
import { cn } from '@/lib/utils'

export default function SystemPage() {
  const degraded = mockServices.filter((s) => s.status !== 'healthy')

  return (
    <div>
      <PageHeader
        title="System Health"
        description={
          degraded.length === 0
            ? 'All 11 services healthy'
            : `${degraded.length} service${degraded.length > 1 ? 's' : ''} degraded`
        }
      />

      {degraded.length > 0 && (
        <div className="mb-6 rounded-lg border border-[var(--status-warn)] bg-[var(--status-warn-bg)] px-4 py-3 text-[13px] text-[var(--status-warn)] font-medium">
          {degraded.map((s) => s.displayName).join(', ')} {degraded.length === 1 ? 'is' : 'are'} degraded. Check service logs for details.
        </div>
      )}

      {/* Service grid */}
      <div className="grid grid-cols-3 gap-3 mb-6">
        {mockServices.map((svc) => {
          const isDegraded = svc.status === 'degraded'
          const isDown = svc.status === 'down'
          return (
            <div
              key={svc.name}
              className={cn(
                'rounded-lg border p-4 flex flex-col gap-2',
                isDegraded ? 'border-[var(--status-warn)] bg-[var(--status-warn-bg)]' :
                isDown ? 'border-[var(--status-bad)] bg-[var(--status-bad-bg)]' :
                'border-[var(--line)] bg-[var(--surface)]'
              )}
            >
              <div className="flex items-center justify-between">
                <StatusDot
                  status={isDown ? 'bad' : isDegraded ? 'warn' : 'good'}
                  label={svc.displayName}
                />
                <span className="font-mono text-[11px] text-[var(--ink-faint)]">{svc.uptime.toFixed(2)}%</span>
              </div>

              <div className="flex items-center justify-between">
                <span className="font-mono text-[12px] text-[var(--ink-muted)]">{svc.p95Latency}ms p95</span>
                <ServiceSparkline
                  data={svc.sparkline}
                  color={isDegraded ? 'var(--status-warn)' : isDown ? 'var(--status-bad)' : 'var(--ink-faint)'}
                />
              </div>
            </div>
          )
        })}
      </div>

      {/* Combined request rate note */}
      <div className="rounded-lg border border-[var(--line)] bg-[var(--surface)] p-5">
        <h2 className="text-[14px] font-semibold text-[var(--ink)] mb-1">Request Rate</h2>
        <p className="text-[12px] text-[var(--ink-muted)]">
          Combined request rate chart across all services will be available when connected to a real monitoring backend (e.g. Prometheus / Grafana).
        </p>
      </div>
    </div>
  )
}
