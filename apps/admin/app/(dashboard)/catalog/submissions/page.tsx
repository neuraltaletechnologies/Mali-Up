'use client'

import { useState } from 'react'
import { PageHeader } from '@/components/ui/page-header'
import { DataTable } from '@/components/ui/data-table'
import { DetailDrawer } from '@/components/ui/detail-drawer'
import { mockSubmissions } from '@/lib/mock-data'
import type { CommunitySubmission } from '@/types'
import type { ColumnDef } from '@tanstack/react-table'
import { formatDate } from '@/lib/format'
import { Check, X } from 'lucide-react'

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
      <div className="flex gap-1">
        <button className="inline-flex items-center gap-1 rounded px-2 py-1 text-[11px] font-medium bg-[var(--status-good-bg)] text-[var(--status-good)] hover:opacity-80 transition-opacity">
          <Check className="h-3 w-3" />
          Approve
        </button>
        <button className="inline-flex items-center gap-1 rounded px-2 py-1 text-[11px] font-medium bg-[var(--status-bad-bg)] text-[var(--status-bad)] hover:opacity-80 transition-opacity">
          <X className="h-3 w-3" />
          Reject
        </button>
      </div>
    ),
  },
]

export default function SubmissionsPage() {
  const pending = mockSubmissions.filter((s) => s.status === 'pending')

  return (
    <div>
      <PageHeader
        title="Community Submissions"
        description={`${pending.length} products pending review — sorted by most submitted`}
      />

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
              Products submitted by businesses will appear here for review
            </p>
          </div>
        }
      />
    </div>
  )
}
