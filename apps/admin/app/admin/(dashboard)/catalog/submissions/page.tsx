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
import { Check, X, AlertCircle, ChevronRight, Upload, Tag, Package, FolderOpen } from 'lucide-react'

// ─── Status badge ────────────────────────────────────────────────────────────

function StatusBadge({ status }: { status: CommunitySubmission['status'] }) {
  const cfg: Record<string, string> = {
    pending:  'bg-yellow-50 text-yellow-700 border-yellow-200',
    approved: 'bg-green-50 text-green-700 border-green-200',
    rejected: 'bg-red-50 text-red-600 border-red-200',
    pushed:   'bg-blue-50 text-blue-700 border-blue-200',
  }
  const label: Record<string, string> = {
    pending:  'Pending',
    approved: 'Approved',
    rejected: 'Rejected',
    pushed:   'Pushed to Catalog',
  }
  return (
    <span className={`inline-flex items-center rounded-full border px-2 py-0.5 text-[10px] font-semibold ${cfg[status] ?? cfg.pending}`}>
      {label[status] ?? status}
    </span>
  )
}

// ─── Detail drawer ────────────────────────────────────────────────────────────

function DetailDrawer({
  submission,
  onClose,
  onRefetch,
}: {
  submission: CommunitySubmission
  onClose: () => void
  onRefetch: () => void
}) {
  const [form, setForm] = useState({
    productName:    submission.productName,
    categoryName:   submission.categoryName ?? submission.productName,
    categorySlug:   submission.categorySlug,
    unit:           submission.unit || 'Piece',
    businessTypeName: submission.businessTypeName || submission.businessType,
    adminNotes:     submission.adminNotes,
  })
  const [acting, setActing] = useState<string | null>(null)

  const isProduct  = submission.type !== 'category'
  const isPushed   = submission.status === 'pushed'
  const isPending  = submission.status === 'pending'

  async function handleAction(action: 'approve' | 'reject' | 'push') {
    setActing(action)
    try {
      await patchSubmission(submission.id, action, {
        adminNotes:      form.adminNotes,
        productName:     isProduct ? form.productName : undefined,
        categoryName:    !isProduct ? form.categoryName : undefined,
        categorySlug:    form.categorySlug || undefined,
        unit:            isProduct ? form.unit : undefined,
        businessTypeName: form.businessTypeName || undefined,
      })
      onRefetch()
      onClose()
    } finally {
      setActing(null)
    }
  }

  return (
    <>
      {/* Backdrop */}
      <div
        className="fixed inset-0 bg-black/30 z-40"
        onClick={onClose}
      />

      {/* Drawer */}
      <div className="fixed right-0 top-0 h-full w-[480px] max-w-full z-50 flex flex-col bg-[var(--canvas)] shadow-2xl overflow-hidden">

        {/* Header */}
        <div className="flex items-center justify-between border-b border-[var(--line)] px-6 py-4">
          <div className="flex items-center gap-2">
            {submission.type === 'category'
              ? <FolderOpen className="h-4 w-4 text-[var(--ink-muted)]" />
              : <Package className="h-4 w-4 text-[var(--ink-muted)]" />
            }
            <span className="font-semibold text-[var(--ink)] text-[15px]">
              {submission.type === 'category' ? 'Category Submission' : 'Product Submission'}
            </span>
          </div>
          <button onClick={onClose} className="rounded p-1 hover:bg-[var(--surface-hover)] transition-colors">
            <X className="h-4 w-4 text-[var(--ink-muted)]" />
          </button>
        </div>

        <div className="flex-1 overflow-y-auto px-6 py-5 space-y-5">

          {/* Metadata */}
          <div className="rounded-lg border border-[var(--line)] bg-[var(--surface)] px-4 py-3 space-y-2">
            <div className="flex items-center justify-between">
              <StatusBadge status={submission.status} />
              <span className="text-[11px] text-[var(--ink-faint)]">
                {submission.submissionCount} submission{submission.submissionCount !== 1 ? 's' : ''}
              </span>
            </div>
            <div className="grid grid-cols-2 gap-x-4 gap-y-1 text-[11px]">
              <div className="text-[var(--ink-muted)]">Business type</div>
              <div className="text-[var(--ink)] font-medium">{submission.businessTypeName || submission.businessType}</div>
              <div className="text-[var(--ink-muted)]">First seen</div>
              <div className="text-[var(--ink)]">{formatDate(submission.firstSeenAt)}</div>
              <div className="text-[var(--ink-muted)]">Last seen</div>
              <div className="text-[var(--ink)]">{formatDate(submission.lastSeenAt)}</div>
              {submission.submittedByUid && (
                <>
                  <div className="text-[var(--ink-muted)]">UID</div>
                  <div className="font-mono text-[10px] text-[var(--ink-faint)] truncate">{submission.submittedByUid}</div>
                </>
              )}
              {submission.masterDocId && (
                <>
                  <div className="text-[var(--ink-muted)]">Master doc</div>
                  <div className="font-mono text-[10px] text-blue-600 truncate">{submission.masterDocId}</div>
                </>
              )}
            </div>
          </div>

          {/* Editable fields */}
          <div className="space-y-3">
            <p className="text-[11px] font-semibold text-[var(--ink-muted)] uppercase tracking-wide">
              Catalog fields — edit before pushing
            </p>

            {isProduct ? (
              <>
                <label className="block space-y-1">
                  <span className="text-[12px] text-[var(--ink-muted)]">Product name (EN)</span>
                  <input
                    disabled={isPushed}
                    value={form.productName}
                    onChange={(e) => setForm((f) => ({ ...f, productName: e.target.value }))}
                    className="w-full rounded-md border border-[var(--line)] bg-[var(--canvas)] px-3 py-1.5 text-[13px] text-[var(--ink)] focus:outline-none focus:ring-1 focus:ring-[var(--brand)] disabled:opacity-50"
                  />
                </label>
                <div className="grid grid-cols-2 gap-3">
                  <label className="block space-y-1">
                    <span className="text-[12px] text-[var(--ink-muted)]">Unit</span>
                    <input
                      disabled={isPushed}
                      value={form.unit}
                      onChange={(e) => setForm((f) => ({ ...f, unit: e.target.value }))}
                      className="w-full rounded-md border border-[var(--line)] bg-[var(--canvas)] px-3 py-1.5 text-[13px] text-[var(--ink)] focus:outline-none focus:ring-1 focus:ring-[var(--brand)] disabled:opacity-50"
                    />
                  </label>
                  <label className="block space-y-1">
                    <span className="text-[12px] text-[var(--ink-muted)]">Category slug</span>
                    <input
                      disabled={isPushed}
                      value={form.categorySlug}
                      onChange={(e) => setForm((f) => ({ ...f, categorySlug: e.target.value }))}
                      placeholder="e.g. beverages"
                      className="w-full rounded-md border border-[var(--line)] bg-[var(--canvas)] px-3 py-1.5 text-[13px] font-mono text-[var(--ink)] focus:outline-none focus:ring-1 focus:ring-[var(--brand)] disabled:opacity-50"
                    />
                  </label>
                </div>
              </>
            ) : (
              <>
                <label className="block space-y-1">
                  <span className="text-[12px] text-[var(--ink-muted)]">Category name (EN)</span>
                  <input
                    disabled={isPushed}
                    value={form.categoryName}
                    onChange={(e) => setForm((f) => ({ ...f, categoryName: e.target.value }))}
                    className="w-full rounded-md border border-[var(--line)] bg-[var(--canvas)] px-3 py-1.5 text-[13px] text-[var(--ink)] focus:outline-none focus:ring-1 focus:ring-[var(--brand)] disabled:opacity-50"
                  />
                </label>
                <label className="block space-y-1">
                  <span className="text-[12px] text-[var(--ink-muted)]">Category slug</span>
                  <input
                    disabled={isPushed}
                    value={form.categorySlug}
                    onChange={(e) => setForm((f) => ({ ...f, categorySlug: e.target.value }))}
                    placeholder="auto-generated if blank"
                    className="w-full rounded-md border border-[var(--line)] bg-[var(--canvas)] px-3 py-1.5 text-[13px] font-mono text-[var(--ink)] focus:outline-none focus:ring-1 focus:ring-[var(--brand)] disabled:opacity-50"
                  />
                </label>
              </>
            )}

            <label className="block space-y-1">
              <span className="text-[12px] text-[var(--ink-muted)]">Catalog business type name</span>
              <input
                disabled={isPushed}
                value={form.businessTypeName}
                onChange={(e) => setForm((f) => ({ ...f, businessTypeName: e.target.value }))}
                placeholder="e.g. Retail, Pharmacy & Healthcare"
                className="w-full rounded-md border border-[var(--line)] bg-[var(--canvas)] px-3 py-1.5 text-[13px] text-[var(--ink)] focus:outline-none focus:ring-1 focus:ring-[var(--brand)] disabled:opacity-50"
              />
            </label>

            {submission.description && (
              <div className="rounded-md border border-[var(--line)] bg-[var(--surface)] px-3 py-2">
                <p className="text-[11px] text-[var(--ink-muted)] mb-1">Description from user</p>
                <p className="text-[12px] text-[var(--ink)]">{submission.description}</p>
              </div>
            )}

            <label className="block space-y-1">
              <span className="text-[12px] text-[var(--ink-muted)]">Admin notes</span>
              <textarea
                rows={2}
                value={form.adminNotes}
                onChange={(e) => setForm((f) => ({ ...f, adminNotes: e.target.value }))}
                placeholder="Internal notes (not shown to users)"
                className="w-full rounded-md border border-[var(--line)] bg-[var(--canvas)] px-3 py-1.5 text-[13px] text-[var(--ink)] focus:outline-none focus:ring-1 focus:ring-[var(--brand)] resize-none"
              />
            </label>
          </div>
        </div>

        {/* Footer actions */}
        <div className="border-t border-[var(--line)] px-6 py-4 space-y-2">
          {isPushed ? (
            <p className="text-center text-[12px] text-[var(--ink-muted)]">
              Already pushed to <span className="font-medium text-blue-600">{submission.masterDocId}</span>
            </p>
          ) : (
            <>
              <button
                disabled={!!acting}
                onClick={() => handleAction('push')}
                className="w-full inline-flex items-center justify-center gap-2 rounded-lg bg-[var(--brand)] px-4 py-2.5 text-[13px] font-semibold text-white hover:opacity-90 disabled:opacity-40 transition-opacity"
              >
                <Upload className="h-4 w-4" />
                {acting === 'push' ? 'Pushing…' : `Push to master ${isProduct ? 'products' : 'categories'}`}
              </button>
              {isPending && (
                <div className="flex gap-2">
                  <button
                    disabled={!!acting}
                    onClick={() => handleAction('approve')}
                    className="flex-1 inline-flex items-center justify-center gap-1 rounded-lg border border-green-300 bg-green-50 px-3 py-2 text-[12px] font-medium text-green-700 hover:opacity-80 disabled:opacity-40 transition-opacity"
                  >
                    <Check className="h-3.5 w-3.5" />
                    {acting === 'approve' ? '…' : 'Approve only'}
                  </button>
                  <button
                    disabled={!!acting}
                    onClick={() => handleAction('reject')}
                    className="flex-1 inline-flex items-center justify-center gap-1 rounded-lg border border-red-200 bg-red-50 px-3 py-2 text-[12px] font-medium text-red-600 hover:opacity-80 disabled:opacity-40 transition-opacity"
                  >
                    <X className="h-3.5 w-3.5" />
                    {acting === 'reject' ? '…' : 'Reject'}
                  </button>
                </div>
              )}
            </>
          )}
        </div>
      </div>
    </>
  )
}

