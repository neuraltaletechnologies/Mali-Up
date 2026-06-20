'use client'

import { useState, useCallback } from 'react'
import { PageHeader } from '@/components/ui/page-header'
import { DetailDrawer } from '@/components/ui/detail-drawer'
import { Skeleton } from '@/components/ui/skeleton'
import { fetchFlags, patchFlag } from '@/lib/admin-api'
import { useAdminFetch } from '@/hooks/use-admin-fetch'
import type { FeatureFlag } from '@/types'
import { cn } from '@/lib/utils'
import { ExternalLink, AlertCircle } from 'lucide-react'

function FlagRow({
  flag,
  onToggle,
  onRolloutChange,
}: {
  flag: FeatureFlag
  onToggle: (id: string, enabled: boolean) => Promise<void>
  onRolloutChange: (id: string, rolloutPercent: number) => Promise<void>
}) {
  const [enabled, setEnabled]   = useState(flag.enabled)
  const [rollout, setRollout]   = useState(flag.rolloutPercent)
  const [saving, setSaving]     = useState(false)
  const [showOverrides, setShowOverrides] = useState(false)

  async function handleToggle() {
    const next = !enabled
    setEnabled(next)
    setSaving(true)
    try { await onToggle(flag.id, next) } catch { setEnabled(!next) } finally { setSaving(false) }
  }

  async function handleRolloutCommit() {
    setSaving(true)
    try { await onRolloutChange(flag.id, rollout) } finally { setSaving(false) }
  }

  return (
    <>
      <div className="flex items-center gap-4 px-4 py-3.5 border-b border-[var(--line)] last:border-0 hover:bg-[var(--canvas)] transition-colors">
        <div className="flex-1 min-w-0">
          <div className="flex items-center gap-2">
            <span className="font-mono text-[13px] font-medium text-[var(--ink)]">{flag.name}</span>
            {saving && <span className="text-[10px] text-[var(--ink-faint)]">saving…</span>}
            {flag.overrides.length > 0 && (
              <button
                onClick={() => setShowOverrides(true)}
                className="text-[11px] text-[var(--accent)] hover:underline flex items-center gap-0.5"
              >
                {flag.overrides.length} override{flag.overrides.length > 1 ? 's' : ''}
                <ExternalLink className="h-2.5 w-2.5" />
              </button>
            )}
          </div>
          <div className="text-[12px] text-[var(--ink-muted)] mt-0.5">{flag.description}</div>
        </div>

        {enabled && rollout < 100 && (
          <div className="flex items-center gap-2 w-36">
            <input
              type="range"
              min={0}
              max={100}
              value={rollout}
              onChange={(e) => setRollout(Number(e.target.value))}
              onMouseUp={handleRolloutCommit}
              onTouchEnd={handleRolloutCommit}
              className="flex-1 h-1 accent-[var(--accent)]"
            />
            <span className="font-mono text-[12px] text-[var(--ink-muted)] w-8 text-right">{rollout}%</span>
          </div>
        )}
        {enabled && rollout === 100 && (
          <span className="text-[11px] font-mono text-[var(--ink-faint)]">100% rollout</span>
        )}

        <button
          onClick={handleToggle}
          disabled={saving}
          className={cn(
            'relative inline-flex h-5 w-9 shrink-0 cursor-pointer rounded-full transition-colors duration-200 disabled:opacity-60',
            enabled ? 'bg-[var(--accent)]' : 'bg-[var(--line)]'
          )}
        >
          <span
            className={cn(
              'inline-block h-4 w-4 rounded-full bg-white shadow-sm transition-transform duration-200 mt-0.5',
              enabled ? 'translate-x-4' : 'translate-x-0.5'
            )}
          />
        </button>
      </div>

      <DetailDrawer
        open={showOverrides}
        onClose={() => setShowOverrides(false)}
        title={`Overrides — ${flag.name}`}
        description={`${flag.overrides.length} specific user/business exceptions`}
      >
        <div className="flex flex-col gap-2">
          {flag.overrides.map((override) => (
            <div key={override.id} className="flex items-center justify-between rounded-lg border border-[var(--line)] bg-[var(--canvas)] px-3 py-2.5">
              <div>
                <div className="text-[13px] font-medium text-[var(--ink)]">{override.label}</div>
                <div className="text-[11px] text-[var(--ink-faint)]">{override.type}</div>
              </div>
              <span className={cn('text-[11px] font-medium', override.enabled ? 'text-[var(--status-good)]' : 'text-[var(--status-bad)]')}>
                {override.enabled ? 'Enabled' : 'Disabled'}
              </span>
            </div>
          ))}
        </div>
      </DetailDrawer>
    </>
  )
}

export default function FeaturesPage() {
  const { data, loading, error } = useAdminFetch(useCallback(() => fetchFlags(), []))

  async function handleToggle(id: string, enabled: boolean) {
    await patchFlag(id, { enabled })
  }

  async function handleRolloutChange(id: string, rolloutPercent: number) {
    await patchFlag(id, { rolloutPercent })
  }

  if (loading) {
    return (
      <div>
        <PageHeader title="Feature Flags" description="Loading…" />
        <div className="rounded-lg border border-[var(--line)] overflow-hidden">
          {Array.from({ length: 5 }).map((_, i) => <Skeleton key={i} className="h-14 w-full border-b border-[var(--line)]" />)}
        </div>
      </div>
    )
  }

  if (error) {
    return (
      <div>
        <PageHeader title="Feature Flags" description="Failed to load" />
        <div className="mt-8 flex items-center gap-3 rounded-lg border border-[var(--status-bad)] bg-[var(--status-bad-bg)] p-4 text-[var(--status-bad)]">
          <AlertCircle className="h-4 w-4 shrink-0" />
          <span className="text-[13px]">{error}</span>
        </div>
      </div>
    )
  }

  const flags = data?.flags ?? []
  const enabledCount = flags.filter((f) => f.enabled).length

  return (
    <div>
      <PageHeader
        title="Feature Flags"
        description={flags.length === 0
          ? 'No flags defined yet'
          : `${enabledCount} of ${flags.length} flags enabled`}
      />

      <div className="rounded-lg border border-[var(--line)] bg-[var(--surface)] overflow-hidden">
        {flags.length === 0 ? (
          <div className="text-center py-12 text-[13px] text-[var(--ink-faint)]">
            No feature flags defined yet.
            <p className="mt-1 text-[12px]">Add documents to the <span className="font-mono">platform_feature_flags</span> Firestore collection to get started.</p>
          </div>
        ) : (
          flags.map((flag) => (
            <FlagRow
              key={flag.id}
              flag={flag}
              onToggle={handleToggle}
              onRolloutChange={handleRolloutChange}
            />
          ))
        )}
      </div>
    </div>
  )
}
