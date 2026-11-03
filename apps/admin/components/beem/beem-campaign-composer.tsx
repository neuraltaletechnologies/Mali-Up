'use client'

import { useState, useEffect, useMemo } from 'react'
import {
  Send,
  Calendar,
  AlertCircle,
  Users,
  Search,
  Sparkles,
  Layers,
  ChevronDown,
} from 'lucide-react'
import { CAMPAIGN_PRESETS, CampaignPreset } from './campaign-presets'
import { createBeemCampaign, estimateSmsRecipients } from '@/lib/admin-api'
import { ConfirmDialog } from '@/components/ui/confirm-dialog'
import { cn } from '@/lib/utils'
import type { Business, PlanTier, SmsCampaignAudience, SmsCampaignAudienceKind, SmsCampaignType } from '@/types'

const BUSINESS_CATEGORIES = [
  { value: 'retail', label: 'Retail & Duka' },
  { value: 'pharmacy', label: 'Pharmacy & Healthcare' },
  { value: 'restaurant', label: 'Restaurant & Food' },
  { value: 'hardware', label: 'Hardware & Construction' },
  { value: 'salon', label: 'Salon & Cosmetics' },
  { value: 'agriculture', label: 'Agriculture & Agrovet' },
  { value: 'electronics', label: 'Electronics & Phones' },
  { value: 'service', label: 'Services & Consultancy' },
]

const PLAN_TIERS: { value: PlanTier; label: string }[] = [
  { value: 'starter', label: 'Starter (Free)' },
  { value: 'growth', label: 'Growth Plan' },
  { value: 'business', label: 'Business Plan' },
  { value: 'enterprise', label: 'Enterprise' },
  { value: 'lifetime', label: 'Lifetime Plan' },
]

interface BeemCampaignComposerProps {
  businesses: Business[]
  defaultSenderId?: string
  onCampaignCreated: () => void
}

