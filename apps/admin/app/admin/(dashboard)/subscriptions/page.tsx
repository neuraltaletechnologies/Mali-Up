'use client'

import { useCallback } from 'react'
import { PageHeader } from '@/components/ui/page-header'
import { DataTable } from '@/components/ui/data-table'
import { KPICard } from '@/components/ui/kpi-card'
import { StatusDot } from '@/components/ui/status-dot'
import { PlanBadge } from '@/components/ui/plan-badge'
import { SkeletonTable, KPIRowSkeleton, RevalidatingBar } from '@/components/ui/skeleton'
import { fetchSubscriptions } from '@/lib/admin-api'
import { useAdminFetch } from '@/hooks/use-admin-fetch'
import { formatTZS, formatTZSCompact, formatDate } from '@/lib/format'
import type { Subscription } from '@/types'
import type { ColumnDef } from '@tanstack/react-table'
import { AlertCircle } from 'lucide-react'

const statusMap: Record<Subscription['status'], { status: 'good' | 'warn' | 'bad' | 'neutral'; label: string }> = {
  active:    { status: 'good',    label: 'Active' },
  past_due:  { status: 'bad',     label: 'Past Due' },
  cancelled: { status: 'neutral', label: 'Cancelled' },
  trialing:  { status: 'warn',    label: 'Trial' },
}

const columns: ColumnDef<Subscription, unknown>[] = [
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

export default function SubscriptionsPage() {
  const { data, loading, revalidating, error } = useAdminFetch(
    useCallback(() => fetchSubscriptions(), []),
    { key: 'subscriptions' },
  )

  const subs = data?.subscriptions ?? []
  const active  = subs.filter((s) => s.status === 'active').length
  const pastDue = subs.filter((s) => s.status === 'past_due').length
  const mrr = subs.filter((s) => s.status === 'active').reduce((sum, s) => sum + s.amount, 0)

  return (
    <div>
      <PageHeader
        title="Monthly Subscriptions"
        description={loading ? 'Loading…' : 'All recurring billing subscriptions'}
      />
      {revalidating && <RevalidatingBar />}

      {loading ? (
        <>
          <KPIRowSkeleton count={4} />
          <SkeletonTable rows={6} cols={7} />
        </>
      ) : error && !data ? (
        <div className="mt-4 flex items-center gap-3 rounded-lg border border-[var(--status-bad)] bg-[var(--status-bad-bg)] p-4 text-[var(--status-bad)]">
          <AlertCircle className="h-4 w-4 shrink-0" />
          <span className="text-[13px]">{error}</span>
        </div>
      ) : (
        <>
          <div className="grid grid-cols-4 gap-4 mb-6">
            <KPICard label="Monthly Recurring Revenue" value={`TZS ${formatTZSCompact(mrr)}`} />
            <KPICard label="Active Subscriptions" value={active.toString()} mono={false} />
            <KPICard label="Past Due" value={pastDue.toString()} mono={false} />
            <KPICard label="Total Subscribers" value={subs.length.toString()} mono={false} />
          </div>
          <DataTable
            data={subs}
            columns={columns}
            searchPlaceholder="Search subscriptions…"
            exportFilename="subscriptions"
            emptyState={<p className="text-[var(--ink-faint)] text-[13px]">No paid subscriptions found</p>}
          />
        </>
      )}
    </div>
  )
}
