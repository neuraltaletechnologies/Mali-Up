'use client'

import { useCallback, useState } from 'react'
import { CalendarClock, Pencil, Plus, Trash2, AlertCircle } from 'lucide-react'
import { PageHeader } from '@/components/ui/page-header'
import { Toggle } from '@/components/ui/toggle'
import { ConfirmDialog } from '@/components/ui/confirm-dialog'
import { SkeletonTable } from '@/components/ui/skeleton'
import { useAdminFetch } from '@/hooks/use-admin-fetch'
import {
  createBeemAutoCampaign,
  deleteBeemAutoCampaign,
  fetchBeemAutoCampaigns,
  updateBeemAutoCampaign,
} from '@/lib/admin-api'
import { cn } from '@/lib/utils'
import { CAMPAIGN_PRESETS } from './campaign-presets'
import type { BeemAutoCampaign, BeemAutoCampaignInput, PlanTier, SmsCampaignType } from '@/types'

const MONTHS = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']
const PLAN_TIERS: PlanTier[] = ['starter', 'growth', 'business', 'enterprise', 'lifetime']

/** One-click starting points. Fixed-date holidays only — Eid moves every
 * year, so it's added with "Custom date" and re-dated each year. */
const QUICK_ADD: { type: SmsCampaignType; month: number; day: number }[] = [
  { type: 'christmas', month: 12, day: 25 },
  { type: 'new_year', month: 1, day: 1 },
]

function blankRule(type: SmsCampaignType = 'custom', month = 1, day = 1): BeemAutoCampaignInput {
  const preset = CAMPAIGN_PRESETS.find((p) => p.id === type) ?? CAMPAIGN_PRESETS[CAMPAIGN_PRESETS.length - 1]
  return {
    name: preset.defaultName,
    campaignType: type,
    enabled: true,
    month,
    day,
    hour: 9,
    message: preset.templateSw,
    audience: { kind: 'all' },
  }
}

/** Same rule as calculateSmsParts in lib/beem.ts (server-only module). */
function calculateSmsParts(text: string) {
  const chars = text.length
  // eslint-disable-next-line no-control-regex
  const isUnicode = /[^\u0000-\u007F]/.test(text)
  const single = isUnicode ? 70 : 160
  const multi = isUnicode ? 67 : 153
  return { chars, isUnicode, parts: chars <= single ? 1 : Math.ceil(chars / multi) }
}

function whenLabel(r: { month: number; day: number; hour: number }) {
  return `${r.day} ${MONTHS[r.month - 1]} · ${String(r.hour).padStart(2, '0')}:00 EAT`
}

function audienceLabel(r: BeemAutoCampaign) {
  return r.audience.kind === 'plan_tier' ? `${r.audience.planTier} plan` : 'All users'
}

const inputCls =
  'w-full rounded-md border border-[var(--line)] bg-[var(--canvas)] px-3 py-2 text-[13px] text-[var(--ink)] outline-none focus:border-[var(--accent)]'
const labelCls = 'block text-[12px] font-medium text-[var(--ink-muted)] mb-1'

