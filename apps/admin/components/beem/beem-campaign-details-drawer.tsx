'use client'

import { useEffect, useMemo, useState } from 'react'
import { DetailDrawer } from '@/components/ui/detail-drawer'
import { StatusDot } from '@/components/ui/status-dot'
import { ConfirmDialog } from '@/components/ui/confirm-dialog'
import { timeAgo } from '@/lib/format'
import { cn } from '@/lib/utils'
import { fetchBeemCampaignRecipients, resendBeemCampaign } from '@/lib/admin-api'
import { RotateCcw, Trash2 } from 'lucide-react'
import type { BeemSmsCampaign, SmsCampaignRecipient } from '@/types'

interface BeemCampaignDetailsDrawerProps {
  campaign: BeemSmsCampaign | null
  open: boolean
  onClose: () => void
  onDelete?: (id: string) => void
  /** Called after "Resend to not delivered" queues a new campaign. */
  onResent?: () => void
}

type RecipientFilter = 'all' | 'not_delivered' | 'pending' | 'delivered'

/** Failed at Beem, or Beem reported the handset never got it. */
function isNotDelivered(r: SmsCampaignRecipient): boolean {
  return r.status === 'failed' || r.dlrStatus === 'UNDELIVERED'
}

function recipientLabel(r: SmsCampaignRecipient): { text: string; tone: 'good' | 'warn' | 'bad' } {
  if (r.status === 'failed') return { text: 'Not sent', tone: 'bad' }
  if (r.dlrStatus === 'DELIVERED') return { text: 'Delivered', tone: 'good' }
  if (r.dlrStatus === 'UNDELIVERED') return { text: 'Undelivered', tone: 'bad' }
  return { text: 'Pending', tone: 'warn' }
}

const TONE_CLASS = {
  good: 'text-[var(--status-good)]',
  warn: 'text-amber-600 dark:text-amber-400',
  bad: 'text-[var(--status-bad)]',
} as const

