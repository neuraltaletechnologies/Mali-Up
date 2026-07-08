'use client'

import { useState, useCallback } from 'react'
import { PageHeader } from '@/components/ui/page-header'
import { Tabs } from '@/components/ui/tabs'
import { DataTable } from '@/components/ui/data-table'
import { KPICard } from '@/components/ui/kpi-card'
import { StatusDot } from '@/components/ui/status-dot'
import { PlanBadge } from '@/components/ui/plan-badge'
import { DetailDrawer } from '@/components/ui/detail-drawer'
import { GrowthChart } from '@/components/charts/growth-chart'
import { SkeletonTable, KPIRowSkeleton, RevalidatingBar } from '@/components/ui/skeleton'
import { fetchSubscriptions, fetchLifetime, fetchConfig } from '@/lib/admin-api'
import { useAdminFetch } from '@/hooks/use-admin-fetch'
import { formatTZS, formatTZSCompact, formatDate } from '@/lib/format'
import type { Subscription, LifetimeSubscription } from '@/types'
import type { ColumnDef } from '@tanstack/react-table'
import { AlertCircle, RefreshCw, AlertTriangle } from 'lucide-react'

function initialTab(): 'monthly' | 'lifetime' {
  if (typeof window === 'undefined') return 'monthly'
  return new URLSearchParams(window.location.search).get('tab') === 'lifetime' ? 'lifetime' : 'monthly'
}

// ─── Monthly tab ────────────────────────────────────────────────────────────────

const statusMap: Record<Subscription['status'], { status: 'good' | 'warn' | 'bad' | 'neutral'; label: string }> = {
  active:    { status: 'good',    label: 'Active' },
  past_due:  { status: 'bad',     label: 'Past Due' },
  cancelled: { status: 'neutral', label: 'Cancelled' },
  trialing:  { status: 'warn',    label: 'Trial' },
}

const monthlyColumns: ColumnDef<Subscription, unknown>[] = [
  {
    accessorKey: 'businessName',
    header: 'Business',
    cell: ({ row }) => <span className="font-medium text-[var(--ink)]">{row.original.businessName}</span>,
  },
  {
    accessorKey: 'plan',
    header: 'Plan',
    cell: ({ row }) => <PlanBadge tier={row.original.plan} />,
  },
  {
    accessorKey: 'status',
    header: 'Status',
    cell: ({ row }) => {
      const s = statusMap[row.original.status]
      return <StatusDot status={s.status} label={s.label} />
    },
  },
  {
    accessorKey: 'amount',
    header: 'Amount (TZS)',
    cell: ({ row }) => (
      <span className="font-mono tabular-nums text-[var(--ink)]">{formatTZS(row.original.amount)}</span>
    ),
  },
  {
    accessorKey: 'nextBillingDate',
    header: 'Next Billing',
    cell: ({ row }) => <span className="text-[var(--ink-muted)]">{formatDate(row.original.nextBillingDate)}</span>,
  },
  {
    accessorKey: 'paymentMethod',
    header: 'Payment',
    cell: ({ row }) => <span className="text-[var(--ink-muted)]">{row.original.paymentMethod}</span>,
  },
  {
    accessorKey: 'startedAt',
    header: 'Started',
    cell: ({ row }) => <span className="text-[var(--ink-muted)]">{formatDate(row.original.startedAt)}</span>,
  },
]

function MonthlyTab() {
  const { data, loading, revalidating, error } = useAdminFetch(
    useCallback(() => fetchSubscriptions(), []),
    { key: 'subscriptions' },
  )

  const subs = data?.subscriptions ?? []
  const active  = subs.filter((s) => s.status === 'active').length
  const pastDue = subs.filter((s) => s.status === 'past_due').length
  const mrr = subs.filter((s) => s.status === 'active').reduce((sum, s) => sum + s.amount, 0)

  if (loading) {
    return (
      <>
        <KPIRowSkeleton count={4} />
        <SkeletonTable rows={6} cols={7} />
      </>
    )
  }
  if (error && !data) {
    return (
      <div className="mt-4 flex items-center gap-3 rounded-lg border border-[var(--status-bad)] bg-[var(--status-bad-bg)] p-4 text-[var(--status-bad)]">
        <AlertCircle className="h-4 w-4 shrink-0" />
        <span className="text-[13px]">{error}</span>
      </div>
    )
  }

  return (
    <>
      {revalidating && <RevalidatingBar />}
      <div className="grid grid-cols-4 gap-4 mb-6">
        <KPICard label="Monthly Recurring Revenue" value={`TZS ${formatTZSCompact(mrr)}`} />
        <KPICard label="Active Subscriptions" value={active.toString()} mono={false} />
        <KPICard label="Past Due" value={pastDue.toString()} mono={false} />
        <KPICard label="Total Subscribers" value={subs.length.toString()} mono={false} />
      </div>
      <DataTable
        data={subs}
        columns={monthlyColumns}
        searchPlaceholder="Search subscriptions…"
        exportFilename="subscriptions"
        emptyState={<p className="text-[var(--ink-faint)] text-[13px]">No paid subscriptions found</p>}
      />
    </>
  )
}

