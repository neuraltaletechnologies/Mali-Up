'use client'

import { useCallback, useMemo, useState } from 'react'
import { Send, Search, AlertCircle, CheckCircle2, Clock } from 'lucide-react'
import { PageHeader } from '@/components/ui/page-header'
import { SegmentedControl } from '@/components/ui/segmented-control'
import { StatusDot } from '@/components/ui/status-dot'
import { ConfirmDialog } from '@/components/ui/confirm-dialog'
import { SkeletonTable, RevalidatingBar } from '@/components/ui/skeleton'
import { fetchBusinesses, fetchPushBroadcasts, sendPushBroadcast } from '@/lib/admin-api'
import { useAdminFetch } from '@/hooks/use-admin-fetch'
import { timeAgo } from '@/lib/format'
import { cn } from '@/lib/utils'
import type { Business, BroadcastCategory, PushBroadcast } from '@/types'

const CATEGORY_OPTIONS: { value: BroadcastCategory; label: string }[] = [
  { value: 'reminder',  label: 'Reminder' },
  { value: 'promotion', label: 'Promotion' },
  { value: 'update',    label: 'Update' },
  { value: 'general',   label: 'General' },
]

const AUDIENCE_OPTIONS: { value: 'all' | 'businesses'; label: string }[] = [
  { value: 'all',         label: 'All users' },
  { value: 'businesses',  label: 'Selected businesses' },
]

const statusConfig: Record<PushBroadcast['status'], { status: 'good' | 'warn' | 'bad'; label: string; icon: typeof CheckCircle2 }> = {
  sent:    { status: 'good', label: 'Sent',    icon: CheckCircle2 },
  pending: { status: 'warn', label: 'Sending…', icon: Clock },
  failed:  { status: 'bad',  label: 'Failed',  icon: AlertCircle },
}

function audienceSummary(b: PushBroadcast): string {
  if (b.audience.kind === 'all') return 'All users'
  const names = b.audience.businessNames ?? []
  if (names.length <= 2) return names.join(', ') || `${b.audience.businessIds.length} businesses`
  return `${names[0]}, ${names[1]} +${names.length - 2} more`
}

function BusinessPicker({
  businesses,
  selectedIds,
  onToggle,
}: {
  businesses: Business[]
  selectedIds: Set<string>
  onToggle: (id: string, name: string) => void
}) {
  const [query, setQuery] = useState('')

  const filtered = useMemo(() => {
    const q = query.trim().toLowerCase()
    if (!q) return businesses
    return businesses.filter(
      (b) => b.name.toLowerCase().includes(q) || b.ownerName.toLowerCase().includes(q) || b.ownerPhone.includes(q),
    )
  }, [businesses, query])

  return (
    <div className="rounded-md border border-[var(--line)] bg-[var(--canvas)]">
      <div className="flex items-center gap-2 border-b border-[var(--line)] px-3 py-2">
        <Search className="h-3.5 w-3.5 text-[var(--ink-faint)] shrink-0" />
        <input
          value={query}
          onChange={(e) => setQuery(e.target.value)}
          placeholder="Search business or owner…"
          className="flex-1 bg-transparent text-[12.5px] text-[var(--ink)] placeholder:text-[var(--ink-faint)] outline-none"
        />
        {selectedIds.size > 0 && (
          <span className="text-[11px] text-[var(--accent)] font-medium shrink-0">{selectedIds.size} selected</span>
        )}
      </div>
      <div className="max-h-64 overflow-y-auto">
        {filtered.length === 0 ? (
          <p className="px-3 py-6 text-center text-[12px] text-[var(--ink-faint)]">No businesses match.</p>
        ) : (
          filtered.map((b) => (
            <label
              key={b.id}
              className="flex items-center gap-2.5 px-3 py-2 border-b border-[var(--line)] last:border-b-0 hover:bg-[var(--hover-bg)] cursor-pointer"
            >
              <input
                type="checkbox"
                checked={selectedIds.has(b.id)}
                onChange={() => onToggle(b.id, b.name)}
                className="h-3.5 w-3.5 shrink-0 accent-[var(--accent)]"
              />
              <span className="min-w-0 flex-1">
                <span className="block truncate text-[12.5px] font-medium text-[var(--ink)]">{b.name}</span>
                <span className="block truncate text-[11px] text-[var(--ink-muted)]">{b.ownerName} · {b.ownerPhone}</span>
              </span>
            </label>
          ))
        )}
      </div>
    </div>
  )
}

