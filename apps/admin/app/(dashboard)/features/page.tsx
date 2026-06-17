'use client'

import { useState } from 'react'
import { PageHeader } from '@/components/ui/page-header'
import { DetailDrawer } from '@/components/ui/detail-drawer'
import { mockFlags } from '@/lib/mock-data'
import type { FeatureFlag } from '@/types'
import { cn } from '@/lib/utils'
import { ExternalLink } from 'lucide-react'

function FlagRow({ flag }: { flag: FeatureFlag }) {
  const [enabled, setEnabled] = useState(flag.enabled)
  const [rollout, setRollout] = useState(flag.rolloutPercent)
  const [showOverrides, setShowOverrides] = useState(false)

  return (
    <>
      <div className="flex items-center gap-4 px-4 py-3.5 border-b border-[var(--line)] last:border-0 hover:bg-[var(--canvas)] transition-colors">
        <div className="flex-1 min-w-0">
          <div className="flex items-center gap-2">
            <span className="font-mono text-[13px] font-medium text-[var(--ink)]">{flag.name}</span>
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

        {/* Rollout */}
        {enabled && rollout < 100 && (
          <div className="flex items-center gap-2 w-36">
            <input
              type="range"
              min={0}
              max={100}
              value={rollout}
              onChange={(e) => setRollout(Number(e.target.value))}
              className="flex-1 h-1 accent-[var(--accent)]"
            />
            <span className="font-mono text-[12px] text-[var(--ink-muted)] w-8 text-right">{rollout}%</span>
          </div>
        )}
        {enabled && rollout === 100 && (
          <span className="text-[11px] font-mono text-[var(--ink-faint)]">100% rollout</span>
        )}

        {/* Toggle */}
        <button
          onClick={() => setEnabled(!enabled)}
          className={cn(
            'relative inline-flex h-5 w-9 shrink-0 cursor-pointer rounded-full transition-colors duration-200',
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
              <span className={cn(
                'text-[11px] font-medium',
                override.enabled ? 'text-[var(--status-good)]' : 'text-[var(--status-bad)]'
              )}>
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
  const enabled = mockFlags.filter((f) => f.enabled).length

  return (
    <div>
      <PageHeader
        title="Feature Flags"
        description={`${enabled} of ${mockFlags.length} flags enabled`}
      />

      <div className="rounded-lg border border-[var(--line)] bg-[var(--surface)] overflow-hidden">
        {mockFlags.map((flag) => (
          <FlagRow key={flag.id} flag={flag} />
        ))}
      </div>
    </div>
  )
}
