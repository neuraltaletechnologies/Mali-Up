'use client'

import { useState, useCallback, useEffect } from 'react'
import { PageHeader } from '@/components/ui/page-header'
import { SkeletonTable, RevalidatingBar } from '@/components/ui/skeleton'
import { fetchVersionGate, saveVersionGate } from '@/lib/admin-api'
import { useAdminFetch } from '@/hooks/use-admin-fetch'
import { Save, AlertCircle } from 'lucide-react'
import type { VersionGateConfig } from '@/types'

function Field({ label, hint, children }: { label: string; hint?: string; children: React.ReactNode }) {
  return (
    <div className="flex items-start gap-4 py-2.5 border-b border-[var(--line)] last:border-0">
      <div className="w-64 shrink-0 pt-1.5">
        <label className="text-[13px] text-[var(--ink-muted)]">{label}</label>
        {hint && <p className="text-[11px] text-[var(--ink-faint)] mt-0.5">{hint}</p>}
      </div>
      <div className="flex-1">{children}</div>
    </div>
  )
}

const inputClass =
  'w-full rounded-md border border-[var(--line)] bg-[var(--canvas)] px-3 py-1.5 text-[13px] text-[var(--ink)] focus:outline-none focus:ring-1 focus:ring-[var(--accent)]'

export default function VersionGatePage() {
  const { data: remoteConfig, loading, revalidating, error } = useAdminFetch(
    useCallback(() => fetchVersionGate(), []),
    { key: 'version-gate' },
  )
  const [config, setConfig] = useState<VersionGateConfig | null>(null)
  const [dirty, setDirty] = useState(false)
  const [saving, setSaving] = useState(false)
  const [saveError, setSaveError] = useState('')

  useEffect(() => {
    if (remoteConfig) setConfig(remoteConfig)
  }, [remoteConfig])

  function update<K extends keyof VersionGateConfig>(key: K, value: VersionGateConfig[K]) {
    setConfig((c) => (c ? { ...c, [key]: value } : c))
    setDirty(true)
  }

  async function handleSave() {
    if (!config) return
    setSaving(true)
    setSaveError('')
    try {
      await saveVersionGate(config)
      setDirty(false)
    } catch (e) {
      setSaveError((e as Error).message ?? 'Failed to save')
    } finally {
      setSaving(false)
    }
  }

  return (
    <div>
      {revalidating && <RevalidatingBar />}
      {loading && <SkeletonTable rows={3} cols={2} />}
      {error && !config && (
        <div className="mt-4 mb-4 flex items-center gap-3 rounded-lg border border-[var(--status-bad)] bg-[var(--status-bad-bg)] p-4 text-[var(--status-bad)]">
          <AlertCircle className="h-4 w-4 shrink-0" />
          <span className="text-[13px]">{error ?? 'Version gate config unavailable'}</span>
        </div>
      )}
      {config && (<>
        <PageHeader
          title="Version Gate"
          description="Block or nudge users on old app builds to update. Build numbers are the +N in the app's version (e.g. 1.1.0+2 → 2)."
        />

        <div className="rounded-lg border border-[var(--line)] overflow-hidden mb-24">
          <div className="px-5 py-4 border-b border-[var(--line)]">
            <span className="text-[14px] font-semibold text-[var(--ink)]">Build thresholds</span>
          </div>
          <div className="bg-[var(--surface)] px-5 py-5 divide-y divide-[var(--line)]">
            <Field label="Minimum supported build" hint="Below this, users are hard-blocked until they update.">
              <input
                type="number"
                min={1}
                value={config.minSupportedBuildNumber}
                onChange={(e) => update('minSupportedBuildNumber', Number(e.target.value))}
                className={inputClass}
              />
            </Field>
            <Field label="Recommended build" hint="Below this (but at/above minimum), users see a dismissible update banner.">
              <input
                type="number"
                min={1}
                value={config.recommendedBuildNumber}
                onChange={(e) => update('recommendedBuildNumber', Number(e.target.value))}
                className={inputClass}
              />
            </Field>
          </div>
        </div>

        <div className="rounded-lg border border-[var(--line)] overflow-hidden mb-24">
          <div className="px-5 py-4 border-b border-[var(--line)]">
            <span className="text-[14px] font-semibold text-[var(--ink)]">Store links</span>
          </div>
          <div className="bg-[var(--surface)] px-5 py-5 divide-y divide-[var(--line)]">
            <Field label="Android (Play Store) URL">
              <input
                value={config.updateUrlAndroid}
                onChange={(e) => update('updateUrlAndroid', e.target.value)}
                placeholder="https://play.google.com/store/apps/details?id=..."
                className={inputClass}
              />
            </Field>
            <Field label="iOS (App Store) URL">
              <input
                value={config.updateUrlIOS}
                onChange={(e) => update('updateUrlIOS', e.target.value)}
                placeholder="https://apps.apple.com/app/id..."
                className={inputClass}
              />
            </Field>
          </div>
        </div>

        <div className="rounded-lg border border-[var(--line)] overflow-hidden mb-24">
          <div className="px-5 py-4 border-b border-[var(--line)]">
            <span className="text-[14px] font-semibold text-[var(--ink)]">Message shown to users</span>
          </div>
          <div className="bg-[var(--surface)] px-5 py-5 divide-y divide-[var(--line)]">
            <Field label="English">
              <textarea
                value={config.messageEn}
                onChange={(e) => update('messageEn', e.target.value)}
                rows={2}
                placeholder="A new version of Mali Up is required to continue."
                className={inputClass}
              />
            </Field>
            <Field label="Swahili">
              <textarea
                value={config.messageSw}
                onChange={(e) => update('messageSw', e.target.value)}
                rows={2}
                placeholder="Toleo jipya la Mali Up linahitajika kuendelea."
                className={inputClass}
              />
            </Field>
          </div>
        </div>

        {/* Sticky save bar */}
        {dirty && (
          <div className="fixed bottom-0 left-[240px] right-0 z-20 border-t border-[var(--line)] bg-[var(--surface)] px-8 py-3 flex items-center justify-between shadow-lg">
            <div className="flex items-center gap-3">
              <span className="text-[13px] text-[var(--ink-muted)]">You have unsaved changes</span>
              {saveError && <span className="text-[12px] text-[var(--status-bad)]">{saveError}</span>}
            </div>
            <div className="flex gap-2">
              <button
                onClick={() => { setConfig(remoteConfig!); setDirty(false); setSaveError('') }}
                disabled={saving}
                className="rounded-md border border-[var(--line)] px-4 py-1.5 text-[12px] font-medium text-[var(--ink-muted)] hover:text-[var(--ink)]"
              >
                Discard
              </button>
              <button
                onClick={handleSave}
                disabled={saving}
                className="inline-flex items-center gap-1.5 rounded-md bg-[var(--navy)] px-4 py-1.5 text-[12px] font-medium text-white hover:bg-[var(--navy-soft)] transition-colors disabled:opacity-50"
              >
                <Save className="h-3.5 w-3.5" />
                {saving ? 'Saving…' : 'Save changes'}
              </button>
            </div>
          </div>
        )}
      </>)}
    </div>
  )
}
