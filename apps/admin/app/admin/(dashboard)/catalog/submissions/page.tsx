'use client'

import { useState, useCallback } from 'react'
import { PageHeader } from '@/components/ui/page-header'
import { DataTable } from '@/components/ui/data-table'
import { SkeletonTable, RevalidatingBar } from '@/components/ui/skeleton'
import { fetchSubmissions, patchSubmission } from '@/lib/admin-api'
import { useAdminFetch } from '@/hooks/use-admin-fetch'
import type { CommunitySubmission } from '@/types'
import type { ColumnDef } from '@tanstack/react-table'
import { formatDate } from '@/lib/format'
import { Check, X, AlertCircle } from 'lucide-react'

function ActionButtons({
  submission,
  onAction,
}: {
  submission: CommunitySubmission
  onAction: (id: string, status: 'approved' | 'rejected') => Promise<void>
}) {
  const [acting, setActing] = useState<'approve' | 'reject' | null>(null)

  if (submission.status !== 'pending') {
    return (
      <span className={`text-[11px] font-medium ${submission.status === 'approved' ? 'text-[var(--status-good)]' : 'text-[var(--ink-faint)]'}`}>
        {submission.status === 'approved' ? 'Approved' : 'Rejected'}
      </span>
    )
  }

  return (
    <div className="flex gap-1">
      <button
        disabled={!!acting}
        onClick={async () => {
          setActing('approve')
          try { await onAction(submission.id, 'approved') } finally { setActing(null) }
        }}
        className="inline-flex items-center gap-1 rounded px-2 py-1 text-[11px] font-medium bg-[var(--status-good-bg)] text-[var(--status-good)] hover:opacity-80 disabled:opacity-40 transition-opacity"
      >
        <Check className="h-3 w-3" />
        {acting === 'approve' ? '…' : 'Approve'}
      </button>
      <button
        disabled={!!acting}
        onClick={async () => {
          setActing('reject')
          try { await onAction(submission.id, 'rejected') } finally { setActing(null) }
        }}
        className="inline-flex items-center gap-1 rounded px-2 py-1 text-[11px] font-medium bg-[var(--status-bad-bg)] text-[var(--status-bad)] hover:opacity-80 disabled:opacity-40 transition-opacity"
      >
        <X className="h-3 w-3" />
        {acting === 'reject' ? '…' : 'Reject'}
      </button>
    </div>
  )
}

export default function SubmissionsPage() {
  const { data, loading, revalidating, error, refetch } = useAdminFetch(
    useCallback(() => fetchSubmissions(), []),
    { key: 'submissions' },
  )

  async function handleAction(id: string, status: 'approved' | 'rejected') {
    await patchSubmission(id, status)
    refetch()
  }

  const columns: ColumnDef<CommunitySubmission, unknown>[] = [
    {
      accessorKey: 'productName',
      header: 'Product Name',
      cell: ({ row }) => <span className="font-medium text-[var(--ink)]">{row.original.productName}</span>,
    },
    {
      accessorKey: 'businessType',
      header: 'Business Type',
      cell: ({ row }) => <span className="text-[var(--ink-muted)]">{row.original.businessType}</span>,
    },
    {
      accessorKey: 'submissionCount',
      header: 'Submitted by',
      cell: ({ row }) => (
        <span className="font-mono font-semibold text-[var(--ink)]">{row.original.submissionCount} businesses</span>
      ),
    },
    {
      accessorKey: 'firstSeenAt',
      header: 'First Seen',
      cell: ({ row }) => <span className="text-[var(--ink-muted)]">{formatDate(row.original.firstSeenAt)}</span>,
    },
    {
      id: 'actions',
      header: 'Actions',
      cell: ({ row }) => (
        <ActionButtons submission={row.original} onAction={handleAction} />
      ),
    },
  ]

  const pending = (data?.submissions ?? []).filter((s) => s.status === 'pending')

  return (
    <div>
      <PageHeader
        title="Community Submissions"
        description={loading ? 'Loading…' : `${pending.length} products pending review — sorted by most submitted`}
      />
      {revalidating && <RevalidatingBar />}
      {loading ? (
        <SkeletonTable rows={5} cols={5} />
      ) : error && !data ? (
        <div className="mt-4 flex items-center gap-3 rounded-lg border border-[var(--status-bad)] bg-[var(--status-bad-bg)] p-4 text-[var(--status-bad)]">
          <AlertCircle className="h-4 w-4 shrink-0" />
          <span className="text-[13px]">{error}</span>
        </div>
      ) : (
        <>

      <div className="mb-4 rounded-lg border border-[var(--line)] bg-[var(--canvas)] px-4 py-3 text-[12px] text-[var(--ink-muted)]">
        Products below are items that multiple businesses independently added and flagged for catalog inclusion.
        High submission counts are strong signal — approve and pre-fill the catalog form, or reject with a reason.
      </div>

      <DataTable
        data={[...pending].sort((a, b) => b.submissionCount - a.submissionCount)}
        columns={columns}
        searchPlaceholder="Search submissions…"
        exportFilename="catalog-submissions"
        emptyState={
          <div className="text-center py-8">
            <p className="text-[var(--ink-muted)] text-[13px]">No pending submissions</p>
            <p className="text-[var(--ink-faint)] text-[12px] mt-1">
              Products submitted by businesses via the mobile app will appear here
            </p>
          </div>
        }
      />
        </>
      )}
    </div>
  )
}
