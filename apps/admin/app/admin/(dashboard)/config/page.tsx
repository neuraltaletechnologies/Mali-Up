'use client'

import { useState, useCallback, useEffect } from 'react'
import { PageHeader } from '@/components/ui/page-header'
import { SkeletonTable, RevalidatingBar } from '@/components/ui/skeleton'
import { fetchConfig, saveConfig } from '@/lib/admin-api'
import { useAdminFetch } from '@/hooks/use-admin-fetch'
import { cn } from '@/lib/utils'
import { Save, AlertCircle } from 'lucide-react'
import type { PlatformConfig } from '@/types'

function Field({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <div className="flex items-center gap-4 py-2.5 border-b border-[var(--line)] last:border-0">
      <label className="text-[13px] text-[var(--ink-muted)] w-64 shrink-0">{label}</label>
      <div className="flex-1">{children}</div>
    </div>
  )
}

function Toggle({ checked, onChange }: { checked: boolean; onChange: (v: boolean) => void }) {
  return (
    <button
      type="button"
      onClick={() => onChange(!checked)}
      className={cn(
        'relative inline-flex h-5 w-9 shrink-0 cursor-pointer rounded-full transition-colors duration-200',
        checked ? 'bg-[var(--accent)]' : 'bg-[var(--line)]'
      )}
    >
      <span className={cn(
        'inline-block h-4 w-4 rounded-full bg-white shadow-sm transition-transform duration-200 mt-0.5',
        checked ? 'translate-x-4' : 'translate-x-0.5'
      )} />
    </button>
  )
}

export default function ConfigPage() {
  const { data: remoteConfig, loading, revalidating, error } = useAdminFetch(
    useCallback(() => fetchConfig(), []),
    { key: 'config' },
  )
  const [config, setConfig] = useState<PlatformConfig | null>(null)
  const [dirty, setDirty] = useState(false)
  const [saving, setSaving] = useState(false)
  const [saveError, setSaveError] = useState('')

  useEffect(() => {
    if (remoteConfig) setConfig(remoteConfig)
  }, [remoteConfig])

  function update<K extends keyof PlatformConfig>(section: K, patch: Partial<PlatformConfig[K]>) {
    setConfig((c) => c ? { ...c, [section]: { ...(c[section] as object), ...patch } } : c)
    setDirty(true)
  }

  async function handleSave() {
    if (!config) return
    setSaving(true)
    setSaveError('')
    try {
      await saveConfig(config)
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
      {loading && <SkeletonTable rows={2} cols={2} />}
      {error && !config && (
        <div className="mt-4 mb-4 flex items-center gap-3 rounded-lg border border-[var(--status-bad)] bg-[var(--status-bad-bg)] p-4 text-[var(--status-bad)]">
          <AlertCircle className="h-4 w-4 shrink-0" />
          <span className="text-[13px]">{error ?? 'Config unavailable'}</span>
        </div>
      )}
      {config && (<>
        <PageHeader
          title="Platform Config"
          description="Maintenance mode and platform-wide settings"
        />

        <div className="rounded-lg border border-[var(--line)] overflow-hidden mb-24">
          <div className="px-5 py-4 border-b border-[var(--line)]">
            <span className="text-[14px] font-semibold text-[var(--ink)]">Platform</span>
          </div>
          <div className="bg-[var(--surface)] px-5 py-5 divide-y divide-[var(--line)]">
            <Field label="Maintenance mode">
              <Toggle checked={config.platform.maintenanceMode}
                onChange={(v) => update('platform', { maintenanceMode: v })} />
            </Field>
            <Field label="Maintenance banner text">
              <input
                value={config.platform.maintenanceBanner}
                onChange={(e) => { update('platform', { maintenanceBanner: e.target.value }); setDirty(true) }}
                placeholder="Message shown to users during maintenance…"
                className="w-full rounded-md border border-[var(--line)] bg-[var(--canvas)] px-3 py-1.5 text-[13px] text-[var(--ink)] focus:outline-none focus:ring-1 focus:ring-[var(--accent)]"
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
