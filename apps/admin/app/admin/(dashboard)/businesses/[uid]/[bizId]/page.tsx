'use client'

import { useState, useCallback } from 'react'
import { useParams, useRouter } from 'next/navigation'
import { useSession } from 'next-auth/react'
import { PageHeader } from '@/components/ui/page-header'
import { StatusDot } from '@/components/ui/status-dot'
import { PlanBadge } from '@/components/ui/plan-badge'
import { Tabs } from '@/components/ui/tabs'
import { ConfirmDialog } from '@/components/ui/confirm-dialog'
import { KPICard } from '@/components/ui/kpi-card'
import { Skeleton } from '@/components/ui/skeleton'
import { fetchBusiness, patchBusiness, postBusinessNote } from '@/lib/admin-api'
import { useAdminFetch } from '@/hooks/use-admin-fetch'
import { formatTZS, formatDate, timeAgo } from '@/lib/format'
import { ArrowLeft, Ban, RotateCcw, MessageSquarePlus, AlertCircle } from 'lucide-react'

const TABS = [
  { id: 'overview', label: 'Overview' },
  { id: 'subscription', label: 'Subscription' },
  { id: 'staff', label: 'Staff' },
  { id: 'financial', label: 'Financial' },
  { id: 'notes', label: 'Notes' },
]