function BroadcastRow({ b }: { b: PushBroadcast }) {
  const cfg = statusConfig[b.status]
  const Icon = cfg.icon
  return (
    <div className="flex items-start gap-4 px-4 py-3.5 border-b border-[var(--line)] last:border-b-0">
      <Icon className="mt-0.5 h-4 w-4 shrink-0 text-[var(--ink-muted)]" />
      <div className="flex-1 min-w-0">
        <div className="flex items-center gap-2 flex-wrap">
          <span className="font-medium text-[var(--ink)] text-[13px]">{b.titleEn}</span>
          <span className="text-[11px] text-[var(--ink-faint)] bg-[var(--canvas)] border border-[var(--line)] rounded px-1.5 py-0.5 capitalize">
            {b.category}
          </span>
        </div>
        <p className="text-[12px] text-[var(--ink-muted)] mt-0.5 truncate">{b.bodyEn}</p>
        <div className="text-[11px] text-[var(--ink-faint)] mt-1">
          {audienceSummary(b)} · by {b.createdByAdminName}
        </div>
      </div>
      <div className="shrink-0 text-right">
        <StatusDot status={cfg.status} label={cfg.label} />
        {b.status === 'sent' && (
          <div className="text-[11px] text-[var(--ink-faint)] mt-1">
            {b.sentCount}/{b.targetCount} delivered{b.failureCount > 0 ? `, ${b.failureCount} failed` : ''}
          </div>
        )}
        <div className="text-[11px] text-[var(--ink-faint)] mt-0.5">{timeAgo(b.createdAt)}</div>
      </div>
    </div>
  )
}

