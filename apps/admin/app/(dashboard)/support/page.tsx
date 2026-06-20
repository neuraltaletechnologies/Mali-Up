'use client'

import { useState, useCallback } from 'react'
import { PageHeader } from '@/components/ui/page-header'
import { StatusDot } from '@/components/ui/status-dot'
import { Skeleton } from '@/components/ui/skeleton'
import { fetchTickets, patchTicket } from '@/lib/admin-api'
import { useAdminFetch } from '@/hooks/use-admin-fetch'
import { timeAgo } from '@/lib/format'
import type { SupportTicket } from '@/types'
import { cn } from '@/lib/utils'
import { AlertCircle } from 'lucide-react'

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

function TicketRow({
  ticket,
  onUpdate,
}: {
  ticket: SupportTicket
  onUpdate: (id: string, update: { status?: SupportTicket['status']; assignedAdmin?: string }) => Promise<void>
}) {
  const [acting, setActing] = useState(false)
  const pConfig = priorityConfig[ticket.priority]

  async function act(update: { status?: SupportTicket['status']; assignedAdmin?: string }) {
    setActing(true)
    try { await onUpdate(ticket.id, update) } finally { setActing(false) }
  }

  return (
    <div className="flex items-start gap-4 px-4 py-3.5 border-b border-[var(--line)] hover:bg-[var(--canvas)] transition-colors">
      <div className="pt-0.5 shrink-0">
        <StatusDot status={pConfig.status} label="" />
      </div>

      <div className="flex-1 min-w-0">
        <div className="flex items-center gap-2 flex-wrap">
          <span className="font-medium text-[var(--ink)] text-[13px]">{ticket.businessName}</span>
          <span className="text-[11px] text-[var(--ink-faint)] bg-[var(--canvas)] border border-[var(--line)] rounded px-1.5 py-0.5">
            {ticket.issueType}
          </span>
        </div>
        <div className="text-[12px] text-[var(--ink-muted)] mt-0.5">
          {ticket.ownerName} · {statusLabel[ticket.status]}
          {ticket.assignedAdmin && ` · Assigned to ${ticket.assignedAdmin}`}
        </div>

        {/* Quick actions */}
        {ticket.status !== 'resolved' && ticket.status !== 'closed' && (
          <div className="mt-2 flex gap-1.5">
            {ticket.status === 'open' && (
              <button
                disabled={acting}
                onClick={() => act({ status: 'in_progress' })}
                className="rounded px-2 py-0.5 text-[11px] font-medium bg-[var(--accent-soft)] text-[var(--accent)] hover:opacity-80 disabled:opacity-40"
              >
                Mark In Progress
              </button>
            )}
            <button
              disabled={acting}
              onClick={() => act({ status: 'resolved' })}
              className="rounded px-2 py-0.5 text-[11px] font-medium bg-[var(--status-good-bg)] text-[var(--status-good)] hover:opacity-80 disabled:opacity-40"
            >
              Resolve
            </button>
          </div>
        )}
      </div>

      <div className="shrink-0 text-right">
        <div className="text-[11px] text-[var(--ink-faint)]">{timeAgo(ticket.createdAt)}</div>
        <div className="text-[10px] text-[var(--ink-faint)] mt-0.5">{pConfig.label}</div>
      </div>
    </div>
  )
}

export default function SupportPage() {
  const [filter, setFilter] = useState<'all' | 'open' | 'in_progress' | 'resolved'>('all')

  const { data, loading, error, refetch } = useAdminFetch(useCallback(() => fetchTickets(), []))

  const tickets = data?.tickets ?? []

  async function handleUpdate(
    id: string,
    update: { status?: SupportTicket['status']; assignedAdmin?: string },
  ) {
    await patchTicket(id, update)
    refetch()
  }

  if (loading) {
    return (
      <div>
        <PageHeader title="Support" description="Loading…" />
        <div className="space-y-2 mt-6">
          {Array.from({ length: 6 }).map((_, i) => <Skeleton key={i} className="h-16 w-full" />)}
        </div>
      </div>
    )
  }

  if (error) {
    return (
      <div>
        <PageHeader title="Support" description="Failed to load" />
        <div className="mt-8 flex items-center gap-3 rounded-lg border border-[var(--status-bad)] bg-[var(--status-bad-bg)] p-4 text-[var(--status-bad)]">
          <AlertCircle className="h-4 w-4 shrink-0" />
          <span className="text-[13px]">{error}</span>
        </div>
      </div>
    )
  }

  const open       = tickets.filter((t) => t.status === 'open').length
  const inProgress = tickets.filter((t) => t.status === 'in_progress').length
  const filtered   = filter === 'all' ? tickets : tickets.filter((t) => t.status === filter)

  return (
    <div>
      <PageHeader
        title="Support"
        description={`${open} open ticket${open !== 1 ? 's' : ''} · ${inProgress} in progress`}
      />

      <div className="flex gap-0 border-b border-[var(--line)] mb-4">
        {[
          { value: 'all',         label: 'All',         count: tickets.length },
          { value: 'open',        label: 'Open',        count: open },
          { value: 'in_progress', label: 'In Progress', count: inProgress },
          { value: 'resolved',    label: 'Resolved',    count: tickets.filter((t) => t.status === 'resolved').length },
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
          <div className="text-center py-12 text-[var(--ink-faint)] text-[13px]">
            {tickets.length === 0 ? 'No support tickets yet.' : 'No tickets in this category.'}
          </div>
        ) : (
          filtered
            .sort((a, b) => {
              const order = { urgent: 0, normal: 1, low: 2 }
              return order[a.priority] - order[b.priority]
            })
            .map((ticket) => (
              <TicketRow key={ticket.id} ticket={ticket} onUpdate={handleUpdate} />
            ))
        )}
      </div>
    </div>
  )
}
