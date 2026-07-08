'use client'

import { useState, useCallback } from 'react'
import Link from 'next/link'
import { PageHeader } from '@/components/ui/page-header'
import { Tabs } from '@/components/ui/tabs'
import { DataTable } from '@/components/ui/data-table'
import { StatusDot } from '@/components/ui/status-dot'
import { SkeletonTable, RevalidatingBar } from '@/components/ui/skeleton'
import { PlanBadge } from '@/components/ui/plan-badge'
import { fetchPlanRequests, patchPlanRequest, assignPlan, fetchRefunds, patchRefund } from '@/lib/admin-api'
import { useAdminFetch } from '@/hooks/use-admin-fetch'
import type { PlanRequest, RefundRequest } from '@/types'
import type { ColumnDef } from '@tanstack/react-table'
import { formatDate, formatTZS, calculateRefund } from '@/lib/format'
import { cn } from '@/lib/utils'
import {
  Check, X, AlertCircle, ChevronRight, ChevronDown, ChevronUp, Building2, Phone,
  Briefcase, Receipt, Rocket, DollarSign,
} from 'lucide-react'

function initialTab(): 'requests' | 'refunds' {
  if (typeof window === 'undefined') return 'requests'
  return new URLSearchParams(window.location.search).get('tab') === 'refunds' ? 'refunds' : 'requests'
}

// ─── Plan Requests tab ────────────────────────────────────────────────────────

function StatusBadge({ status }: { status: PlanRequest['status'] }) {
  const cfg: Record<string, string> = {
    pending:  'bg-yellow-50 text-yellow-700 border-yellow-200',
    approved: 'bg-green-50 text-green-700 border-green-200',
    rejected: 'bg-red-50 text-red-600 border-red-200',
  }
  const label: Record<string, string> = {
    pending:  'Pending',
    approved: 'Approved',
    rejected: 'Rejected',
  }
  return (
    <span className={`inline-flex items-center rounded-full border px-2 py-0.5 text-[10px] font-semibold ${cfg[status] ?? cfg.pending}`}>
      {label[status] ?? status}
    </span>
  )
}

function TypeBadge({ type }: { type: PlanRequest['type'] }) {
  return type === 'enterprise_inquiry' ? (
    <span className="inline-flex items-center gap-1 text-[11px] text-purple-600">
      <Briefcase className="h-3 w-3" />Enterprise
    </span>
  ) : (
    <span className="inline-flex items-center gap-1 text-[11px] text-blue-600">
      <Receipt className="h-3 w-3" />Payment
    </span>
  )
}

