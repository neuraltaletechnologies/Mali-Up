'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import { PageHeader } from '@/components/ui/page-header'
import { DataTable } from '@/components/ui/data-table'
import { StatusDot } from '@/components/ui/status-dot'
import { SegmentedControl } from '@/components/ui/segmented-control'
import { Skeleton } from '@/components/ui/skeleton'
import { fetchUsers } from '@/lib/admin-api'
import { useAdminFetch } from '@/hooks/use-admin-fetch'
import { formatDate, timeAgo } from '@/lib/format'
import { AlertCircle } from 'lucide-react'
import type { AdminUser, UserStatus } from '@/types'
import type { ColumnDef } from '@tanstack/react-table'

const columns: ColumnDef<AdminUser, unknown>[] = [
  {
    accessorKey: 'name',
    header: 'Name',
    cell: ({ row }) => (
      <div>
        <div className="font-medium text-[var(--ink)]">{row.original.name}</div>
        <div className="text-[11px] font-mono text-[var(--ink-faint)]">{row.original.phone}</div>
      </div>
    ),
  },
  {
    accessorKey: 'email',
    header: 'Email',
    cell: ({ row }) => (
      <span className="text-[var(--ink-muted)] text-[12px]">
        {row.original.email ?? <span className="text-[var(--ink-faint)]">—</span>}
      </span>
    ),
  },
  {
    accessorKey: 'status',
    header: 'Status',
    cell: ({ row }) => {
      const s = row.original.status
      return (
        <StatusDot
          status={s === 'active' ? 'good' : s === 'suspended' ? 'bad' : 'warn'}
          label={s.charAt(0).toUpperCase() + s.slice(1)}
        />
      )
    },
  },
  {
    accessorKey: 'businessCount',
    header: 'Businesses',
    cell: ({ row }) => (
      <span className="font-mono text-[var(--ink)]">{row.original.businessCount}</span>
    ),
  },
  {
    accessorKey: 'lastLogin',
    header: 'Last Login',
    cell: ({ row }) => <span className="text-[var(--ink-muted)]">{timeAgo(row.original.lastLogin)}</span>,
  },
  {
    accessorKey: 'joinedAt',
    header: 'Joined',
    cell: ({ row }) => <span className="text-[var(--ink-muted)]">{formatDate(row.original.joinedAt)}</span>,
  },
]

export default function UsersPage() {
  const [statusFilter, setStatusFilter] = useState<'all' | UserStatus>('all')
  const router = useRouter()
  const { data, loading, error } = useAdminFetch(() => fetchUsers())

  const users = data?.users ?? []

  const filtered = statusFilter === 'all'
    ? users
    : users.filter((u) => u.status === statusFilter)

  if (loading) {
    return (
      <div>
        <PageHeader title="Users" description="Loading…" />
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
        <PageHeader title="Users" description="Failed to load" />
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
        title="Users"
        description={`${data?.total ?? 0} platform users`}
      />

      <div className="mb-4">
        <SegmentedControl
          options={[
            { value: 'all', label: 'All', count: users.length },
            { value: 'active', label: 'Active', count: users.filter(u => u.status === 'active').length },
            { value: 'suspended', label: 'Suspended', count: users.filter(u => u.status === 'suspended').length },
            { value: 'pending', label: 'Pending', count: users.filter(u => u.status === 'pending').length },
          ]}
          value={statusFilter}
          onChange={(v) => setStatusFilter(v as 'all' | UserStatus)}
        />
      </div>

      <DataTable
        data={filtered}
        columns={columns}
        searchPlaceholder="Search users…"
        onRowClick={(u) => router.push(`/users/${u.id}`)}
        exportFilename="users"
        emptyState={
          <div className="text-center py-8">
            <p className="text-[var(--ink-muted)] text-[13px]">No users match this filter</p>
          </div>
        }
      />
    </div>
  )
}
