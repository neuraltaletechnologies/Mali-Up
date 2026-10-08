'use client'

import { DetailDrawer } from '@/components/ui/detail-drawer'
import { StatusDot } from '@/components/ui/status-dot'
import { timeAgo } from '@/lib/format'
import { CheckCircle2, Clock, AlertCircle, Trash2 } from 'lucide-react'
import type { BeemSmsCampaign } from '@/types'

interface BeemCampaignDetailsDrawerProps {
  campaign: BeemSmsCampaign | null
  open: boolean
  onClose: () => void
  onDelete?: (id: string) => void
}

export function BeemCampaignDetailsDrawer({
  campaign,
  open,
  onClose,
  onDelete,
}: BeemCampaignDetailsDrawerProps) {
  if (!campaign) return null

  const statusLabel =
    campaign.status === 'sent'
      ? 'Sent'
      : campaign.status === 'scheduled'
      ? 'Scheduled'
      : campaign.status === 'sending'
      ? 'Sending'
      : campaign.status === 'partially_failed'
      ? 'Partially Failed'
      : 'Failed'

  const dotStatus: 'good' | 'warn' | 'bad' =
    campaign.status === 'sent'
      ? 'good'
      : campaign.status === 'scheduled' || campaign.status === 'sending'
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
              <div className="text-[11px] text-[var(--status-good)]">Delivered</div>
              <div className="text-[15px] font-bold text-[var(--status-good)] font-mono">
                {campaign.sentCount.toLocaleString()}
              </div>
            </div>
            <div>
              <div className="text-[11px] text-[var(--status-bad)]">Failed</div>
              <div className="text-[15px] font-bold text-[var(--status-bad)] font-mono">
                {campaign.failedCount.toLocaleString()}
              </div>
            </div>
          </div>
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

        {/* Failed Recipients Breakdown if any */}
        {campaign.failedRecipients && campaign.failedRecipients.length > 0 && (
          <div className="space-y-2">
            <label className="block text-[12px] font-semibold text-[var(--status-bad)]">
              Delivery Issues ({campaign.failedRecipients.length})
            </label>
            <div className="rounded-md border border-[var(--status-bad)]/30 bg-[var(--status-bad-bg)] p-2.5 max-h-40 overflow-y-auto divide-y divide-[var(--status-bad)]/20">
              {campaign.failedRecipients.map((f, i) => (
                <div key={i} className="py-1 text-[11.5px] flex justify-between gap-2">
                  <span className="font-mono text-[var(--ink)]">{f.phone}</span>
                  <span className="text-[var(--status-bad)] truncate">{f.reason}</span>
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
    </DetailDrawer>
  )
}
