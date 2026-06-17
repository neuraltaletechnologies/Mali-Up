'use client'

import { PageHeader } from '@/components/ui/page-header'
import { DataTable } from '@/components/ui/data-table'
import { KPICard } from '@/components/ui/kpi-card'
import { StatusDot } from '@/components/ui/status-dot'
import { PlanBadge } from '@/components/ui/plan-badge'
import { mockSubscriptions, mockDashboardKPIs } from '@/lib/mock-data'
import { formatTZS, formatTZSCompact, formatDate } from '@/lib/format'
import type { Subscription } from '@/types'
import type { ColumnDef } from '@tanstack/react-table'

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

const mrr = mockDashboardKPIs.mrr
const mrrGrowth = ((mrr - 13_700_000) / 13_700_000) * 100

export default function SubscriptionsPage() {
  const active = mockSubscriptions.filter((s) => s.status === 'active').length
  const pastDue = mockSubscriptions.filter((s) => s.status === 'past_due').length

  return (
    <div>
      <PageHeader
        title="Monthly Subscriptions"
        description="All recurring billing subscriptions"
      />

      <div className="grid grid-cols-4 gap-4 mb-6">
        <KPICard label="Monthly Recurring Revenue" value={`TZS ${formatTZSCompact(mrr)}`} delta={mrrGrowth} deltaLabel="vs last month" />
        <KPICard label="Active Subscriptions" value={active.toString()} mono={false} />
        <KPICard label="Past Due" value={pastDue.toString()} mono={false} />
        <KPICard label="Total Subscribers" value={mockSubscriptions.length.toString()} mono={false} />
      </div>

      <DataTable
        data={mockSubscriptions}
        columns={columns}
        searchPlaceholder="Search subscriptions…"
        exportFilename="subscriptions"
        emptyState={<p className="text-[var(--ink-faint)] text-[13px]">No subscriptions found</p>}
      />
    </div>
  )
}