export default function BusinessDetailPage() {
  const { uid, bizId } = useParams<{ uid: string; bizId: string }>()
  const router = useRouter()
  const { data: session } = useSession()

  const [tab, setTab] = useState('overview')
  const [showSuspend, setShowSuspend] = useState(false)
  const [showUnsuspend, setShowUnsuspend] = useState(false)
  const [actionPending, setActionPending] = useState(false)
  const [noteInput, setNoteInput] = useState('')
  const [savingNote, setSavingNote] = useState(false)

  const { data, loading, error, refetch } = useAdminFetch(
    useCallback(() => fetchBusiness(uid, bizId), [uid, bizId])
  )

  const business = data?.business
  const isSuspended = business?.status === 'suspended'

  async function handleToggleSuspend() {
    if (!business) return
    setActionPending(true)
    try {
      await patchBusiness(uid, bizId, isSuspended)
      refetch()
    } finally {
      setActionPending(false)
      setShowSuspend(false)
      setShowUnsuspend(false)
    }
  }

  async function handleAddNote() {
    if (!noteInput.trim()) return
    setSavingNote(true)
    try {
      await postBusinessNote(uid, bizId, noteInput.trim(), session?.user?.name ?? 'Admin')
      setNoteInput('')
      refetch()
    } finally {
      setSavingNote(false)
    }
  }

  if (loading) {
    return (
      <div>
        <Skeleton className="h-4 w-28 mb-4" />
        <Skeleton className="h-8 w-72 mb-2" />
        <Skeleton className="h-4 w-48 mb-6" />
        <div className="space-y-2">
          {Array.from({ length: 4 }).map((_, i) => <Skeleton key={i} className="h-12 w-full" />)}
        </div>
      </div>
    )
  }

  if (error || !business) {
    return (
      <div className="text-center py-16">
        <div className="inline-flex items-center gap-2 text-[var(--status-bad)] mb-3">
          <AlertCircle className="h-4 w-4" />
          <span className="text-[13px]">{error ?? 'Business not found'}</span>
        </div>
        <br />
        <button onClick={() => router.back()} className="text-[12px] text-[var(--accent)] hover:underline">
          Go back
        </button>
      </div>
    )
  }

  return (
    <div>
      <button
        onClick={() => router.back()}
        className="flex items-center gap-1.5 text-[12px] text-[var(--ink-muted)] hover:text-[var(--ink)] mb-4 transition-colors"
      >
        <ArrowLeft className="h-3.5 w-3.5" />
        Back to businesses
      </button>

      <PageHeader
        title={business.name}
        description={`${business.industry}${business.location ? ` · ${business.location}` : ''}`}
      >
        {isSuspended ? (
          <button
            onClick={() => setShowUnsuspend(true)}
            className="inline-flex items-center gap-1.5 rounded-md bg-[var(--status-good)] px-3 py-1.5 text-[12px] font-medium text-white hover:opacity-90 transition-opacity"
          >
            <RotateCcw className="h-3.5 w-3.5" />
            Unsuspend
          </button>
        ) : (
          <button
            onClick={() => setShowSuspend(true)}
            className="inline-flex items-center gap-1.5 rounded-md border border-[var(--status-bad)] bg-[var(--status-bad-bg)] px-3 py-1.5 text-[12px] font-medium text-[var(--status-bad)] hover:bg-[var(--status-bad)] hover:text-white transition-colors"
          >
            <Ban className="h-3.5 w-3.5" />
            Suspend
          </button>
        )}
      </PageHeader>

      {/* header strip */}
      <div className="flex items-center gap-6 mb-5 p-4 rounded-lg border border-[var(--line)] bg-[var(--surface)]">
        <div className="flex items-center gap-2">
          <PlanBadge tier={business.plan} />
          <StatusDot
            status={business.status === 'active' ? 'good' : business.status === 'suspended' ? 'bad' : 'warn'}
            label={business.status.charAt(0).toUpperCase() + business.status.slice(1)}
            meta={timeAgo(business.lastActive)}
          />
        </div>
        <div className="text-[12px] text-[var(--ink-muted)]">
          Owner: <span className="text-[var(--ink)] font-medium">{business.ownerName}</span>
          {business.ownerPhone && (
            <span className="ml-1 font-mono text-[var(--ink-faint)]">{business.ownerPhone}</span>
          )}
        </div>
        <div className="text-[12px] text-[var(--ink-muted)] ml-auto">
          Joined {formatDate(business.createdAt)}
        </div>
      </div>

      <Tabs tabs={TABS} active={tab} onChange={setTab} className="mb-6" />

      {/* Overview */}
      {tab === 'overview' && (
        <div className="grid grid-cols-3 gap-4">
          <KPICard label="Staff Members" value={business.staffCount.toString()} mono={false} />
          <KPICard label="Last Active" value={timeAgo(business.lastActive)} mono={false} />
          <KPICard label="Joined" value={formatDate(business.createdAt)} mono={false} />
          <KPICard label="Total Invoices" value={(business.invoiceCount ?? 0).toString()} mono={false} />
          <KPICard label="Industry" value={business.industry} mono={false} />
          {business.location && <KPICard label="Location" value={business.location} mono={false} />}
        </div>
      )}

      {/* Subscription */}
      {tab === 'subscription' && (
        <div className="rounded-lg border border-[var(--line)] bg-[var(--surface)] p-6">
          <div className="flex items-center gap-3 mb-4">
            <PlanBadge tier={business.plan} />
            {business.plan === 'lifetime' && (
              <span className="text-[12px] text-[var(--ink-muted)]">Lifetime program — UTT AMIS invested</span>
            )}
          </div>
          {business.plan !== 'lifetime' && business.mrr > 0 && (
            <div className="text-[24px] font-mono font-semibold text-[var(--ink)]">
              {formatTZS(business.mrr)}
              <span className="text-[14px] text-[var(--ink-muted)] font-sans font-normal ml-2">/month</span>
            </div>
          )}
          {business.plan === 'starter' && (
            <p className="mt-2 text-[13px] text-[var(--ink-muted)]">Free trial — no recurring charge.</p>
          )}
          {business.plan === 'lifetime' && (
            <div className="mt-2 text-[13px] text-[var(--ink-muted)]">
              View full UTT AMIS details on the{' '}
              <a href="/lifetime" className="text-[var(--accent)] hover:underline">Lifetime page</a>.
            </div>
          )}
        </div>
      )}

      {/* Staff */}
      {tab === 'staff' && (
        <div className="rounded-lg border border-[var(--line)] bg-[var(--surface)] p-6">
          <p className="text-[13px] text-[var(--ink)]">
            <span className="font-semibold">{business.staffCount}</span>{' '}
            team member{business.staffCount !== 1 ? 's' : ''} on this business.
          </p>
          <p className="mt-2 text-[12px] text-[var(--ink-faint)]">
            Individual roster view coming in a future release.
          </p>
        </div>
      )}

      {/* Financial */}
      {tab === 'financial' && (
        <div className="grid grid-cols-2 gap-4">
          <KPICard label="Total Invoices" value={(business.invoiceCount ?? 0).toString()} mono={false} />
          <KPICard label="Total Revenue" value={business.totalRevenue ? formatTZS(business.totalRevenue) : '—'} />
          <KPICard label="Receivables" value={business.receivables ? formatTZS(business.receivables) : '—'} />
          <KPICard label="Total Expenses" value={business.expenseTotal ? formatTZS(business.expenseTotal) : '—'} />
        </div>
      )}

      {/* Notes */}
      {tab === 'notes' && (
        <div className="rounded-lg border border-[var(--line)] bg-[var(--surface)] p-6">
          <h3 className="text-[14px] font-semibold text-[var(--ink)] mb-4">Internal Notes</h3>
          {(!business.notes || business.notes.length === 0) && (
            <p className="text-[13px] text-[var(--ink-faint)] mb-4">No notes yet. Add context for the support team.</p>
          )}
          {business.notes?.map((note) => (
            <div key={note.id} className="mb-3 rounded-md bg-[var(--canvas)] border border-[var(--line)] p-3">
              <div className="flex items-center gap-2 mb-1">
                <span className="text-[12px] font-medium text-[var(--ink)]">{note.author}</span>
                <span className="text-[11px] text-[var(--ink-faint)]">{formatDate(note.createdAt)}</span>
              </div>
              <p className="text-[13px] text-[var(--ink-muted)]">{note.content}</p>
            </div>
          ))}
          <div className="mt-4 flex gap-2">
            <input
              value={noteInput}
              onChange={(e) => setNoteInput(e.target.value)}
              onKeyDown={(e) => e.key === 'Enter' && !e.shiftKey && handleAddNote()}
              placeholder="Add a note…"
              className="flex-1 rounded-md border border-[var(--line)] bg-[var(--canvas)] px-3 py-2 text-[13px] focus:outline-none focus:ring-1 focus:ring-[var(--accent)]"
            />
            <button
              onClick={handleAddNote}
              disabled={savingNote || !noteInput.trim()}
              className="inline-flex items-center gap-1.5 rounded-md bg-[var(--navy)] px-3 py-2 text-[12px] font-medium text-white hover:bg-[var(--navy-soft)] transition-colors disabled:opacity-50"
            >
              <MessageSquarePlus className="h-3.5 w-3.5" />
              {savingNote ? 'Saving…' : 'Add'}
            </button>
          </div>
        </div>
      )}

      <ConfirmDialog
        open={showSuspend}
        onClose={() => setShowSuspend(false)}
        onConfirm={handleToggleSuspend}
        title={`Suspend ${business.name}?`}
        consequence="Suspending blocks sign-in immediately for all staff. Their business data is untouched and can be restored by unsuspending."
        confirmLabel={actionPending ? 'Saving…' : 'Suspend business'}
        variant="destructive"
      />
      <ConfirmDialog
        open={showUnsuspend}
        onClose={() => setShowUnsuspend(false)}
        onConfirm={handleToggleSuspend}
        title={`Unsuspend ${business.name}?`}
        consequence="Restoring access will allow all staff to sign in immediately. Make sure the reason for suspension has been resolved."
        confirmLabel={actionPending ? 'Saving…' : 'Unsuspend business'}
        variant="warning"
      />
    </div>
  )
}
