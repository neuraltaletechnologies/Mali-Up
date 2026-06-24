'use client'

import { useState, useCallback } from 'react'
import { PageHeader } from '@/components/ui/page-header'
import { KPICard } from '@/components/ui/kpi-card'
import { DataTable } from '@/components/ui/data-table'
import { StatusDot } from '@/components/ui/status-dot'
import { DetailDrawer } from '@/components/ui/detail-drawer'
import { GrowthChart } from '@/components/charts/growth-chart'
import { PlanBadge } from '@/components/ui/plan-badge'
import { KPIRowSkeleton, SkeletonTable, RevalidatingBar } from '@/components/ui/skeleton'
import { fetchLifetime, fetchConfig } from '@/lib/admin-api'
import { useAdminFetch } from '@/hooks/use-admin-fetch'
import { formatTZS, formatTZSCompact, formatDate } from '@/lib/format'
import type { LifetimeSubscription } from '@/types'
import type { ColumnDef } from '@tanstack/react-table'
import { RefreshCw, AlertTriangle, AlertCircle } from 'lucide-react'

const statusMap: Record<LifetimeSubscription['status'], { status: 'good' | 'warn' | 'bad' | 'neutral'; label: string }> = {
  active:             { status: 'good',    label: 'Active' },
  refund_requested:   { status: 'warn',    label: 'Refund Requested' },
  refund_processing:  { status: 'warn',    label: 'Processing' },
  refunded:           { status: 'neutral', label: 'Refunded' },
}

const columns: ColumnDef<LifetimeSubscription, unknown>[] = [
  {
    accessorKey: 'businessName',
    header: 'Business',
    cell: ({ row }) => (
      <div>
        <div className="font-medium text-[var(--ink)]">{row.original.businessName}</div>
        <div className="text-[11px] text-[var(--ink-muted)]">{row.original.ownerName}</div>
      </div>
    ),
  },
  {
    accessorKey: 'tier',
    header: 'Tier',
    cell: ({ row }) => <PlanBadge tier={row.original.tier} />,
  },
  {
    accessorKey: 'principal',
    header: 'Principal (TZS)',
    cell: ({ row }) => (
      <span className="font-mono text-[var(--ink)] tabular-nums">{formatTZS(row.original.principal)}</span>
    ),
  },
  {
    accessorKey: 'activatedAt',
    header: 'Activated',
    cell: ({ row }) => <span className="text-[var(--ink-muted)]">{formatDate(row.original.activatedAt)}</span>,
  },
  {
    accessorKey: 'monthsActive',
    header: 'Months',
    cell: ({ row }) => <span className="font-mono text-[var(--ink)]">{row.original.monthsActive}</span>,
  },
  {
    accessorKey: 'uttAMISBalance',
    header: 'UTT AMIS Balance',
    cell: ({ row }) => (
      <span className="font-mono text-[var(--ink)] tabular-nums">{formatTZS(row.original.uttAMISBalance)}</span>
    ),
  },
  {
    accessorKey: 'thisMonthReturn',
    header: 'This Month',
    cell: ({ row }) => (
      <span className="font-mono text-[var(--status-good)] tabular-nums">+{formatTZS(row.original.thisMonthReturn)}</span>
    ),
  },
  {
    accessorKey: 'status',
    header: 'Status',
    cell: ({ row }) => {
      const s = statusMap[row.original.status]
      return <StatusDot status={s.status} label={s.label} />
    },
  },
]