function RuleEditor({
  initial,
  saving,
  error,
  onCancel,
  onSave,
}: {
  initial: BeemAutoCampaignInput
  saving: boolean
  error: string | null
  onCancel: () => void
  onSave: (rule: BeemAutoCampaignInput) => void
}) {
  const [rule, setRule] = useState(initial)
  const set = <K extends keyof BeemAutoCampaignInput>(k: K, v: BeemAutoCampaignInput[K]) =>
    setRule((r) => ({ ...r, [k]: v }))
  const parts = calculateSmsParts(rule.message)

  return (
    <div className="rounded-lg border border-[var(--accent)] bg-[var(--surface)] p-4 mb-4 space-y-3">
      <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
        <div>
          <label className={labelCls}>Name</label>
          <input className={inputCls} value={rule.name} onChange={(e) => set('name', e.target.value)} />
        </div>
        <div>
          <label className={labelCls}>Audience</label>
          <select
            className={inputCls}
            value={rule.audience.kind === 'plan_tier' ? rule.audience.planTier : 'all'}
            onChange={(e) =>
              set(
                'audience',
                e.target.value === 'all' ? { kind: 'all' } : { kind: 'plan_tier', planTier: e.target.value as PlanTier }
              )
            }
          >
            <option value="all">All users</option>
            {PLAN_TIERS.map((t) => (
              <option key={t} value={t}>
                {t[0].toUpperCase() + t.slice(1)} plan only
              </option>
            ))}
          </select>
        </div>
      </div>

      <div className="grid grid-cols-3 gap-3">
        <div>
          <label className={labelCls}>Month</label>
          <select className={inputCls} value={rule.month} onChange={(e) => set('month', Number(e.target.value))}>
            {MONTHS.map((m, i) => (
              <option key={m} value={i + 1}>
                {m}
              </option>
            ))}
          </select>
        </div>
        <div>
          <label className={labelCls}>Day</label>
          <input
            type="number"
            min={1}
            max={31}
            className={inputCls}
            value={rule.day}
            onChange={(e) => set('day', Number(e.target.value))}
          />
        </div>
        <div>
          <label className={labelCls}>Hour (EAT)</label>
          <select className={inputCls} value={rule.hour} onChange={(e) => set('hour', Number(e.target.value))}>
            {Array.from({ length: 24 }, (_, h) => (
              <option key={h} value={h}>
                {String(h).padStart(2, '0')}:00
              </option>
            ))}
          </select>
        </div>
      </div>

      <div>
        <label className={labelCls}>Message</label>
        <textarea
          rows={4}
          className={inputCls}
          value={rule.message}
          onChange={(e) => set('message', e.target.value)}
        />
        <p className="text-[11px] text-[var(--ink-faint)] mt-1">
          {parts.chars} chars · {parts.parts} SMS part{parts.parts === 1 ? '' : 's'} per recipient
          {parts.isUnicode && ' · emoji/unicode detected (shorter parts)'} · Tags: {'{name}'}, {'{businessName}'}
        </p>
      </div>

      {error && (
        <div className="flex items-center gap-2 text-[12.5px] text-[var(--status-bad)]">
          <AlertCircle className="h-4 w-4 shrink-0" /> {error}
        </div>
      )}

      <div className="flex items-center justify-between">
        <label className="flex items-center gap-2 text-[12.5px] text-[var(--ink)]">
          <Toggle checked={rule.enabled} onChange={(v) => set('enabled', v)} /> Enabled
        </label>
        <div className="flex gap-2">
          <button
            type="button"
            onClick={onCancel}
            className="rounded-md border border-[var(--line)] px-3 py-1.5 text-[12.5px] text-[var(--ink-muted)]"
          >
            Cancel
          </button>
          <button
            type="button"
            disabled={saving || !rule.name.trim() || !rule.message.trim()}
            onClick={() => onSave(rule)}
            className="rounded-md bg-[var(--accent)] px-3 py-1.5 text-[12.5px] font-semibold text-white disabled:opacity-50"
          >
            {saving ? 'Saving…' : 'Save'}
          </button>
        </div>
      </div>
    </div>
  )
}

