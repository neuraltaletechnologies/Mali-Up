'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import { PageHeader } from '@/components/ui/page-header'
import { DataTable } from '@/components/ui/data-table'
import { StatusDot } from '@/components/ui/status-dot'
import { PlanBadge } from '@/components/ui/plan-badge'
import { SegmentedControl } from '@/components/ui/segmented-control'
import { Skeleton } from '@/components/ui/skeleton'
import { fetchBusinesses } from '@/lib/admin-api'
import { useAdminFetch } from '@/hooks/use-admin-fetch'
import { formatTZS, timeAgo } from '@/lib/format'
import { AlertCircle } from 'lucide-react'
import type { Business, BusinessStatus } from '@/types'
import type { ColumnDef } from '@tanstack/react-table'

const columns: ColumnDef<Business, unknown>[] = [
  {
    accessorKey: 'name',
    header: 'Business',
    cell: ({ row }) => (
      <div>
        <div className="font-medium text-[var(--ink)]">{row.original.name}</div>
        <div className="text-[11px] text-[var(--ink-muted)]">
          {row.original.industry}
          {row.original.location ? ` · ${row.original.location}` : ''}
        </div>
      </div>
    ),
  },
  {
    accessorKey: 'ownerName',
    header: 'Owner',
    cell: ({ row }) => (
      <div>
        <div className="text-[var(--ink)]">{row.original.ownerName || '—'}</div>
        <div className="text-[11px] text-[var(--ink-faint)] font-mono">{row.original.ownerPhone}</div>
      </div>
    ),
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
      const s = row.original.status
      return (
        <StatusDot
          status={s === 'active' ? 'good' : s === 'suspended' ? 'bad' : s === 'pending' ? 'warn' : 'neutral'}
          label={s.charAt(0).toUpperCase() + s.slice(1)}
        />
      )
    },
  },
  {
    accessorKey: 'staffCount',
    header: 'Staff',
    cell: ({ row }) => <span className="font-mono text-[var(--ink)]">{row.original.staffCount}</span>,
  },
  {
    accessorKey: 'lastActive',
    header: 'Last Active',
    cell: ({ row }) => <span className="text-[var(--ink-muted)]">{timeAgo(row.original.lastActive)}</span>,
  },
  {
    accessorKey: 'mrr',
    header: 'MRR',
    cell: ({ row }) => (
      <span className="font-mono text-[var(--ink)] tabular-nums">
        {row.original.mrr > 0
          ? formatTZS(row.original.mrr)
          : <span className="text-[var(--ink-faint)]">—</span>
        }
      </span>
    ),
  },
]

export default function BusinessesPage() {
  const [statusFilter, setStatusFilter] = useState<'all' | BusinessStatus>('all')
  const router = useRouter()
  const { data, loading, error } = useAdminFetch(() => fetchBusinesses())

  const businesses = data?.businesses ?? []

  const filtered = statusFilter === 'all'
    ? businesses
    : businesses.filter((b) => b.status === statusFilter)

  if (loading) {
    return (
      <div>
        <PageHeader title="Businesses" description="Loading…" />
        <div className="space-y-2 mt-4">
          {Array.from({ length: 8 }).map((_, i) => (
            <Skeleton key={i} className="h-12 w-full rounded-md" />
          ))}
        </div>
      </div>
    )
  }

  if (error) {
    return (
      <div>
        <PageHeader title="Businesses" description="Failed to load" />
        <div className="mt-8 flex items-center gap-3 rounded-lg border border-[var(--status-bad)] bg-[var(--status-bad-bg)] p-4 text-[var(--status-bad)]">
          <AlertCircle className="h-4 w-4 shrink-0" />
          <span className="text-[13px]">{error}</span>
        </div>
      </div>
    )
  }

  return (
    <div>
      <PageHeader
        title="Businesses"
        description={`${data?.total ?? 0} registered businesses`}
      />

      <div className="mb-4">
        <SegmentedControl
          options={[
            { value: 'all', label: 'All', count: businesses.length },
            { value: 'active', label: 'Active', count: businesses.filter(b => b.status === 'active').length },
            { value: 'suspended', label: 'Suspended', count: businesses.filter(b => b.status === 'suspended').length },
            { value: 'inactive', label: 'Inactive', count: businesses.filter(b => b.status === 'inactive').length },
          ]}
          value={statusFilter}
          onChange={(v) => setStatusFilter(v as 'all' | BusinessStatus)}
        />
      </div>

      <DataTable
        data={filtered}
        columns={columns}
        searchPlaceholder="Search businesses…"
        onRowClick={(b) => router.push(`/businesses/${b.ownerId}/${b.id}`)}
        exportFilename="businesses"
        emptyState={
          <div className="text-center py-8">
            <p className="text-[var(--ink-muted)] text-[13px]">No businesses match this filter</p>
          </div>
        }
      />
    </div>
  )
}