// ─── Lifetime tab ───────────────────────────────────────────────────────────────

const lifetimeStatusMap: Record<LifetimeSubscription['status'], { status: 'good' | 'warn' | 'bad' | 'neutral'; label: string }> = {
  active:             { status: 'good',    label: 'Active' },
  refund_requested:   { status: 'warn',    label: 'Refund Requested' },
  refund_processing:  { status: 'warn',    label: 'Processing' },
  refunded:           { status: 'neutral', label: 'Refunded' },
}

const lifetimeColumns: ColumnDef<LifetimeSubscription, unknown>[] = [
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
      const s = lifetimeStatusMap[row.original.status]
      return <StatusDot status={s.status} label={s.label} />
    },
  },
]

function LifetimeTab() {
  const [selected, setSelected] = useState<LifetimeSubscription | null>(null)
  const [reconcileMode, setReconcileMode] = useState(false)
  const [reconcileValue, setReconcileValue] = useState('')

  const { data: lifetimeData, loading, revalidating, error } =
    useAdminFetch(useCallback(() => fetchLifetime(), []), { key: 'lifetime' })
  const { data: configData } =
    useAdminFetch(useCallback(() => fetchConfig(), []), { key: 'config' })

  const lifetime = lifetimeData?.lifetime ?? []
  const monthlyRate = configData?.lifetimeProgram?.uttAMISMonthlyRate ?? 1
  const totalPrincipal  = lifetime.reduce((s, l) => s + l.principal, 0)
  const totalBalance    = lifetime.reduce((s, l) => s + l.uttAMISBalance, 0)
  const thisMonthReturn = lifetime.reduce((s, l) => s + l.thisMonthReturn, 0)
  const avgMonths = lifetime.length > 0
    ? Math.round(lifetime.reduce((s, l) => s + l.monthsActive, 0) / lifetime.length)
    : 0

  if (loading) {
    return (
      <>
        <KPIRowSkeleton count={4} />
        <SkeletonTable rows={5} cols={7} />
      </>
    )
  }
  if (error && !lifetimeData) {
    return (
      <div className="mt-4 flex items-center gap-3 rounded-lg border border-[var(--status-bad)] bg-[var(--status-bad-bg)] p-4 text-[var(--status-bad)]">
        <AlertCircle className="h-4 w-4 shrink-0" />
        <span className="text-[13px]">{error}</span>
      </div>
    )
  }

  return (
    <>
      {revalidating && <RevalidatingBar />}

      <div className="mb-4 flex justify-end">
        <button
          onClick={() => setReconcileMode(true)}
          className="inline-flex items-center gap-1.5 rounded-md border border-[var(--line)] bg-[var(--surface)] px-3 py-1.5 text-[12px] font-medium text-[var(--ink-muted)] hover:text-[var(--ink)] transition-colors"
        >
          <RefreshCw className="h-3.5 w-3.5" />
          Reconcile with UTT AMIS
        </button>
      </div>

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
        columns={lifetimeColumns}
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
              status={lifetimeStatusMap[selected.status].status}
              label={lifetimeStatusMap[selected.status].label}
            />

            {(selected.status === 'active' || selected.status === 'refund_requested') && (
              <a
                href="/admin/plan-requests?tab=refunds"
                className="inline-flex items-center justify-center rounded-md bg-[var(--status-bad)] px-4 py-2 text-[13px] font-medium text-white hover:opacity-90 transition-opacity"
              >
                Process refund →
              </a>
            )}
          </div>
        )}
      </DetailDrawer>
    </>
  )
}

// ─── Page ─────────────────────────────────────────────────────────────────────

export default function SubscriptionsPage() {
  const [tab, setTab] = useState<'monthly' | 'lifetime'>(initialTab)

  return (
    <div>
      <PageHeader
        title="Subscriptions"
        description={tab === 'monthly' ? 'All recurring monthly billing subscriptions' : 'UTT AMIS investment tracking and refund management'}
      />

      <Tabs
        tabs={[
          { id: 'monthly', label: 'Monthly' },
          { id: 'lifetime', label: 'Lifetime' },
        ]}
        active={tab}
        onChange={(id) => setTab(id as 'monthly' | 'lifetime')}
        className="mb-6"
      />

      {tab === 'monthly' ? <MonthlyTab /> : <LifetimeTab />}
    </div>
  )
}
