'use client'

import { useState } from 'react'
import { PageHeader } from '@/components/ui/page-header'
import { StatusDot } from '@/components/ui/status-dot'
import { ConfirmDialog } from '@/components/ui/confirm-dialog'
import { mockRefunds } from '@/lib/mock-data'
import { formatTZS, formatDate, calculateRefund } from '@/lib/format'
import type { RefundRequest } from '@/types'
import { ChevronDown, ChevronUp, DollarSign } from 'lucide-react'
import { cn } from '@/lib/utils'

const COLUMNS: RefundRequest['status'][][] = [
  ['requested'],
  ['processing'],
  ['completed'],
]

const COLUMN_LABELS = ['Requested', 'Processing (UTT AMIS)', 'Completed']

function RefundCalculatorModal({
  refund,
  onClose,
  onAction,
}: {
  refund: RefundRequest
  onClose: () => void
  onAction: (action: string) => void
}) {
  const breakdown = calculateRefund(refund.principal, refund.monthlyFee, refund.monthsHeld, refund.tier)

  const actionLabel =
    refund.status === 'requested' ? 'Initiate UTT AMIS Withdrawal' :
    refund.status === 'processing' ? 'Mark Refund Sent' :
    'Close & Notify User'

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center">
      <div className="absolute inset-0 bg-black/30" onClick={onClose} />
      <div className="relative z-10 w-full max-w-md rounded-xl border border-[var(--line)] bg-[var(--surface)] p-6 shadow-2xl">
        <h2 className="text-[15px] font-semibold text-[var(--ink)] mb-4">Refund Calculation</h2>
        <div className="text-[13px] font-medium text-[var(--ink-muted)] mb-1">{refund.businessName}</div>
        <div className="text-[12px] text-[var(--ink-faint)] mb-5">{refund.monthsHeld} months held · {refund.tier} tier</div>

        <div className="rounded-lg border border-[var(--line)] overflow-hidden mb-5">
          {[
            { label: 'Original Principal', value: refund.principal, bold: false, color: '' },
            { label: `Fees Used (${refund.monthsHeld} × ${formatTZS(refund.monthlyFee)})`, value: -breakdown.feesUsed, bold: false, color: 'text-[var(--status-bad)]' },
            { label: 'Cancellation Fee', value: -breakdown.cancellationFee, bold: false, color: 'text-[var(--status-bad)]' },
          ].map(({ label, value, bold, color }) => (
            <div key={label} className="flex items-center justify-between px-4 py-2.5 border-b border-[var(--line)] last:border-0">
              <span className={cn('text-[13px]', bold ? 'font-semibold text-[var(--ink)]' : 'text-[var(--ink-muted)]')}>{label}</span>
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
            className="rounded-md border border-[var(--line)] px-3 py-1.5 text-[12px] font-medium text-[var(--ink-muted)] hover:text-[var(--ink)] transition-colors"
          >
            Cancel
          </button>
          <button
            onClick={() => { onAction(actionLabel); onClose() }}
            className="rounded-md bg-[var(--navy)] px-4 py-1.5 text-[12px] font-medium text-white hover:bg-[var(--navy-soft)] transition-colors"
          >
            {actionLabel}
          </button>
        </div>
      </div>
    </div>
  )
}

function RefundCard({ refund }: { refund: RefundRequest }) {
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
            View calculation
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
          onAction={(action) => console.log('Action:', action, refund.id)}
        />
      )}
    </>
  )
}

export default function RefundsPage() {
  return (
    <div>
      <PageHeader
        title="Refunds"
        description="Lifetime subscription refund queue"
      />

      <div className="grid grid-cols-3 gap-4">
        {COLUMN_LABELS.map((label, ci) => {
          const statuses = COLUMNS[ci]
          const cards = mockRefunds.filter((r) => statuses.includes(r.status))
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
                  cards.map((r) => <RefundCard key={r.id} refund={r} />)
                )}
              </div>
            </div>
          )
        })}
      </div>
    </div>
  )
}