export function BeemCampaignComposer({
  businesses,
  defaultSenderId = 'INFO',
  onCampaignCreated,
}: BeemCampaignComposerProps) {
  // Preset & basics
  const [selectedPresetId, setSelectedPresetId] = useState<SmsCampaignType>('christmas')
  const [campaignName, setCampaignName] = useState('Xmas Holiday Greetings & Promo')
  const [senderId, setSenderId] = useState(defaultSenderId)

  // Message & language
  const [languageMode, setLanguageMode] = useState<'sw' | 'en'>('sw')
  const [messageSw, setMessageSw] = useState(CAMPAIGN_PRESETS[0].templateSw)
  const [messageEn, setMessageEn] = useState(CAMPAIGN_PRESETS[0].templateEn)

  // Audience
  const [audienceKind, setAudienceKind] = useState<SmsCampaignAudienceKind>('all')
  const [selectedCategory, setSelectedCategory] = useState('retail')
  const [selectedPlanTier, setSelectedPlanTier] = useState<PlanTier>('starter')
  const [selectedBusinesses, setSelectedBusinesses] = useState<Map<string, string>>(new Map())
  const [customNumbersInput, setCustomNumbersInput] = useState('')
  const [bizSearchQuery, setBizSearchQuery] = useState('')

  // Scheduling
  const [sendMode, setSendMode] = useState<'immediate' | 'scheduled'>('immediate')
  const [scheduledDateTime, setScheduledDateTime] = useState('')

  // Estimation & state
  const [estimating, setEstimating] = useState(false)
  const [recipientCount, setRecipientCount] = useState<number>(0)
  const [estimatedCredits, setEstimatedCredits] = useState<number>(0)
  const [smsParts, setSmsParts] = useState<number>(1)
  const [confirmOpen, setConfirmOpen] = useState(false)
  const [sending, setSending] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [successNotice, setSuccessNotice] = useState<string | null>(null)

  // Current active message text
  const currentMessage = languageMode === 'sw' ? messageSw : messageEn

  // When preset is clicked
  function applyPreset(preset: CampaignPreset) {
    setSelectedPresetId(preset.id)
    setCampaignName(preset.defaultName)
    setMessageSw(preset.templateSw)
    setMessageEn(preset.templateEn)
  }

  // Insert tag into active message
  function insertTag(tag: string) {
    if (languageMode === 'sw') {
      setMessageSw((prev) => prev + ` ${tag}`)
    } else {
      setMessageEn((prev) => prev + ` ${tag}`)
    }
  }

  // Construct audience object
  const currentAudience: SmsCampaignAudience = useMemo(() => {
    if (audienceKind === 'business_category') {
      const catObj = BUSINESS_CATEGORIES.find((c) => c.value === selectedCategory)
      return {
        kind: 'business_category',
        category: selectedCategory,
        categoryName: catObj?.label || selectedCategory,
      }
    }
    if (audienceKind === 'plan_tier') {
      return {
        kind: 'plan_tier',
        planTier: selectedPlanTier,
      }
    }
    if (audienceKind === 'selected_businesses') {
      return {
        kind: 'selected_businesses',
        businessIds: Array.from(selectedBusinesses.keys()),
        businessNames: Array.from(selectedBusinesses.values()),
      }
    }
    if (audienceKind === 'custom_numbers') {
      const nums = customNumbersInput
        .split(/[\n,;]+/)
        .map((s) => s.trim())
        .filter((s) => s.length > 0)
      return {
        kind: 'custom_numbers',
        customNumbers: nums,
      }
    }
    return { kind: 'all' }
  }, [
    audienceKind,
    selectedCategory,
    selectedPlanTier,
    selectedBusinesses,
    customNumbersInput,
  ])

  // Recipient estimation debounced
  useEffect(() => {
    let active = true
    async function runEstimate() {
      setEstimating(true)
      try {
        const res = await estimateSmsRecipients({
          audience: currentAudience,
          message: currentMessage,
        })
        if (active) {
          setRecipientCount(res.recipientCount)
          setSmsParts(res.smsParts)
          setEstimatedCredits(res.estimatedCredits)
        }
      } catch (err) {
        console.error('Estimate error:', err)
      } finally {
        if (active) setEstimating(false)
      }
    }

    const timer = setTimeout(runEstimate, 300)
    return () => {
      active = false
      clearTimeout(timer)
    }
  }, [currentAudience, currentMessage])

  // Filter businesses for picker
  const filteredBusinesses = useMemo(() => {
    const q = bizSearchQuery.trim().toLowerCase()
    if (!q) return businesses
    return businesses.filter(
      (b) =>
        b.name.toLowerCase().includes(q) ||
        b.ownerName.toLowerCase().includes(q) ||
        b.ownerPhone.includes(q)
    )
  }, [businesses, bizSearchQuery])

  function toggleBusiness(id: string, name: string) {
    setSelectedBusinesses((prev) => {
      const next = new Map(prev)
      if (next.has(id)) next.delete(id)
      else next.set(id, name)
      return next
    })
  }

  // Character calculation
  const charLength = currentMessage.length
  // eslint-disable-next-line no-control-regex
  const isUnicode = /[^\u0000-\u007F]/.test(currentMessage)
  const maxPerPart = isUnicode ? (charLength <= 70 ? 70 : 67) : charLength <= 160 ? 160 : 153

  const canSubmit =
    campaignName.trim().length > 0 &&
    currentMessage.trim().length > 0 &&
    recipientCount > 0 &&
    (sendMode === 'immediate' || (sendMode === 'scheduled' && scheduledDateTime.length > 0))

  async function handleDispatchCampaign() {
    setSending(true)
    setError(null)
    setSuccessNotice(null)

    try {
      const res = await createBeemCampaign({
        name: campaignName.trim(),
        campaignType: selectedPresetId,
        senderId: senderId.trim() || undefined,
        message: currentMessage.trim(),
        messageSw: messageSw.trim() || undefined,
        audience: currentAudience,
        isScheduled: sendMode === 'scheduled',
        // datetime-local has no zone; resolve it in the admin's browser zone.
        scheduledAt: sendMode === 'scheduled' ? new Date(scheduledDateTime).toISOString() : undefined,
      })

      setSuccessNotice(
        sendMode === 'scheduled'
          ? `Campaign scheduled successfully for ${res.recipientCount} recipients.`
          : `Campaign dispatched to ${res.recipientCount} recipients via Beem Africa!`
      )

      setConfirmOpen(false)
      onCampaignCreated()
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to dispatch campaign')
    } finally {
      setSending(false)
    }
  }

  return (
    <div className="rounded-lg border border-[var(--line)] bg-[var(--surface)] p-5 mb-8 shadow-xs">
      <div className="flex items-center justify-between pb-3 border-b border-[var(--line)] mb-5">
        <div>
          <h2 className="text-[15px] font-semibold text-[var(--ink)] flex items-center gap-2">
            <Sparkles className="h-4 w-4 text-[var(--accent)]" />
            Create SMS Campaign (Beem Africa)
          </h2>
          <p className="text-[12px] text-[var(--ink-muted)] mt-0.5">
            Send bulk holiday greetings, promotional offers, and automated notifications to your users.
          </p>
        </div>
      </div>

      {/* ── Campaign Presets (Christmas, New Year, Easter, etc.) ── */}
      <div className="mb-5">
        <label className="block text-[12px] font-semibold text-[var(--ink)] mb-2">
          Select Campaign Preset / Holiday
        </label>
        <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-7 gap-2">
          {CAMPAIGN_PRESETS.map((preset) => {
            const isSelected = selectedPresetId === preset.id
            return (
              <button
                key={preset.id}
                type="button"
                onClick={() => applyPreset(preset)}
                className={cn(
                  'flex flex-col items-start p-2.5 rounded-lg border text-left transition-all',
                  isSelected
                    ? 'border-[var(--accent)] bg-[var(--accent-soft)]/20 shadow-xs ring-1 ring-[var(--accent)]'
                    : 'border-[var(--line)] bg-[var(--canvas)] hover:border-[var(--ink-faint)]'
                )}
              >
                <span className="text-xl mb-1">{preset.icon}</span>
                <span className="text-[12px] font-semibold text-[var(--ink)] line-clamp-1">
                  {preset.title}
                </span>
                <span className="text-[10.5px] text-[var(--ink-muted)] line-clamp-1 mt-0.5">
                  {preset.subtitle}
                </span>
              </button>
            )
          })}
        </div>
      </div>

      <div className="grid gap-5 md:grid-cols-2">
        {/* Left: Campaign info & Audience */}
        <div className="space-y-4">
          <div>
            <label className="block text-[12px] font-medium text-[var(--ink-muted)] mb-1">
              Campaign Name
            </label>
            <input
              value={campaignName}
              onChange={(e) => setCampaignName(e.target.value)}
              placeholder="e.g. Christmas 2026 Promo Campaign"
              className="w-full rounded-md border border-[var(--line)] bg-[var(--canvas)] px-3 py-2 text-[13px] text-[var(--ink)] outline-none focus:border-[var(--accent)]"
            />
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="block text-[12px] font-medium text-[var(--ink-muted)] mb-1">
                Sender ID
              </label>
              <input
                value={senderId}
                onChange={(e) => setSenderId(e.target.value)}
                placeholder="e.g. INFO"
                className="w-full rounded-md border border-[var(--line)] bg-[var(--canvas)] px-3 py-2 text-[13px] text-[var(--ink)] outline-none focus:border-[var(--accent)]"
              />
            </div>
            <div>
              <label className="block text-[12px] font-medium text-[var(--ink-muted)] mb-1">
                Send Timing
              </label>
              <select
                value={sendMode}
                onChange={(e) => setSendMode(e.target.value as 'immediate' | 'scheduled')}
                className="w-full rounded-md border border-[var(--line)] bg-[var(--canvas)] px-3 py-2 text-[13px] text-[var(--ink)] outline-none focus:border-[var(--accent)]"
              >
                <option value="immediate">⚡ Send Immediately</option>
                <option value="scheduled">📅 Schedule for Later</option>
              </select>
            </div>
          </div>

          {sendMode === 'scheduled' && (
            <div>
              <label className="block text-[12px] font-medium text-[var(--ink-muted)] mb-1">
                Scheduled Date & Time (Local Time)
              </label>
              <input
                type="datetime-local"
                value={scheduledDateTime}
                onChange={(e) => setScheduledDateTime(e.target.value)}
                className="w-full rounded-md border border-[var(--line)] bg-[var(--canvas)] px-3 py-2 text-[13px] text-[var(--ink)] outline-none focus:border-[var(--accent)]"
              />
              <p className="text-[11px] text-[var(--ink-faint)] mt-1">
                e.g. Dec 25 at 08:00 AM for Christmas greetings. Sent automatically within ~5 minutes of this time.
              </p>
            </div>
          )}

          {/* Audience Filter Selection */}
          <div>
            <label className="block text-[12px] font-medium text-[var(--ink-muted)] mb-1">
              Target Audience
            </label>
            <div className="grid grid-cols-2 sm:grid-cols-3 gap-1.5 mb-3">
              {[
                { id: 'all', label: 'All Users' },
                { id: 'business_category', label: 'By Category' },
                { id: 'plan_tier', label: 'By Plan Tier' },
                { id: 'selected_businesses', label: 'Specific Businesses' },
                { id: 'custom_numbers', label: 'Custom Numbers' },
              ].map((item) => (
                <button
                  key={item.id}
                  type="button"
                  onClick={() => setAudienceKind(item.id as SmsCampaignAudienceKind)}
                  className={cn(
                    'px-2.5 py-1.5 rounded-md text-[11.5px] font-medium border text-center transition-colors',
                    audienceKind === item.id
                      ? 'border-[var(--accent)] bg-[var(--accent-soft)] text-[var(--accent)] font-semibold'
                      : 'border-[var(--line)] bg-[var(--canvas)] text-[var(--ink-muted)] hover:text-[var(--ink)]'
                  )}
                >
                  {item.label}
                </button>
              ))}
            </div>

            {/* Audience sub-selectors */}
            {audienceKind === 'business_category' && (
              <div>
                <label className="block text-[11px] text-[var(--ink-faint)] mb-1">
                  Select Business Category
                </label>
                <select
                  value={selectedCategory}
                  onChange={(e) => setSelectedCategory(e.target.value)}
                  className="w-full rounded-md border border-[var(--line)] bg-[var(--canvas)] px-3 py-2 text-[12.5px] text-[var(--ink)] outline-none"
                >
                  {BUSINESS_CATEGORIES.map((c) => (
                    <option key={c.value} value={c.value}>
                      {c.label}
                    </option>
                  ))}
                </select>
              </div>
            )}

            {audienceKind === 'plan_tier' && (
              <div>
                <label className="block text-[11px] text-[var(--ink-faint)] mb-1">
                  Select Subscription Tier
                </label>
                <select
                  value={selectedPlanTier}
                  onChange={(e) => setSelectedPlanTier(e.target.value as PlanTier)}
                  className="w-full rounded-md border border-[var(--line)] bg-[var(--canvas)] px-3 py-2 text-[12.5px] text-[var(--ink)] outline-none"
                >
                  {PLAN_TIERS.map((t) => (
                    <option key={t.value} value={t.value}>
                      {t.label}
                    </option>
                  ))}
                </select>
              </div>
            )}

            {audienceKind === 'custom_numbers' && (
              <div>
                <label className="block text-[11px] text-[var(--ink-faint)] mb-1">
                  Paste Phone Numbers (comma or newline separated)
                </label>
                <textarea
                  value={customNumbersInput}
                  onChange={(e) => setCustomNumbersInput(e.target.value)}
                  rows={3}
                  placeholder="0712345678, 255754000111, +255653520829..."
                  className="w-full rounded-md border border-[var(--line)] bg-[var(--canvas)] px-3 py-2 text-[12px] text-[var(--ink)] outline-none resize-none font-mono"
                />
              </div>
            )}

            {audienceKind === 'selected_businesses' && (
              <div className="rounded-md border border-[var(--line)] bg-[var(--canvas)]">
                <div className="flex items-center gap-2 border-b border-[var(--line)] px-3 py-2">
                  <Search className="h-3.5 w-3.5 text-[var(--ink-faint)] shrink-0" />
                  <input
                    value={bizSearchQuery}
                    onChange={(e) => setBizSearchQuery(e.target.value)}
                    placeholder="Search business name, owner, or phone…"
                    className="flex-1 bg-transparent text-[12px] text-[var(--ink)] outline-none placeholder:text-[var(--ink-faint)]"
                  />
                  {selectedBusinesses.size > 0 && (
                    <span className="text-[11px] text-[var(--accent)] font-medium shrink-0">
                      {selectedBusinesses.size} selected
                    </span>
                  )}
                </div>
                <div className="max-h-48 overflow-y-auto divide-y divide-[var(--line)]">
                  {filteredBusinesses.length === 0 ? (
                    <p className="px-3 py-4 text-center text-[11.5px] text-[var(--ink-faint)]">
                      No businesses found.
                    </p>
                  ) : (
                    filteredBusinesses.map((b) => (
                      <label
                        key={b.id}
                        className="flex items-center gap-2 px-3 py-2 hover:bg-[var(--hover-bg)] cursor-pointer"
                      >
                        <input
                          type="checkbox"
                          checked={selectedBusinesses.has(b.id)}
                          onChange={() => toggleBusiness(b.id, b.name)}
                          className="h-3.5 w-3.5 shrink-0 accent-[var(--accent)]"
                        />
                        <span className="min-w-0 flex-1">
                          <span className="block truncate text-[12px] font-medium text-[var(--ink)]">
                            {b.name}
                          </span>
                          <span className="block truncate text-[10.5px] text-[var(--ink-muted)]">
                            {b.ownerName} · {b.ownerPhone}
                          </span>
                        </span>
                      </label>
                    ))
                  )}
                </div>
              </div>
            )}
          </div>
        </div>

        {/* Right: Message Editor & Estimation */}
        <div className="space-y-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-1">
              <button
                type="button"
                onClick={() => setLanguageMode('sw')}
                className={cn(
                  'px-3 py-1 rounded text-[12px] font-medium transition-colors',
                  languageMode === 'sw'
                    ? 'bg-[var(--navy)] text-white'
                    : 'bg-[var(--canvas)] text-[var(--ink-muted)] border border-[var(--line)]'
                )}
              >
                Swahili (Kiswahili)
              </button>
              <button
                type="button"
                onClick={() => setLanguageMode('en')}
                className={cn(
                  'px-3 py-1 rounded text-[12px] font-medium transition-colors',
                  languageMode === 'en'
                    ? 'bg-[var(--navy)] text-white'
                    : 'bg-[var(--canvas)] text-[var(--ink-muted)] border border-[var(--line)]'
                )}
              >
                English
              </button>
            </div>

            <div className="flex items-center gap-1 text-[11px] text-[var(--ink-faint)]">
              <span>Insert tag:</span>
              <button
                type="button"
                onClick={() => insertTag('{name}')}
                className="px-1.5 py-0.5 rounded bg-[var(--canvas)] border border-[var(--line)] hover:bg-[var(--hover-bg)] text-[var(--ink)] font-mono"
              >
                {'{name}'}
              </button>
              <button
                type="button"
                onClick={() => insertTag('{businessName}')}
                className="px-1.5 py-0.5 rounded bg-[var(--canvas)] border border-[var(--line)] hover:bg-[var(--hover-bg)] text-[var(--ink)] font-mono"
              >
                {'{businessName}'}
              </button>
            </div>
          </div>

          <div>
            <textarea
              value={languageMode === 'sw' ? messageSw : messageEn}
              onChange={(e) => {
                if (languageMode === 'sw') setMessageSw(e.target.value)
                else setMessageEn(e.target.value)
              }}
              rows={6}
              placeholder="Write your SMS message here..."
              className="w-full rounded-md border border-[var(--line)] bg-[var(--canvas)] px-3.5 py-2.5 text-[13px] text-[var(--ink)] outline-none focus:border-[var(--accent)] font-sans resize-none"
            />
            <div className="flex items-center justify-between text-[11.5px] text-[var(--ink-faint)] mt-1.5">
              <span>
                {charLength} characters · {smsParts} SMS part{smsParts > 1 ? 's' : ''}{' '}
                {isUnicode && '(Unicode)'}
              </span>
              <span>Max {maxPerPart} chars/part</span>
            </div>
          </div>

          {/* Live Recipient & Cost Summary */}
          <div className="rounded-lg border border-[var(--line)] bg-[var(--canvas)] p-3.5 space-y-2">
            <div className="flex items-center justify-between text-[12.5px]">
              <span className="text-[var(--ink-muted)] flex items-center gap-1.5">
                <Users className="h-3.5 w-3.5 text-[var(--ink-faint)]" />
                Target Recipients:
              </span>
              <span className="font-semibold text-[var(--ink)]">
                {estimating ? 'Calculating…' : `${recipientCount.toLocaleString()} numbers`}
              </span>
            </div>
            <div className="flex items-center justify-between text-[12.5px]">
              <span className="text-[var(--ink-muted)] flex items-center gap-1.5">
                <Layers className="h-3.5 w-3.5 text-[var(--ink-faint)]" />
                Est. Beem Credits Required:
              </span>
              <span className="font-bold text-[var(--accent)] font-mono">
                {estimating ? 'Calculating…' : `${estimatedCredits.toLocaleString()} Credits`}
              </span>
            </div>
          </div>

          {error && (
            <div className="flex items-center gap-2 rounded-md border border-[var(--status-bad)] bg-[var(--status-bad-bg)] px-3 py-2 text-[12px] text-[var(--status-bad)]">
              <AlertCircle className="h-4 w-4 shrink-0" />
              <span>{error}</span>
            </div>
          )}

          {successNotice && (
            <div className="flex items-center gap-2 rounded-md border border-[var(--status-good)] bg-[var(--status-good-bg)] px-3 py-2 text-[12px] text-[var(--status-good)]">
              <Sparkles className="h-4 w-4 shrink-0" />
              <span>{successNotice}</span>
            </div>
          )}

          <div className="flex justify-end pt-2">
            <button
              type="button"
              onClick={() => setConfirmOpen(true)}
              disabled={!canSubmit || sending}
              className={cn(
                'inline-flex items-center gap-2 rounded-md px-5 py-2.5 text-[13px] font-medium text-white transition-all shadow-xs',
                canSubmit && !sending
                  ? 'bg-[var(--navy)] hover:opacity-90 cursor-pointer'
                  : 'bg-[var(--line)] text-[var(--ink-faint)] cursor-not-allowed'
              )}
            >
              {sendMode === 'scheduled' ? (
                <>
                  <Calendar className="h-4 w-4" />
                  Schedule Campaign
                </>
              ) : (
                <>
                  <Send className="h-4 w-4" />
                  {sending ? 'Sending Campaign…' : 'Send Campaign Now'}
                </>
              )}
            </button>
          </div>
        </div>
      </div>

      <ConfirmDialog
        open={confirmOpen}
        onClose={() => !sending && setConfirmOpen(false)}
        onConfirm={handleDispatchCampaign}
        loading={sending}
        variant={sendMode === 'immediate' ? 'warning' : undefined}
        title={
          sendMode === 'immediate'
            ? `Send "${campaignName}" now?`
            : `Schedule "${campaignName}"?`
        }
        description={`This will dispatch SMS via Beem Africa to ${recipientCount.toLocaleString()} recipients (approx ${estimatedCredits.toLocaleString()} credits). Once dispatched, it cannot be undone.`}
        confirmLabel={sendMode === 'immediate' ? 'Send Campaign' : 'Confirm Schedule'}
      />
    </div>
  )
}