export default function NotificationsPage() {
  const { data: broadcastData, loading, revalidating, error, refetch } = useAdminFetch(
    useCallback(() => fetchPushBroadcasts(), []),
    { key: 'push-notifications', pollingInterval: 15_000, minStaleMs: 5_000 },
  )
  const { data: businessData } = useAdminFetch(useCallback(() => fetchBusinesses(), []), { key: 'businesses' })

  const broadcasts = broadcastData?.broadcasts ?? []
  const businesses = businessData?.businesses ?? []

  const [category, setCategory] = useState<BroadcastCategory>('general')
  const [audienceKind, setAudienceKind] = useState<'all' | 'businesses'>('all')
  const [titleEn, setTitleEn] = useState('')
  const [bodyEn, setBodyEn] = useState('')
  const [titleSw, setTitleSw] = useState('')
  const [bodySw, setBodySw] = useState('')
  const [selectedBusinesses, setSelectedBusinesses] = useState<Map<string, string>>(new Map())
  const [confirmOpen, setConfirmOpen] = useState(false)
  const [sending, setSending] = useState(false)
  const [sendError, setSendError] = useState<string | null>(null)

  function toggleBusiness(id: string, name: string) {
    setSelectedBusinesses((prev) => {
      const next = new Map(prev)
      if (next.has(id)) next.delete(id)
      else next.set(id, name)
      return next
    })
  }

  const canSend =
    titleEn.trim().length > 0 &&
    bodyEn.trim().length > 0 &&
    (audienceKind === 'all' || selectedBusinesses.size > 0)

  const audienceLabel =
    audienceKind === 'all' ? 'every user with the app installed' : `${selectedBusinesses.size} selected business${selectedBusinesses.size === 1 ? '' : 'es'}`

  async function handleSend() {
    setSending(true)
    setSendError(null)
    try {
      await sendPushBroadcast({
        titleEn: titleEn.trim(),
        bodyEn: bodyEn.trim(),
        titleSw: titleSw.trim() || undefined,
        bodySw: bodySw.trim() || undefined,
        category,
        audience:
          audienceKind === 'all'
            ? { kind: 'all' }
            : {
                kind: 'businesses',
                businessIds: Array.from(selectedBusinesses.keys()),
                businessNames: Array.from(selectedBusinesses.values()),
              },
      })
      setTitleEn('')
      setBodyEn('')
      setTitleSw('')
      setBodySw('')
      setSelectedBusinesses(new Map())
      setConfirmOpen(false)
      refetch()
    } catch (err) {
      setSendError(err instanceof Error ? err.message : 'Failed to send notification')
    } finally {
      setSending(false)
    }
  }

  return (
    <div>
      <PageHeader
        title="Notifications"
        description="Send push notifications to the mobile app — reminders, promotions, and updates."
      />

      {/* ── Compose ─────────────────────────────────────────────────────── */}
      <div className="rounded-lg border border-[var(--line)] bg-[var(--surface)] p-5 mb-6">
        <div className="grid gap-4 md:grid-cols-2">
          <div className="md:col-span-2 flex items-center justify-between flex-wrap gap-2">
            <SegmentedControl options={CATEGORY_OPTIONS} value={category} onChange={setCategory} />
            <SegmentedControl options={AUDIENCE_OPTIONS} value={audienceKind} onChange={setAudienceKind} />
          </div>

          <div>
            <label className="block text-[12px] font-medium text-[var(--ink-muted)] mb-1">Title (English)</label>
            <input
              value={titleEn}
              onChange={(e) => setTitleEn(e.target.value)}
              maxLength={80}
              placeholder="e.g. Your invoice is overdue"
              className="w-full rounded-md border border-[var(--line)] bg-[var(--canvas)] px-3 py-2 text-[13px] text-[var(--ink)] outline-none focus:border-[var(--accent)]"
            />
          </div>
          <div>
            <label className="block text-[12px] font-medium text-[var(--ink-muted)] mb-1">Title (Swahili — optional)</label>
            <input
              value={titleSw}
              onChange={(e) => setTitleSw(e.target.value)}
              maxLength={80}
              placeholder="e.g. Ankara yako imechelewa"
              className="w-full rounded-md border border-[var(--line)] bg-[var(--canvas)] px-3 py-2 text-[13px] text-[var(--ink)] outline-none focus:border-[var(--accent)]"
            />
          </div>

          <div>
            <label className="block text-[12px] font-medium text-[var(--ink-muted)] mb-1">Message (English)</label>
            <textarea
              value={bodyEn}
              onChange={(e) => setBodyEn(e.target.value)}
              rows={3}
              maxLength={200}
              placeholder="Short, clear message shown in the notification"
              className="w-full rounded-md border border-[var(--line)] bg-[var(--canvas)] px-3 py-2 text-[13px] text-[var(--ink)] outline-none focus:border-[var(--accent)] resize-none"
            />
          </div>
          <div>
            <label className="block text-[12px] font-medium text-[var(--ink-muted)] mb-1">Message (Swahili — optional)</label>
            <textarea
              value={bodySw}
              onChange={(e) => setBodySw(e.target.value)}
              rows={3}
              maxLength={200}
              placeholder="Falls back to the English message if left blank"
              className="w-full rounded-md border border-[var(--line)] bg-[var(--canvas)] px-3 py-2 text-[13px] text-[var(--ink)] outline-none focus:border-[var(--accent)] resize-none"
            />
          </div>

          {audienceKind === 'businesses' && (
            <div className="md:col-span-2">
              <label className="block text-[12px] font-medium text-[var(--ink-muted)] mb-1">Businesses</label>
              <BusinessPicker businesses={businesses} selectedIds={new Set(selectedBusinesses.keys())} onToggle={toggleBusiness} />
            </div>
          )}
        </div>

        {sendError && (
          <div className="mt-4 flex items-center gap-2 rounded-md border border-[var(--status-bad)] bg-[var(--status-bad-bg)] px-3 py-2 text-[12.5px] text-[var(--status-bad)]">
            <AlertCircle className="h-3.5 w-3.5 shrink-0" />
            {sendError}
          </div>
        )}

        <div className="mt-4 flex justify-end">
          <button
            onClick={() => setConfirmOpen(true)}
            disabled={!canSend}
            className={cn(
              'inline-flex items-center gap-2 rounded-md px-4 py-2 text-[13px] font-medium text-white transition-colors',
              canSend ? 'bg-[var(--navy)] hover:opacity-90' : 'bg-[var(--line)] text-[var(--ink-faint)] cursor-not-allowed',
            )}
          >
            <Send className="h-3.5 w-3.5" />
            Send notification
          </button>
        </div>
      </div>

      <ConfirmDialog
        open={confirmOpen}
        onClose={() => !sending && setConfirmOpen(false)}
        onConfirm={handleSend}
        loading={sending}
        variant="warning"
        title="Send this notification?"
        description={`This will push "${titleEn}" to ${audienceLabel}. This can't be recalled once sent.`}
        confirmLabel="Send"
      />

      {/* ── History ──────────────────────────────────────────────────────── */}
      <PageHeader title="Recent broadcasts" className="mb-3" />
      {revalidating && <RevalidatingBar />}
      {loading ? (
        <SkeletonTable rows={5} cols={4} />
      ) : error && !broadcastData ? (
        <div className="flex items-center gap-3 rounded-lg border border-[var(--status-bad)] bg-[var(--status-bad-bg)] p-4 text-[var(--status-bad)]">
          <AlertCircle className="h-4 w-4 shrink-0" />
          <span className="text-[13px]">{error}</span>
        </div>
      ) : (
        <div className="rounded-lg border border-[var(--line)] bg-[var(--surface)] overflow-hidden">
          {broadcasts.length === 0 ? (
            <div className="text-center py-12 text-[var(--ink-faint)] text-[13px]">
              No notifications sent yet.
            </div>
          ) : (
            broadcasts.map((b) => <BroadcastRow key={b.id} b={b} />)
          )}
        </div>
      )}
    </div>
  )
}