export function BeemCampaignDetailsDrawer({
  campaign,
  open,
  onClose,
  onDelete,
  onResent,
}: BeemCampaignDetailsDrawerProps) {
  const [recipients, setRecipients] = useState<SmsCampaignRecipient[] | null>(null)
  const [recipientsError, setRecipientsError] = useState<string | null>(null)
  const [filter, setFilter] = useState<RecipientFilter>('all')
  const [confirmResend, setConfirmResend] = useState(false)
  const [resending, setResending] = useState(false)
  const [resendNotice, setResendNotice] = useState<string | null>(null)

  const campaignId = campaign?.id
  const tracked = campaign?.recipientsTracked === true

  // Loaded once per drawer open, never polled: it costs one read per recipient.
  useEffect(() => {
    setRecipients(null)
    setRecipientsError(null)
    setFilter('all')
    setResendNotice(null)
    if (!open || !campaignId || !tracked) return
    let active = true
    fetchBeemCampaignRecipients(campaignId)
      .then((res) => active && setRecipients(res.recipients))
      .catch((err: Error) => active && setRecipientsError(err.message))
    return () => {
      active = false
    }
  }, [open, campaignId, tracked])

  const notDeliveredCount = useMemo(
    () => (recipients ?? []).filter(isNotDelivered).length,
    [recipients]
  )

  const visibleRecipients = useMemo(() => {
    const list = recipients ?? []
    if (filter === 'not_delivered') return list.filter(isNotDelivered)
    if (filter === 'delivered') return list.filter((r) => r.dlrStatus === 'DELIVERED')
    if (filter === 'pending') return list.filter((r) => r.status === 'accepted' && (!r.dlrStatus || r.dlrStatus === 'PENDING'))
    return list
  }, [recipients, filter])

  if (!campaign) return null

  const finished = !['queued', 'scheduled', 'sending', 'draft'].includes(campaign.status)

  async function handleResend() {
    if (!campaign) return
    setResending(true)
    try {
      const res = await resendBeemCampaign(campaign.id)
      setResendNotice(`Resend queued for ${res.recipientCount} numbers. It appears in the history as a new campaign.`)
      setConfirmResend(false)
      onResent?.()
    } catch (err) {
      setResendNotice(err instanceof Error ? err.message : 'Failed to queue resend')
      setConfirmResend(false)
    } finally {
      setResending(false)
    }
  }

  const statusLabel =
    campaign.status === 'sent'
      ? 'Sent'
      : campaign.status === 'scheduled'
      ? 'Scheduled'
      : campaign.status === 'queued'
      ? 'Queued'
      : campaign.status === 'sending'
      ? 'Sending'
      : campaign.status === 'partially_failed'
      ? 'Partially Failed'
      : 'Failed'

  const dotStatus: 'good' | 'warn' | 'bad' =
    campaign.status === 'sent'
      ? 'good'
      : campaign.status === 'scheduled' || campaign.status === 'queued' || campaign.status === 'sending'
      ? 'warn'
      : 'bad'

  return (
    <DetailDrawer
      open={open}
      onClose={onClose}
      title={campaign.name}
      description={`Created by ${campaign.createdByAdminName} · ${timeAgo(campaign.createdAt)}`}
      width="w-[520px]"
    >
      <div className="space-y-6">
        {/* Status & Delivery Card */}
        <div className="rounded-lg border border-[var(--line)] bg-[var(--canvas)] p-4 space-y-3">
          <div className="flex items-center justify-between">
            <span className="text-[12px] font-medium text-[var(--ink-muted)]">Campaign Status</span>
            <StatusDot status={dotStatus} label={statusLabel} />
          </div>

          <div className="grid grid-cols-3 gap-2 pt-2 border-t border-[var(--line)] text-center">
            <div>
              <div className="text-[11px] text-[var(--ink-faint)]">Target</div>
              <div className="text-[15px] font-bold text-[var(--ink)] font-mono">
                {campaign.targetCount.toLocaleString()}
              </div>
            </div>
            <div>
              <div className="text-[11px] text-[var(--ink-faint)]">Accepted by Beem</div>
              <div className="text-[15px] font-bold text-[var(--ink)] font-mono">
                {campaign.sentCount.toLocaleString()}
              </div>
            </div>
            <div>
              <div className="text-[11px] text-[var(--status-bad)]">Not sent</div>
              <div className="text-[15px] font-bold text-[var(--status-bad)] font-mono">
                {campaign.failedCount.toLocaleString()}
              </div>
            </div>
          </div>

          {tracked && (
            <>
              <div className="grid grid-cols-3 gap-2 pt-2 border-t border-[var(--line)] text-center">
                <div>
                  <div className="text-[11px] text-[var(--status-good)]">Delivered</div>
                  <div className="text-[15px] font-bold text-[var(--status-good)] font-mono">
                    {(campaign.deliveredCount ?? 0).toLocaleString()}
                  </div>
                </div>
                <div>
                  <div className="text-[11px] text-[var(--status-bad)]">Undelivered</div>
                  <div className="text-[15px] font-bold text-[var(--status-bad)] font-mono">
                    {(campaign.undeliveredCount ?? 0).toLocaleString()}
                  </div>
                </div>
                <div>
                  <div className="text-[11px] text-amber-600 dark:text-amber-400">Pending</div>
                  <div className="text-[15px] font-bold text-amber-600 dark:text-amber-400 font-mono">
                    {(campaign.dlrPendingCount ?? 0).toLocaleString()}
                  </div>
                </div>
              </div>
              <p className="text-[11px] text-[var(--ink-faint)]">
                {campaign.dlrState === 'pending'
                  ? 'Checking delivery with Beem: first check 5 minutes after sending, then every 10 minutes for about an hour.'
                  : 'Delivery checks finished. Numbers still pending never got a final report from the network (phone off or out of coverage).'}
              </p>
            </>
          )}
          {!tracked && finished && (
            <p className="pt-2 border-t border-[var(--line)] text-[11px] text-[var(--ink-faint)]">
              Sent before per-recipient tracking was added, so handset delivery isn&apos;t known here.
              Check Beem&apos;s portal under SMS → Reports.
            </p>
          )}
        </div>

        {/* Message Content */}
        <div className="space-y-2">
          <label className="block text-[12px] font-semibold text-[var(--ink)]">Message Content</label>
          <div className="rounded-md border border-[var(--line)] bg-[var(--surface)] p-3 text-[13px] text-[var(--ink)] leading-relaxed font-mono whitespace-pre-wrap">
            {campaign.message}
          </div>
          <div className="flex items-center justify-between text-[11px] text-[var(--ink-faint)]">
            <span>Sender ID: <strong className="text-[var(--ink)]">{campaign.senderId}</strong></span>
            <span>{campaign.smsPartsCount} SMS Part(s) per recipient</span>
          </div>
        </div>

        {/* Audience Info */}
        <div className="space-y-2">
          <label className="block text-[12px] font-semibold text-[var(--ink)]">Audience Details</label>
          <div className="rounded-md border border-[var(--line)] bg-[var(--canvas)] p-3 text-[12.5px] space-y-1.5">
            <div className="flex justify-between">
              <span className="text-[var(--ink-muted)]">Target Type:</span>
              <span className="font-medium text-[var(--ink)] capitalize">
                {campaign.audience.kind.replace(/_/g, ' ')}
              </span>
            </div>
            {campaign.audience.categoryName && (
              <div className="flex justify-between">
                <span className="text-[var(--ink-muted)]">Category:</span>
                <span className="font-medium text-[var(--ink)]">{campaign.audience.categoryName}</span>
              </div>
            )}
            {campaign.audience.planTier && (
              <div className="flex justify-between">
                <span className="text-[var(--ink-muted)]">Plan Tier:</span>
                <span className="font-medium text-[var(--ink)] capitalize">{campaign.audience.planTier}</span>
              </div>
            )}
            {campaign.audience.businessNames && campaign.audience.businessNames.length > 0 && (
              <div className="flex justify-between">
                <span className="text-[var(--ink-muted)]">Selected:</span>
                <span className="font-medium text-[var(--ink)]">{campaign.audience.businessNames.join(', ')}</span>
              </div>
            )}
            {campaign.scheduledAt && (
              <div className="flex justify-between text-amber-600 dark:text-amber-400">
                <span>Scheduled for:</span>
                <span className="font-mono">{new Date(campaign.scheduledAt).toLocaleString()}</span>
              </div>
            )}
            {campaign.sentAt && (
              <div className="flex justify-between">
                <span className="text-[var(--ink-muted)]">Dispatched At:</span>
                <span className="font-mono">{new Date(campaign.sentAt).toLocaleString()}</span>
              </div>
            )}
          </div>
        </div>

        {/* Per-recipient results + resend */}
        {tracked && (
          <div className="space-y-2">
            <div className="flex items-center justify-between gap-2">
              <label className="block text-[12px] font-semibold text-[var(--ink)]">Recipients</label>
              {finished && (
                <button
                  onClick={() => setConfirmResend(true)}
                  disabled={!recipients || notDeliveredCount === 0 || resending}
                  className="inline-flex items-center gap-1.5 rounded-md border border-[var(--line)] px-2.5 py-1 text-[12px] font-medium text-[var(--ink)] hover:bg-[var(--canvas)] disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
                >
                  <RotateCcw className="h-3.5 w-3.5" />
                  Resend to not delivered{recipients ? ` (${notDeliveredCount})` : ''}
                </button>
              )}
            </div>

            {resendNotice && (
              <div className="rounded-md border border-[var(--line)] bg-[var(--canvas)] p-2.5 text-[12px] text-[var(--ink)]">
                {resendNotice}
              </div>
            )}

            <div className="flex flex-wrap gap-1">
              {(
                [
                  ['all', 'All'],
                  ['not_delivered', 'Not delivered'],
                  ['pending', 'Pending'],
                  ['delivered', 'Delivered'],
                ] as [RecipientFilter, string][]
              ).map(([key, label]) => (
                <button
                  key={key}
                  onClick={() => setFilter(key)}
                  className={cn(
                    'rounded-full px-2.5 py-0.5 text-[11.5px] border transition-colors',
                    filter === key
                      ? 'border-[var(--ink)] text-[var(--ink)] font-medium'
                      : 'border-[var(--line)] text-[var(--ink-muted)] hover:text-[var(--ink)]'
                  )}
                >
                  {label}
                </button>
              ))}
            </div>

            <div className="rounded-md border border-[var(--line)] bg-[var(--surface)] max-h-72 overflow-y-auto divide-y divide-[var(--line)]">
              {recipientsError ? (
                <div className="p-3 text-[12px] text-[var(--status-bad)]">{recipientsError}</div>
              ) : !recipients ? (
                <div className="p-3 text-[12px] text-[var(--ink-faint)]">Loading recipients…</div>
              ) : visibleRecipients.length === 0 ? (
                <div className="p-3 text-[12px] text-[var(--ink-faint)]">No recipients in this view.</div>
              ) : (
                visibleRecipients.map((r) => {
                  const label = recipientLabel(r)
                  return (
                    <div key={r.phone} className="px-3 py-1.5 flex items-start justify-between gap-3 text-[12px]">
                      <div className="min-w-0">
                        <div className="font-mono text-[var(--ink)]">{r.phone}</div>
                        <div className="text-[11px] text-[var(--ink-faint)] truncate">
                          {[r.name, r.businessName].filter(Boolean).join(' · ')}
                        </div>
                        {r.status === 'failed' && r.reason && (
                          <div className="text-[11px] text-[var(--status-bad)] break-words">{r.reason}</div>
                        )}
                      </div>
                      <span className={cn('shrink-0 font-medium', TONE_CLASS[label.tone])}>{label.text}</span>
                    </div>
                  )
                })
              )}
            </div>
          </div>
        )}

        {/* Failed Recipients Breakdown — only for campaigns from before per-recipient tracking */}
        {!tracked && campaign.failedRecipients && campaign.failedRecipients.length > 0 && (
          <div className="space-y-2">
            <label className="block text-[12px] font-semibold text-[var(--status-bad)]">
              Delivery Issues ({campaign.failedRecipients.length})
            </label>
            <div className="rounded-md border border-[var(--status-bad)]/30 bg-[var(--status-bad-bg)] p-2.5 max-h-40 overflow-y-auto divide-y divide-[var(--status-bad)]/20">
              {campaign.failedRecipients.map((f, i) => (
                <div key={i} className="py-1 text-[11.5px] flex justify-between gap-2">
                  <span className="font-mono text-[var(--ink)]">{f.phone}</span>
                  <span className="text-[var(--status-bad)] break-words text-right">{f.reason}</span>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* Delete action */}
        {onDelete && (
          <div className="pt-4 border-t border-[var(--line)] flex justify-end">
            <button
              onClick={() => onDelete(campaign.id)}
              className="inline-flex items-center gap-1.5 rounded-md px-3 py-1.5 text-[12px] font-medium text-[var(--status-bad)] hover:bg-[var(--status-bad-bg)] transition-colors"
            >
              <Trash2 className="h-3.5 w-3.5" />
              Delete Campaign Record
            </button>
          </div>
        )}
      </div>

      <ConfirmDialog
        open={confirmResend}
        onClose={() => setConfirmResend(false)}
        onConfirm={handleResend}
        loading={resending}
        variant="warning"
        title="Resend to not delivered?"
        description={`This queues a new campaign with the same message for the ${notDeliveredCount} numbers that were not sent or that Beem reported undelivered (about ${(notDeliveredCount * campaign.smsPartsCount).toLocaleString()} credits). Numbers still pending are left out, since their SMS may still arrive.`}
        confirmLabel="Resend"
      />
    </DetailDrawer>
  )
}
