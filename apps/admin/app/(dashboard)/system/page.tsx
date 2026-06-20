'use client'

import { useCallback } from 'react'
import { PageHeader } from '@/components/ui/page-header'
import { StatusDot } from '@/components/ui/status-dot'
import { ServiceSparkline } from '@/components/charts/service-sparkline'
import { Skeleton } from '@/components/ui/skeleton'
import { fetchSystemHealth } from '@/lib/admin-api'
import { useAdminFetch } from '@/hooks/use-admin-fetch'
import { cn } from '@/lib/utils'
import { AlertCircle } from 'lucide-react'

export default function SystemPage() {
  const { data, loading, error } = useAdminFetch(useCallback(() => fetchSystemHealth(), []))

  if (loading) {
    return (
      <div>
        <PageHeader title="System Health" description="Loading…" />
        <div className="grid grid-cols-3 gap-3 mb-6">
          {Array.from({ length: 11 }).map((_, i) => <Skeleton key={i} className="h-20 rounded-lg" />)}
        </div>
      </div>
    )
  }

  if (error) {
    return (
      <div>
        <PageHeader title="System Health" description="Failed to load" />
        <div className="mt-8 flex items-center gap-3 rounded-lg border border-[var(--status-bad)] bg-[var(--status-bad-bg)] p-4 text-[var(--status-bad)]">
          <AlertCircle className="h-4 w-4 shrink-0" />
          <span className="text-[13px]">{error}</span>
        </div>
      </div>
    )
  }

  const services = data?.services ?? []
  const degraded = services.filter((s) => s.status !== 'healthy')

  return (
    <div>
      <PageHeader
        title="System Health"
        description={
          degraded.length === 0
            ? `All ${services.length} services healthy`
            : `${degraded.length} service${degraded.length > 1 ? 's' : ''} degraded`
        }
      />

      {degraded.length > 0 && (
        <div className="mb-6 rounded-lg border border-[var(--status-warn)] bg-[var(--status-warn-bg)] px-4 py-3 text-[13px] text-[var(--status-warn)] font-medium">
          {degraded.map((s) => s.displayName).join(', ')} {degraded.length === 1 ? 'is' : 'are'} degraded. Check Firebase console for details.
        </div>
      )}

      {data?.firestoreLatencyMs !== undefined && (
        <div className="mb-4 text-[12px] text-[var(--ink-faint)]">
          Firestore round-trip: <span className="font-mono">{data.firestoreLatencyMs}ms</span>
          {data.manualOverrideAt && (
            <span className="ml-3">· Manual overrides active</span>
          )}
        </div>
      )}

      <div className="grid grid-cols-3 gap-3 mb-6">
        {services.map((svc) => {
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

      <div className="rounded-lg border border-[var(--line)] bg-[var(--surface)] p-5">
        <h2 className="text-[14px] font-semibold text-[var(--ink)] mb-1">Status Overrides</h2>
        <p className="text-[12px] text-[var(--ink-muted)]">
          To mark a service as degraded or down, update the{' '}
          <span className="font-mono">platform_system_health/current</span> document in Firestore
          with a <span className="font-mono">services</span> array containing the override entries.
        </p>
      </div>
    </div>
  )
}