export function BeemAutoCampaigns() {
  const { data, loading, error: loadError, refetch } = useAdminFetch(
    useCallback(() => fetchBeemAutoCampaigns(), []),
    { key: 'beem-sms-auto-campaigns' }
  )
  const rules = data?.rules ?? []

  // `null` = closed, `'new'` = creating, otherwise the id being edited.
  const [editing, setEditing] = useState<string | null>(null)
  const [draft, setDraft] = useState<BeemAutoCampaignInput>(blankRule())
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [deleting, setDeleting] = useState<BeemAutoCampaign | null>(null)

  function openNew(type?: SmsCampaignType, month?: number, day?: number) {
    setDraft(blankRule(type, month, day))
    setEditing('new')
    setError(null)
  }

  function openEdit(r: BeemAutoCampaign) {
    const { id: _id, lastRunYear: _y, lastCampaignId: _c, updatedAt: _u, ...input } = r
    setDraft(input)
    setEditing(r.id)
    setError(null)
  }

  async function save(rule: BeemAutoCampaignInput) {
    setSaving(true)
    setError(null)
    try {
      if (editing === 'new') await createBeemAutoCampaign(rule)
      else if (editing) await updateBeemAutoCampaign(editing, rule)
      setEditing(null)
      refetch()
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to save')
    } finally {
      setSaving(false)
    }
  }

  async function toggle(r: BeemAutoCampaign, enabled: boolean) {
    try {
      await updateBeemAutoCampaign(r.id, { enabled })
      refetch()
    } catch (err) {
      console.error('Failed to toggle auto campaign:', err)
    }
  }

  const thisYear = new Date().getFullYear()

  return (
    <div className="mb-8">
      <PageHeader
        title="Automatic Holiday Campaigns"
        description="Yearly SMS that send themselves on the date — e.g. Christmas on 25 Dec and New Year on 1 Jan. Checked every 5 minutes (Tanzania time)."
      >
        {QUICK_ADD.filter((q) => !rules.some((r) => r.campaignType === q.type)).map((q) => {
          const preset = CAMPAIGN_PRESETS.find((p) => p.id === q.type)!
          return (
            <button
              key={q.type}
              type="button"
              onClick={() => openNew(q.type, q.month, q.day)}
              className="rounded-md border border-[var(--line)] bg-[var(--surface)] px-2.5 py-1.5 text-[12px] text-[var(--ink)] hover:border-[var(--accent)]"
            >
              {preset.icon} Add {preset.title.split(' (')[0]}
            </button>
          )
        })}
        <button
          type="button"
          onClick={() => openNew()}
          className="inline-flex items-center gap-1 rounded-md bg-[var(--accent)] px-2.5 py-1.5 text-[12px] font-semibold text-white"
        >
          <Plus className="h-3.5 w-3.5" /> Custom date
        </button>
      </PageHeader>

      {editing && (
        <RuleEditor
          key={editing}
          initial={draft}
          saving={saving}
          error={error}
          onCancel={() => setEditing(null)}
          onSave={save}
        />
      )}

      {loading ? (
        <SkeletonTable rows={2} cols={4} />
      ) : loadError && !data ? (
        <div className="flex items-center gap-3 rounded-lg border border-[var(--status-bad)] bg-[var(--status-bad-bg)] p-4 text-[var(--status-bad)]">
          <AlertCircle className="h-4 w-4 shrink-0" />
          <span className="text-[13px]">{loadError}</span>
        </div>
      ) : rules.length === 0 ? (
        <div className="rounded-lg border border-dashed border-[var(--line)] p-6 text-center text-[12.5px] text-[var(--ink-faint)]">
          No automatic campaigns yet. Add Christmas or New Year above and they&apos;ll go out every year on their own.
        </div>
      ) : (
        <div className="divide-y divide-[var(--line)] rounded-lg border border-[var(--line)] bg-[var(--surface)]">
          {rules.map((r) => {
            const preset = CAMPAIGN_PRESETS.find((p) => p.id === r.campaignType)
            return (
              <div key={r.id} className="flex flex-col sm:flex-row sm:items-center gap-3 p-3">
                <div className="flex items-start gap-3 min-w-0 flex-1">
                  <div className="flex h-9 w-9 shrink-0 items-center justify-center rounded-lg bg-[var(--accent-soft)] text-[16px]">
                    {preset?.icon ?? <CalendarClock className="h-4 w-4 text-[var(--accent)]" />}
                  </div>
                  <div className="min-w-0">
                    <div className="text-[13px] font-semibold text-[var(--ink)] truncate">{r.name}</div>
                    <div className="text-[11.5px] text-[var(--ink-muted)]">
                      {whenLabel(r)} · {audienceLabel(r)}
                      {r.lastRunYear && (
                        <span className={cn('ml-1', r.lastRunYear === thisYear && 'text-[var(--status-good)]')}>
                          · last sent {r.lastRunYear}
                        </span>
                      )}
                    </div>
                    <div className="text-[11.5px] text-[var(--ink-faint)] truncate">{r.message}</div>
                  </div>
                </div>
                <div className="flex items-center gap-2 shrink-0">
                  <Toggle checked={r.enabled} onChange={(v) => toggle(r, v)} />
                  <button
                    type="button"
                    onClick={() => openEdit(r)}
                    className="rounded-md p-1.5 text-[var(--ink-muted)] hover:text-[var(--ink)]"
                    aria-label="Edit"
                  >
                    <Pencil className="h-3.5 w-3.5" />
                  </button>
                  <button
                    type="button"
                    onClick={() => setDeleting(r)}
                    className="rounded-md p-1.5 text-[var(--ink-muted)] hover:text-[var(--status-bad)]"
                    aria-label="Delete"
                  >
                    <Trash2 className="h-3.5 w-3.5" />
                  </button>
                </div>
              </div>
            )
          })}
        </div>
      )}

      <ConfirmDialog
        open={deleting !== null}
        onClose={() => setDeleting(null)}
        onConfirm={async () => {
          if (!deleting) return
          await deleteBeemAutoCampaign(deleting.id)
          setDeleting(null)
          refetch()
        }}
        title={`Delete "${deleting?.name ?? ''}"?`}
        description="It will stop sending every year. Campaigns it already sent stay in the history."
        confirmLabel="Delete"
        destructive
      />
    </div>
  )
}
