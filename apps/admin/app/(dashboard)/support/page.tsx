'use client'

import { useState } from 'react'
import { PageHeader } from '@/components/ui/page-header'
import { StatusDot } from '@/components/ui/status-dot'
import { mockTickets, mockBusinesses } from '@/lib/mock-data'
import { timeAgo, formatDate } from '@/lib/format'
import type { SupportTicket } from '@/types'
import { cn } from '@/lib/utils'
import Link from 'next/link'

const priorityConfig = {
  urgent: { status: 'bad' as const,     label: 'Urgent' },
  normal: { status: 'warn' as const,    label: 'Normal' },
  low:    { status: 'neutral' as const, label: 'Low' },
}

const statusLabel: Record<SupportTicket['status'], string> = {
  open:        'Open',
  in_progress: 'In Progress',
  resolved:    'Resolved',
  closed:      'Closed',
}

function TicketRow({ ticket }: { ticket: SupportTicket }) {
  const pConfig = priorityConfig[ticket.priority]
  const business = mockBusinesses.find((b) => b.id === ticket.businessId)
  const age = timeAgo(ticket.createdAt)

  return (
    <div className="flex items-start gap-4 px-4 py-3.5 border-b border-[var(--line)] hover:bg-[var(--canvas)] transition-colors cursor-pointer">
      <div className="pt-0.5 shrink-0">
        <StatusDot status={pConfig.status} label="" />
      </div>

      <div className="flex-1 min-w-0">
        <div className="flex items-center gap-2">
          <span className="font-medium text-[var(--ink)] text-[13px]">{ticket.businessName}</span>
          <span className="text-[11px] text-[var(--ink-faint)] bg-[var(--canvas)] border border-[var(--line)] rounded px-1.5 py-0.5">
            {ticket.issueType}
          </span>
        </div>
        <div className="text-[12px] text-[var(--ink-muted)] mt-0.5">
          {ticket.ownerName} · {statusLabel[ticket.status]}
          {ticket.assignedAdmin && ` · Assigned to ${ticket.assignedAdmin}`}
        </div>
      </div>

      <div className="shrink-0 text-right">
        <div className="text-[11px] text-[var(--ink-faint)]">{age}</div>
      </div>

      {/* Business context panel hint */}
      {business && (
        <div className="shrink-0 w-44 rounded bg-[var(--canvas)] border border-[var(--line)] px-3 py-2 text-[11px]">
          <div className="font-medium text-[var(--ink)]">{business.name}</div>
          <div className="text-[var(--ink-faint)] mt-0.5">{business.industry} · {business.staffCount} staff</div>
          <Link href={`/businesses/${business.id}`} className="text-[var(--accent)] hover:underline mt-1 block">
            View business →
          </Link>
        </div>
      )}
    </div>
  )
}

export default function SupportPage() {
  const [filter, setFilter] = useState<'all' | 'open' | 'in_progress' | 'resolved'>('all')

  const filtered = filter === 'all' ? mockTickets : mockTickets.filter((t) => t.status === filter)
  const open = mockTickets.filter((t) => t.status === 'open').length
  const inProgress = mockTickets.filter((t) => t.status === 'in_progress').length

  return (
    <div>
      <PageHeader
        title="Support"
        description={`${open} open tickets · ${inProgress} in progress`}
      />

      {/* Filter tabs */}
      <div className="flex gap-0 border-b border-[var(--line)] mb-4">
        {[
          { value: 'all', label: 'All', count: mockTickets.length },
          { value: 'open', label: 'Open', count: open },
          { value: 'in_progress', label: 'In Progress', count: inProgress },
          { value: 'resolved', label: 'Resolved', count: mockTickets.filter(t => t.status === 'resolved').length },
        ].map(({ value, label, count }) => (
          <button
            key={value}
            onClick={() => setFilter(value as typeof filter)}
            className={cn(
              'px-4 py-2.5 text-[13px] font-medium border-b-2 -mb-px transition-colors',
              filter === value
                ? 'border-[var(--accent)] text-[var(--accent)]'
                : 'border-transparent text-[var(--ink-muted)] hover:text-[var(--ink)]'
            )}
          >
            {label}
            <span className={cn(
              'ml-1.5 rounded-full px-1.5 py-0.5 text-[11px]',
              filter === value ? 'bg-[var(--accent-soft)] text-[var(--accent)]' : 'bg-[var(--line)] text-[var(--ink-faint)]'
            )}>
              {count}
            </span>
          </button>
        ))}
      </div>

      <div className="rounded-lg border border-[var(--line)] bg-[var(--surface)] overflow-hidden">
        {filtered.length === 0 ? (
          <div className="text-center py-12 text-[var(--ink-faint)] text-[13px]">No tickets in this category</div>
        ) : (
          filtered
            .sort((a, b) => {
              const order = { urgent: 0, normal: 1, low: 2 }
              return order[a.priority] - order[b.priority]
            })
            .map((ticket) => (
              <TicketRow key={ticket.id} ticket={ticket} />
            ))
        )}
      </div>
    </div>
  )
}