function RequestDetailDrawer({
  request,
  onClose,
  onRefetch,
}: {
  request: PlanRequest
  onClose: () => void
  onRefetch: () => void
}) {
  const [adminNotes, setAdminNotes] = useState(request.adminNotes)
  const [cycleMonths, setCycleMonths] = useState(6)
  const [acting, setActing] = useState<string | null>(null)
  const [error, setError] = useState<string | null>(null)

  const isPending = request.status === 'pending'
  const isRejected = request.status === 'rejected'
  const isApproved = request.status === 'approved'
  const canActivate = Boolean(request.uid && request.businessId)

  async function handle(action: 'approve' | 'reject', activate: boolean) {
    setActing(activate ? 'activate' : action)
    setError(null)
    try {
      if (activate) {
        await assignPlan(request.uid, request.businessId, request.requestedTier, cycleMonths)
      }
      await patchPlanRequest(request.id, action, adminNotes, activate)
      onRefetch()
      onClose()
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Action failed')
    } finally {
      setActing(null)
    }
  }

  return (
    <>
      {/* Backdrop */}
      <div className="fixed inset-0 bg-black/30 z-40" onClick={onClose} />

      {/* Drawer */}
      <div className="fixed right-0 top-0 h-full w-[480px] max-w-full z-50 flex flex-col bg-[var(--canvas)] shadow-2xl overflow-hidden">

        {/* Header */}
        <div className="flex items-center justify-between border-b border-[var(--line)] px-6 py-4">
          <div className="flex items-center gap-2">
            {request.type === 'enterprise_inquiry'
              ? <Briefcase className="h-4 w-4 text-[var(--ink-muted)]" />
              : <Receipt className="h-4 w-4 text-[var(--ink-muted)]" />
            }
            <span className="font-semibold text-[var(--ink)] text-[15px]">
              {request.type === 'enterprise_inquiry' ? 'Enterprise Inquiry' : 'Payment Confirmation'}
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
              <StatusBadge status={request.status} />
              <PlanBadge tier={request.requestedTier} />
            </div>
            <div className="grid grid-cols-2 gap-x-4 gap-y-1 text-[11px]">
              <div className="text-[var(--ink-muted)]">Requester</div>
              <div className="text-[var(--ink)] font-medium">{request.name || '—'}</div>
              <div className="text-[var(--ink-muted)]">Phone</div>
              <div className="text-[var(--ink)] flex items-center gap-1">
                <Phone className="h-3 w-3 text-[var(--ink-faint)]" />
                {request.phone || '—'}
              </div>
              <div className="text-[var(--ink-muted)]">Business</div>
              <div className="text-[var(--ink)] flex items-center gap-1">
                <Building2 className="h-3 w-3 text-[var(--ink-faint)]" />
                {request.businessName || '—'}
              </div>
              <div className="text-[var(--ink-muted)]">Submitted</div>
              <div className="text-[var(--ink)]">{request.createdAt ? formatDate(request.createdAt) : '—'}</div>
              {request.resolvedAt && (
                <>
                  <div className="text-[var(--ink-muted)]">Resolved</div>
                  <div className="text-[var(--ink)]">{formatDate(request.resolvedAt)}</div>
                </>
              )}
              {request.paymentRef && (
                <>
                  <div className="text-[var(--ink-muted)]">Payment ref</div>
                  <div className="font-mono text-[10px] text-blue-600">{request.paymentRef}</div>
                </>
              )}
              <div className="text-[var(--ink-muted)]">UID</div>
              <div className="font-mono text-[10px] text-[var(--ink-faint)] truncate">
                {request.uid ? (
                  <Link href={`/admin/users/${request.uid}`} className="hover:underline text-blue-600">
                    {request.uid}
                  </Link>
                ) : '—'}
              </div>
            </div>
          </div>

          {/* User note */}
          {request.note && (
            <div className="rounded-md border border-[var(--line)] bg-[var(--surface)] px-3 py-2">
              <p className="text-[11px] text-[var(--ink-muted)] mb-1">Message from user</p>
              <p className="text-[12px] text-[var(--ink)] whitespace-pre-wrap">{request.note}</p>
            </div>
          )}

          {/* Activation settings */}
          {!isRejected && !(isApproved && request.activated) && (
            <div className="space-y-3">
              <p className="text-[11px] font-semibold text-[var(--ink-muted)] uppercase tracking-wide">
                Activation
              </p>
              <label className="block space-y-1">
                <span className="text-[12px] text-[var(--ink-muted)]">Cycle length</span>
                <select
                  value={cycleMonths}
                  onChange={(e) => setCycleMonths(Number(e.target.value))}
                  className="w-full rounded-md border border-[var(--line)] bg-[var(--canvas)] px-3 py-1.5 text-[13px] text-[var(--ink)] focus:outline-none focus:ring-1 focus:ring-[var(--brand)]"
                >
                  <option value={1}>1 month</option>
                  <option value={3}>3 months</option>
                  <option value={6}>6 months</option>
                  <option value={12}>12 months</option>
                </select>
              </label>
              {!canActivate && (
                <p className="text-[11px] text-[var(--status-bad)]">
                  Missing uid or businessId on this request — activate manually from the user page.
                </p>
              )}
            </div>
          )}

          <label className="block space-y-1">
            <span className="text-[12px] text-[var(--ink-muted)]">Admin notes</span>
            <textarea
              rows={2}
              value={adminNotes}
              onChange={(e) => setAdminNotes(e.target.value)}
              placeholder="Internal notes (not shown to users)"
              className="w-full rounded-md border border-[var(--line)] bg-[var(--canvas)] px-3 py-1.5 text-[13px] text-[var(--ink)] focus:outline-none focus:ring-1 focus:ring-[var(--brand)] resize-none"
            />
          </label>

          {error && (
            <div className="flex items-center gap-2 rounded-lg border border-[var(--status-bad)] bg-[var(--status-bad-bg)] p-3 text-[var(--status-bad)]">
              <AlertCircle className="h-4 w-4 shrink-0" />
              <span className="text-[12px]">{error}</span>
            </div>
          )}
        </div>

        {/* Footer actions */}
        <div className="border-t border-[var(--line)] px-6 py-4 space-y-2">
          {isRejected ? (
            <p className="text-center text-[12px] text-[var(--ink-muted)]">
              This request has been rejected.
            </p>
          ) : isApproved && request.activated ? (
            <p className="text-center text-[12px] text-[var(--ink-muted)]">
              Approved and activated.
            </p>
          ) : (
            <>
              {isApproved && !request.activated && (
                <p className="text-center text-[11px] text-[var(--status-bad)]">
                  Approved, but the plan was never activated for this user.
                </p>
              )}
              <button
                disabled={!!acting || !canActivate}
                onClick={() => handle('approve', true)}
                className="w-full inline-flex items-center justify-center gap-2 rounded-lg bg-[var(--brand)] px-4 py-2.5 text-[13px] font-semibold text-white hover:opacity-90 disabled:opacity-40 transition-opacity"
              >
                <Rocket className="h-4 w-4" />
                {acting === 'activate'
                  ? 'Activating…'
                  : isApproved
                    ? `Activate ${request.requestedTier}`
                    : `Activate ${request.requestedTier} & approve`}
              </button>
              {isPending && (
                <div className="flex gap-2">
                  <button
                    disabled={!!acting}
                    onClick={() => handle('approve', false)}
                    className="flex-1 inline-flex items-center justify-center gap-1 rounded-lg border border-green-300 bg-green-50 px-3 py-2 text-[12px] font-medium text-green-700 hover:opacity-80 disabled:opacity-40 transition-opacity"
                  >
                    <Check className="h-3.5 w-3.5" />
                    {acting === 'approve' ? '…' : 'Approve only'}
                  </button>
                  <button
                    disabled={!!acting}
                    onClick={() => handle('reject', false)}
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

function RequestsTab() {
  const [statusFilter, setStatusFilter] = useState<string>('pending')
  const [selected, setSelected] = useState<PlanRequest | null>(null)

  const { data, loading, revalidating, error, refetch } = useAdminFetch(
    useCallback(() => fetchPlanRequests(statusFilter), [statusFilter]),
    { key: `plan-requests-${statusFilter}` },
  )

  const requests = data?.requests ?? []
  const pending = requests.filter((r) => r.status === 'pending').length

  const columns: ColumnDef<PlanRequest, unknown>[] = [
    {
      id: 'type',
      header: 'Type',
      cell: ({ row }) => <TypeBadge type={row.original.type} />,
    },
    {
      accessorKey: 'name',
      header: 'Requester',
      cell: ({ row }) => (
        <div>
          <div className="font-medium text-[var(--ink)]">{row.original.name || '—'}</div>
          <div className="text-[11px] text-[var(--ink-muted)]">{row.original.phone}</div>
        </div>
      ),
    },
    {
      accessorKey: 'businessName',
      header: 'Business',
      cell: ({ row }) => (
        <span className="text-[12px] text-[var(--ink-muted)]">{row.original.businessName || '—'}</span>
      ),
    },
    {
      accessorKey: 'requestedTier',
      header: 'Plan',
      cell: ({ row }) => <PlanBadge tier={row.original.requestedTier} />,
    },
    {
      accessorKey: 'paymentRef',
      header: 'Payment Ref',
      cell: ({ row }) => row.original.paymentRef
        ? <span className="font-mono text-[10px] text-blue-600">{row.original.paymentRef}</span>
        : <span className="text-[var(--ink-faint)]">—</span>,
    },
    {
      accessorKey: 'createdAt',
      header: 'Submitted',
      cell: ({ row }) => (
        <span className="text-[var(--ink-muted)] text-[12px]">
          {row.original.createdAt ? formatDate(row.original.createdAt) : '—'}
        </span>
      ),
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
    <>
      {revalidating && <RevalidatingBar />}

      {/* Filter tabs */}
      <div className="mb-4 flex gap-1 border-b border-[var(--line)]">
        {(['pending', 'approved', 'rejected'] as const).map((s) => (
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
        <SkeletonTable rows={5} cols={8} />
      ) : error && !data ? (
        <div className="mt-4 flex items-center gap-3 rounded-lg border border-[var(--status-bad)] bg-[var(--status-bad-bg)] p-4 text-[var(--status-bad)]">
          <AlertCircle className="h-4 w-4 shrink-0" />
          <span className="text-[13px]">{error}</span>
        </div>
      ) : (
        <DataTable
          data={requests}
          columns={columns}
          searchPlaceholder="Search plan requests…"
          exportFilename="plan-requests"
          emptyState={
            <div className="text-center py-8">
              <p className="text-[var(--ink-muted)] text-[13px]">No {statusFilter} requests</p>
              <p className="text-[var(--ink-faint)] text-[12px] mt-1">
                {statusFilter === 'pending'
                  ? 'Enterprise inquiries and payment confirmations from the mobile app will appear here'
                  : `No requests with status "${statusFilter}"`}
              </p>
            </div>
          }
        />
      )}

      {selected && (
        <RequestDetailDrawer
          request={selected}
          onClose={() => setSelected(null)}
          onRefetch={refetch}
        />
      )}
    </>
  )
}

// ─── Refunds tab ──────────────────────────────────────────────────────────────

const REFUND_COLUMNS: RefundRequest['status'][][] = [['requested'], ['processing'], ['completed']]
const REFUND_COLUMN_LABELS = ['Requested', 'Processing (UTT AMIS)', 'Completed']

function RefundCalculatorModal({
  refund,
  onClose,
  onAction,
}: {
  refund: RefundRequest
  onClose: () => void
  onAction: (action: 'processing' | 'completed') => Promise<void>
}) {
  const [acting, setActing] = useState(false)
  const breakdown = calculateRefund(refund.principal, refund.monthlyFee, refund.monthsHeld, refund.tier)

  const nextStatus: 'processing' | 'completed' | null =
    refund.status === 'requested'  ? 'processing' :
    refund.status === 'processing' ? 'completed'  :
    null

  const actionLabel =
    refund.status === 'requested'  ? 'Initiate UTT AMIS Withdrawal' :
    refund.status === 'processing' ? 'Mark Refund Sent' :
    'View Only'

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center">
      <div className="absolute inset-0 bg-black/30" onClick={onClose} />
      <div className="relative z-10 w-full max-w-md rounded-xl border border-[var(--line)] bg-[var(--surface)] p-6 shadow-2xl">
        <h2 className="text-[15px] font-semibold text-[var(--ink)] mb-4">Refund Calculation</h2>
        <div className="text-[13px] font-medium text-[var(--ink-muted)] mb-1">{refund.businessName}</div>
        <div className="text-[12px] text-[var(--ink-faint)] mb-5">{refund.monthsHeld} months held · {refund.tier} tier</div>

        <div className="rounded-lg border border-[var(--line)] overflow-hidden mb-5">
          {[
            { label: 'Original Principal', value: refund.principal, color: '' },
            { label: `Fees Used (${refund.monthsHeld} × ${formatTZS(refund.monthlyFee)})`, value: -breakdown.feesUsed, color: 'text-[var(--status-bad)]' },
            { label: 'Cancellation Fee', value: -breakdown.cancellationFee, color: 'text-[var(--status-bad)]' },
          ].map(({ label, value, color }) => (
            <div key={label} className="flex items-center justify-between px-4 py-2.5 border-b border-[var(--line)] last:border-0">
              <span className="text-[13px] text-[var(--ink-muted)]">{label}</span>
              <span className={cn('font-mono text-[13px]', color || 'text-[var(--ink)]')}>
                {value < 0 ? `−${formatTZS(Math.abs(value))}` : formatTZS(value)}
              </span>
            </div>
          ))}
          <div className="flex items-center justify-between px-4 py-3 bg-[var(--canvas)]">
            <span className="text-[14px] font-semibold text-[var(--ink)]">Final Refund Amount</span>
            <span className="font-mono text-[16px] font-bold text-[var(--ink)]">{formatTZS(breakdown.refundAmount)}</span>
          </div>
        </div>

        <div className="flex items-center justify-end gap-2">
          <button
            onClick={onClose}
            disabled={acting}
            className="rounded-md border border-[var(--line)] px-3 py-1.5 text-[12px] font-medium text-[var(--ink-muted)] hover:text-[var(--ink)] transition-colors"
          >
            Cancel
          </button>
          {nextStatus && (
            <button
              onClick={async () => {
                setActing(true)
                try { await onAction(nextStatus) } finally { setActing(false) }
                onClose()
              }}
              disabled={acting}
              className="rounded-md bg-[var(--navy)] px-4 py-1.5 text-[12px] font-medium text-white hover:bg-[var(--navy-soft)] transition-colors disabled:opacity-50"
            >
              {acting ? 'Saving…' : actionLabel}
            </button>
          )}
        </div>
      </div>
    </div>
  )
}

function RefundCard({
  refund,
  onStatusChange,
}: {
  refund: RefundRequest
  onStatusChange: (id: string, status: 'processing' | 'completed') => Promise<void>
}) {
  const [expanded, setExpanded] = useState(false)
  const [showCalc, setShowCalc] = useState(false)
  const breakdown = calculateRefund(refund.principal, refund.monthlyFee, refund.monthsHeld, refund.tier)

  return (
    <>
      <div className="rounded-lg border border-[var(--line)] bg-[var(--surface)] p-4">
        <div className="flex items-start justify-between gap-3">
          <div>
            <div className="font-medium text-[var(--ink)] text-[13px]">{refund.businessName}</div>
            <div className="text-[11px] text-[var(--ink-muted)] mt-0.5">
              {refund.tier} · {refund.monthsHeld} months held
            </div>
          </div>
          <StatusDot
            status={refund.status === 'completed' ? 'neutral' : refund.status === 'processing' ? 'warn' : 'bad'}
            label={refund.status.charAt(0).toUpperCase() + refund.status.replace(/_/g, ' ').slice(1)}
          />
        </div>

        <div className="mt-3 flex items-center justify-between">
          <div>
            <div className="text-[11px] text-[var(--ink-faint)]">Principal</div>
            <div className="font-mono text-[13px] font-semibold text-[var(--ink)]">{formatTZS(refund.principal)}</div>
          </div>
          <div className="text-right">
            <div className="text-[11px] text-[var(--ink-faint)]">Refund Amount</div>
            <div className="font-mono text-[13px] font-semibold text-[var(--status-good)]">{formatTZS(breakdown.refundAmount)}</div>
          </div>
        </div>

        <div className="mt-3 flex items-center gap-2">
          <button
            onClick={() => setShowCalc(true)}
            className="flex items-center gap-1 text-[11px] text-[var(--accent)] hover:underline"
          >
            <DollarSign className="h-3 w-3" />
            {refund.status !== 'completed' ? 'View & action' : 'View calculation'}
          </button>
          <button
            onClick={() => setExpanded(!expanded)}
            className="ml-auto flex items-center gap-0.5 text-[11px] text-[var(--ink-faint)] hover:text-[var(--ink-muted)]"
          >
            {expanded ? <ChevronUp className="h-3 w-3" /> : <ChevronDown className="h-3 w-3" />}
            {expanded ? 'Less' : 'More'}
          </button>
        </div>

        {expanded && (
          <div className="mt-3 pt-3 border-t border-[var(--line)] text-[11px] text-[var(--ink-muted)] space-y-1">
            <div>Requested: {formatDate(refund.requestedAt)}</div>
            {refund.processedAt && <div>Processing started: {formatDate(refund.processedAt)}</div>}
            {refund.completedAt && <div>Completed: {formatDate(refund.completedAt)}</div>}
          </div>
        )}
      </div>

      {showCalc && (
        <RefundCalculatorModal
          refund={refund}
          onClose={() => setShowCalc(false)}
          onAction={(status) => onStatusChange(refund.id, status)}
        />
      )}
    </>
  )
}

function RefundsTab() {
  const { data, loading, revalidating, error, refetch } = useAdminFetch(
    useCallback(() => fetchRefunds(), []),
    { key: 'refunds' },
  )

  async function handleStatusChange(id: string, status: 'processing' | 'completed') {
    await patchRefund(id, status)
    refetch()
  }

  const refunds = data?.refunds ?? []

  if (loading) return <SkeletonTable rows={6} cols={5} />
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
      <div className="grid grid-cols-3 gap-4">
        {REFUND_COLUMN_LABELS.map((label, ci) => {
          const statuses = REFUND_COLUMNS[ci]
          const cards = refunds.filter((r) => statuses.includes(r.status))
          return (
            <div key={label}>
              <div className="flex items-center justify-between mb-3">
                <h2 className="text-[13px] font-semibold text-[var(--ink)]">{label}</h2>
                <span className="text-[11px] font-mono text-[var(--ink-faint)]">{cards.length}</span>
              </div>
              <div className="flex flex-col gap-3 min-h-[120px] rounded-lg border border-[var(--line)] bg-[var(--canvas)] p-3">
                {cards.length === 0 ? (
                  <div className="text-center py-6 text-[12px] text-[var(--ink-faint)]">No refunds here</div>
                ) : (
                  cards.map((r) => (
                    <RefundCard key={r.id} refund={r} onStatusChange={handleStatusChange} />
                  ))
                )}
              </div>
            </div>
          )
        })}
      </div>
    </>
  )
}

// ─── Page ─────────────────────────────────────────────────────────────────────

export default function RequestsPage() {
  const [tab, setTab] = useState<'requests' | 'refunds'>(initialTab)

  return (
    <div>
      <PageHeader
        title="Requests"
        description={tab === 'requests' ? 'Enterprise inquiries and payment confirmations' : 'Lifetime subscription refund queue'}
      />

      <Tabs
        tabs={[
          { id: 'requests', label: 'Plan Requests' },
          { id: 'refunds', label: 'Refunds' },
        ]}
        active={tab}
        onChange={(id) => setTab(id as 'requests' | 'refunds')}
        className="mb-6"
      />

      {tab === 'requests' ? <RequestsTab /> : <RefundsTab />}
    </div>
  )
}