// ─── Page ─────────────────────────────────────────────────────────────────────

export default function SubmissionsPage() {
  const [statusFilter, setStatusFilter] = useState<string>('pending')
  const [selected, setSelected] = useState<CommunitySubmission | null>(null)

  const { data, loading, revalidating, error, refetch } = useAdminFetch(
    useCallback(() => fetchSubmissions(statusFilter), [statusFilter]),
    { key: `submissions-${statusFilter}` },
  )

  const submissions = data?.submissions ?? []
  const pending = submissions.filter((s) => s.status === 'pending').length

  const columns: ColumnDef<CommunitySubmission, unknown>[] = [
    {
      id: 'type',
      header: 'Type',
      cell: ({ row }) => row.original.type === 'category'
        ? <span className="inline-flex items-center gap-1 text-[11px] text-purple-600"><FolderOpen className="h-3 w-3" />Category</span>
        : <span className="inline-flex items-center gap-1 text-[11px] text-blue-600"><Tag className="h-3 w-3" />Product</span>,
    },
    {
      accessorKey: 'productName',
      header: 'Name',
      cell: ({ row }) => (
        <span className="font-medium text-[var(--ink)]">
          {row.original.type === 'category' ? (row.original.categoryName || row.original.productName) : row.original.productName}
        </span>
      ),
    },
    {
      accessorKey: 'businessTypeName',
      header: 'Business Type',
      cell: ({ row }) => (
        <span className="rounded bg-[var(--surface)] px-2 py-0.5 text-[11px] text-[var(--ink-muted)]">
          {row.original.businessTypeName || row.original.businessType}
        </span>
      ),
    },
    {
      accessorKey: 'submissionCount',
      header: 'Submissions',
      cell: ({ row }) => (
        <span className="font-mono font-semibold text-[var(--ink)]">{row.original.submissionCount}</span>
      ),
    },
    {
      accessorKey: 'firstSeenAt',
      header: 'First Seen',
      cell: ({ row }) => <span className="text-[var(--ink-muted)] text-[12px]">{formatDate(row.original.firstSeenAt)}</span>,
    },
    {
      id: 'status',
      header: 'Status',
      cell: ({ row }) => <StatusBadge status={row.original.status} />,
    },
    {
      id: 'open',
      header: '',
      cell: ({ row }) => (
        <button
          onClick={() => setSelected(row.original)}
          className="inline-flex items-center gap-1 text-[11px] text-[var(--brand)] hover:underline"
        >
          Review <ChevronRight className="h-3 w-3" />
        </button>
      ),
    },
  ]

  return (
    <div>
      <PageHeader
        title="Community Submissions"
        description={loading ? 'Loading…' : `${pending} pending · ${submissions.length} total shown`}
      />
      {revalidating && <RevalidatingBar />}

      {/* Filter tabs */}
      <div className="mb-4 flex gap-1 border-b border-[var(--line)]">
        {(['pending', 'approved', 'rejected', 'pushed'] as const).map((s) => (
          <button
            key={s}
            onClick={() => setStatusFilter(s)}
            className={`px-4 py-2 text-[12px] font-medium transition-colors border-b-2 -mb-px ${
              statusFilter === s
                ? 'border-[var(--brand)] text-[var(--brand)]'
                : 'border-transparent text-[var(--ink-muted)] hover:text-[var(--ink)]'
            }`}
          >
            {s.charAt(0).toUpperCase() + s.slice(1)}
            {s === 'pending' && pending > 0 && (
              <span className="ml-1.5 rounded-full bg-yellow-100 px-1.5 py-0.5 text-[10px] font-semibold text-yellow-700">
                {pending}
              </span>
            )}
          </button>
        ))}
      </div>

      {loading ? (
        <SkeletonTable rows={5} cols={7} />
      ) : error && !data ? (
        <div className="mt-4 flex items-center gap-3 rounded-lg border border-[var(--status-bad)] bg-[var(--status-bad-bg)] p-4 text-[var(--status-bad)]">
          <AlertCircle className="h-4 w-4 shrink-0" />
          <span className="text-[13px]">{error}</span>
        </div>
      ) : (
        <DataTable
          data={submissions}
          columns={columns}
          searchPlaceholder="Search submissions…"
          exportFilename="catalog-submissions"
          emptyState={
            <div className="text-center py-8">
              <p className="text-[var(--ink-muted)] text-[13px]">No {statusFilter} submissions</p>
              <p className="text-[var(--ink-faint)] text-[12px] mt-1">
                {statusFilter === 'pending'
                  ? 'Products submitted by users via the mobile app will appear here'
                  : `No submissions with status "${statusFilter}"`}
              </p>
            </div>
          }
        />
      )}

      {selected && (
        <DetailDrawer
          submission={selected}
          onClose={() => setSelected(null)}
          onRefetch={refetch}
        />
      )}
    </div>
  )
}