export default function LifetimePage() {
  const [selected, setSelected] = useState<LifetimeSubscription | null>(null)
  const [reconcileMode, setReconcileMode] = useState(false)
  const [reconcileValue, setReconcileValue] = useState('')

  const { data: lifetimeData, loading: lifetimeLoading, revalidating: lifetimeRefreshing, error: lifetimeError } =
    useAdminFetch(useCallback(() => fetchLifetime(), []), { key: 'lifetime' })
  const { data: configData } =
    useAdminFetch(useCallback(() => fetchConfig(), []))

  const lifetime = lifetimeData?.lifetime ?? []
  const monthlyRate = configData?.lifetimeProgram?.uttAMISMonthlyRate ?? 1
  const totalPrincipal  = lifetime.reduce((s, l) => s + l.principal, 0)
  const totalBalance    = lifetime.reduce((s, l) => s + l.uttAMISBalance, 0)
  const thisMonthReturn = lifetime.reduce((s, l) => s + l.thisMonthReturn, 0)
  const avgMonths = lifetime.length > 0
    ? Math.round(lifetime.reduce((s, l) => s + l.monthsActive, 0) / lifetime.length)
    : 0

  return (
    <div>
      {lifetimeRefreshing && <RevalidatingBar />}
      {lifetimeLoading && (
        <>
          <KPIRowSkeleton count={4} />
          <SkeletonTable rows={5} cols={7} />
        </>
      )}
      {lifetimeError && !lifetimeData && (
        <div className="mt-4 flex items-center gap-3 rounded-lg border border-[var(--status-bad)] bg-[var(--status-bad-bg)] p-4 text-[var(--status-bad)]">
          <AlertCircle className="h-4 w-4 shrink-0" />
          <span className="text-[13px]">{lifetimeError}</span>
        </div>
      )}
      {!lifetimeLoading && (
      <PageHeader
        title="Lifetime Subscriptions"
        description="UTT AMIS investment tracking and refund management"
      >
        <button
          onClick={() => setReconcileMode(true)}
          className="inline-flex items-center gap-1.5 rounded-md border border-[var(--line)] bg-[var(--surface)] px-3 py-1.5 text-[12px] font-medium text-[var(--ink-muted)] hover:text-[var(--ink)] transition-colors"
        >
          <RefreshCw className="h-3.5 w-3.5" />
          Reconcile with UTT AMIS
        </button>
      </PageHeader>

      <div className="grid grid-cols-4 gap-4 mb-6">
        <KPICard label="Total Lifetime Users" value={lifetime.length.toString()} mono={false} />
        <KPICard label="Total Principal in UTT AMIS" value={`TZS ${formatTZSCompact(totalPrincipal)}`} />
        <KPICard label="This Month's Interest" value={`TZS ${formatTZSCompact(thisMonthReturn)}`} />
        <KPICard label="Avg. Months Held" value={`${avgMonths} months`} mono={false} />
      </div>

      {reconcileMode && (
        <div className="mb-4 flex items-center gap-3 rounded-lg border border-[var(--status-warn)] bg-[var(--status-warn-bg)] px-4 py-3">
          <AlertTriangle className="h-4 w-4 text-[var(--status-warn)] shrink-0" />
          <span className="text-[12px] text-[var(--status-warn)] font-medium">Enter actual UTT AMIS total balance from your statement:</span>
          <input
            value={reconcileValue}
            onChange={(e) => setReconcileValue(e.target.value)}
            placeholder="e.g. 25,000,000"
            className="rounded border border-[var(--line)] bg-[var(--surface)] px-2 py-1 text-[12px] font-mono text-[var(--ink)] focus:outline-none focus:ring-1 focus:ring-[var(--accent)] w-40"
          />
          <button
            onClick={() => {
              const actual = parseInt(reconcileValue.replace(/,/g, ''))
              const diff   = actual - totalBalance
              alert(diff === 0 ? 'Balances match ✓' : `Mismatch: ${diff > 0 ? '+' : ''}TZS ${diff.toLocaleString()}`)
              setReconcileMode(false)
              setReconcileValue('')
            }}
            className="rounded-md bg-[var(--status-warn)] px-3 py-1 text-[12px] font-medium text-white hover:opacity-90"
          >
            Check
          </button>
          <button onClick={() => setReconcileMode(false)} className="text-[12px] text-[var(--ink-faint)] hover:text-[var(--ink)]">Cancel</button>
        </div>
      )}

      <DataTable
        data={lifetime}
        columns={columns}
        searchPlaceholder="Search lifetime subscribers…"
        onRowClick={setSelected}
        exportFilename="lifetime-subscriptions"
        emptyState={
          <p className="text-[var(--ink-faint)] text-[13px]">
            No lifetime subscribers yet. Add records to the <span className="font-mono">platform_lifetime</span> Firestore collection.
          </p>
        }
      />

      <DetailDrawer
        open={!!selected}
        onClose={() => setSelected(null)}
        title={selected?.businessName ?? ''}
        description={selected ? `Lifetime ${selected.tier} — activated ${formatDate(selected.activatedAt)}` : ''}
      >
        {selected && (
          <div className="flex flex-col gap-5">
            <div className="grid grid-cols-2 gap-3 text-[13px]">
              {[
                ['Principal', formatTZS(selected.principal)],
                ['UTT AMIS Ref', selected.uttAMISReference ?? '—'],
                ['Current Balance', formatTZS(selected.uttAMISBalance)],
                ['This Month Return', `+${formatTZS(selected.thisMonthReturn)}`],
                ['Months Active', `${selected.monthsActive} months`],
                ['Monthly Rate', `${monthlyRate}%`],
              ].map(([label, value]) => (
                <div key={label} className="flex flex-col gap-1">
                  <span className="text-[11px] uppercase tracking-wide text-[var(--ink-faint)]">{label}</span>
                  <span className="font-mono font-medium text-[var(--ink)]">{value}</span>
                </div>
              ))}
            </div>

            <div>
              <h4 className="text-[12px] font-semibold text-[var(--ink-muted)] uppercase tracking-wide mb-2">Balance Growth</h4>
              <GrowthChart
                principal={selected.principal}
                monthsActive={selected.monthsActive}
                monthlyRate={monthlyRate}
              />
              <p className="text-[11px] text-[var(--ink-faint)] mt-1">Dashed = projected, solid = actual</p>
            </div>

            <StatusDot
              status={statusMap[selected.status].status}
              label={statusMap[selected.status].label}
            />

            {(selected.status === 'active' || selected.status === 'refund_requested') && (
              <a
                href="/refunds"
                className="inline-flex items-center justify-center rounded-md bg-[var(--status-bad)] px-4 py-2 text-[13px] font-medium text-white hover:opacity-90 transition-opacity"
              >
                Process refund →
              </a>
            )}
          </div>
        )}
      </DetailDrawer>
      )}
    </div>
  )
}
