'use client'

import { useState, useMemo } from 'react'
import {
  CheckCircle2,
  Clock,
  AlertCircle,
  Search,
  ChevronRight,
  Send,
  Calendar,
  Layers,
} from 'lucide-react'
import { StatusDot } from '@/components/ui/status-dot'
import { timeAgo } from '@/lib/format'
import { BeemCampaignDetailsDrawer } from './beem-campaign-details-drawer'
import { CAMPAIGN_PRESETS } from './campaign-presets'
import { cn } from '@/lib/utils'
import type { BeemSmsCampaign } from '@/types'

const statusConfig: Record<
  BeemSmsCampaign['status'],
  { status: 'good' | 'warn' | 'bad'; label: string; icon: typeof CheckCircle2 }
> = {
  sent: { status: 'good', label: 'Sent', icon: CheckCircle2 },
  sending: { status: 'warn', label: 'Sending…', icon: Clock },
  scheduled: { status: 'warn', label: 'Scheduled', icon: Calendar },
  draft: { status: 'warn', label: 'Draft', icon: Clock },
  partially_failed: { status: 'warn', label: 'Partial', icon: AlertCircle },
  failed: { status: 'bad', label: 'Failed', icon: AlertCircle },
  cancelled: { status: 'bad', label: 'Cancelled', icon: AlertCircle },
}

function audienceSummary(c: BeemSmsCampaign): string {
  if (c.audience.kind === 'all') return 'All users'
  if (c.audience.kind === 'business_category') return `Category: ${c.audience.categoryName || c.audience.category}`
  if (c.audience.kind === 'plan_tier') return `Tier: ${c.audience.planTier}`
  if (c.audience.kind === 'custom_numbers') return `${c.audience.customNumbers?.length ?? 0} custom numbers`
  const names = c.audience.businessNames ?? []
  if (names.length <= 2) return names.join(', ') || `${c.audience.businessIds?.length ?? 0} businesses`
  return `${names[0]}, ${names[1]} +${names.length - 2} more`
}

interface BeemCampaignsTableProps {
  campaigns: BeemSmsCampaign[]
  onDeleteCampaign?: (id: string) => void
}

export function BeemCampaignsTable({ campaigns, onDeleteCampaign }: BeemCampaignsTableProps) {
  const [query, setQuery] = useState('')
  const [selectedCampaign, setSelectedCampaign] = useState<BeemSmsCampaign | null>(null)

  const filtered = useMemo(() => {
    const q = query.trim().toLowerCase()
    if (!q) return campaigns
    return campaigns.filter(
      (c) =>
        c.name.toLowerCase().includes(q) ||
        c.message.toLowerCase().includes(q) ||
        c.createdByAdminName.toLowerCase().includes(q) ||
        c.senderId.toLowerCase().includes(q)
    )
  }, [campaigns, query])

  return (
    <>
      <div className="rounded-lg border border-[var(--line)] bg-[var(--surface)] overflow-hidden shadow-xs">
        <div className="flex items-center justify-between border-b border-[var(--line)] px-4 py-3 bg-[var(--canvas)]">
          <div className="flex items-center gap-2 flex-1 max-w-sm">
            <Search className="h-3.5 w-3.5 text-[var(--ink-faint)] shrink-0" />
            <input
              value={query}
              onChange={(e) => setQuery(e.target.value)}
              placeholder="Search campaigns or messages…"
              className="w-full bg-transparent text-[12.5px] text-[var(--ink)] placeholder:text-[var(--ink-faint)] outline-none"
            />
          </div>
          <span className="text-[12px] text-[var(--ink-faint)]">
            {filtered.length} {filtered.length === 1 ? 'campaign' : 'campaigns'}
          </span>
        </div>

        {filtered.length === 0 ? (
          <div className="text-center py-12 text-[var(--ink-faint)] text-[13px]">
            No SMS campaigns found. Create your first campaign above!
          </div>
        ) : (
          <div className="divide-y divide-[var(--line)]">
            {filtered.map((c) => {
              const cfg = statusConfig[c.status] || statusConfig.sent
              const Icon = cfg.icon
              const preset = CAMPAIGN_PRESETS.find((p) => p.id === c.campaignType)
              const iconEmoji = preset?.icon || '📱'

              return (
                <div
                  key={c.id}
                  onClick={() => setSelectedCampaign(c)}
                  className="flex items-start gap-4 px-4 py-3.5 hover:bg-[var(--hover-bg)] cursor-pointer transition-colors group"
                >
                  <span className="text-xl mt-0.5 shrink-0">{iconEmoji}</span>

                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-2 flex-wrap">
                      <span className="font-semibold text-[var(--ink)] text-[13px] group-hover:text-[var(--accent)] transition-colors">
                        {c.name}
                      </span>
                      <span className="text-[11px] text-[var(--ink-faint)] bg-[var(--canvas)] border border-[var(--line)] rounded px-1.5 py-0.5 capitalize">
                        {c.campaignType.replace(/_/g, ' ')}
                      </span>
                      <span className="text-[10.5px] font-mono text-[var(--ink-muted)] bg-[var(--canvas)] px-1.5 py-0.5 rounded border border-[var(--line)]">
                        Sender: {c.senderId}
                      </span>
                    </div>
                    <p className="text-[12px] text-[var(--ink-muted)] mt-1 line-clamp-1">
                      {c.message}
                    </p>
                    <div className="text-[11px] text-[var(--ink-faint)] mt-1.5 flex items-center gap-2 flex-wrap">
                      <span>{audienceSummary(c)}</span>
                      <span>·</span>
                      <span>By {c.createdByAdminName}</span>
                      {c.scheduledAt && (
                        <>
                          <span>·</span>
                          <span className="text-amber-600 dark:text-amber-400 font-medium">
                            Scheduled: {new Date(c.scheduledAt).toLocaleString()}
                          </span>
                        </>
                      )}
                    </div>
                  </div>

                  <div className="shrink-0 text-right flex flex-col items-end">
                    <StatusDot status={cfg.status} label={cfg.label} />
                    <div className="text-[11px] text-[var(--ink-faint)] mt-1 font-mono">
                      {c.sentCount}/{c.targetCount} delivered
                      {c.failedCount > 0 ? (
                        <span className="text-[var(--status-bad)] ml-1">
                          ({c.failedCount} failed)
                        </span>
                      ) : null}
                    </div>
                    <div className="text-[10.5px] text-[var(--ink-faint)] mt-0.5">
                      {timeAgo(c.createdAt)}
                    </div>
                  </div>

                  <ChevronRight className="h-4 w-4 text-[var(--ink-faint)] shrink-0 self-center group-hover:translate-x-0.5 transition-transform" />
                </div>
              )
            })}
          </div>
        )}
      </div>

      <BeemCampaignDetailsDrawer
        campaign={selectedCampaign}
        open={Boolean(selectedCampaign)}
        onClose={() => setSelectedCampaign(null)}
        onDelete={(id) => {
          setSelectedCampaign(null)
          onDeleteCampaign?.(id)
        }}
      />
    </>
  )
}
