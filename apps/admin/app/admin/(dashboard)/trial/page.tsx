'use client'

import { useState, useCallback, useEffect, useMemo } from 'react'
import { PageHeader } from '@/components/ui/page-header'
import { SkeletonTable, RevalidatingBar } from '@/components/ui/skeleton'
import { Toggle } from '@/components/ui/toggle'
import { ConfirmDialog } from '@/components/ui/confirm-dialog'
import {
  fetchTrialConfig, saveTrialConfig, countTrialEligible, grantTrialToExisting,
} from '@/lib/admin-api'
import { useAdminFetch } from '@/hooks/use-admin-fetch'
import { Save, AlertCircle, Gift, Bell, MessageSquare } from 'lucide-react'
import {
  TRIAL_PLACEHOLDERS, fillTrialTemplate, formatTrialDate, type TrialConfig,
} from '@/lib/trial-config'

function Field({ label, hint, children }: { label: string; hint?: string; children: React.ReactNode }) {
  return (
    <div className="flex flex-col gap-2 py-2.5 border-b border-[var(--line)] last:border-0 md:flex-row md:items-start md:gap-4">
      <div className="md:w-64 shrink-0 md:pt-1.5">
        <label className="text-[13px] text-[var(--ink-muted)]">{label}</label>
        {hint && <p className="text-[11px] text-[var(--ink-faint)] mt-0.5">{hint}</p>}
      </div>
      <div className="flex-1 min-w-0">{children}</div>
    </div>
  )
}

const inputClass =
  'w-full rounded-md border border-[var(--line)] bg-[var(--canvas)] px-3 py-1.5 text-[13px] text-[var(--ink)] focus:outline-none focus:ring-1 focus:ring-[var(--accent)]'

function Section({ title, icon, hint, children }: {
  title: string; icon: React.ReactNode; hint?: string; children: React.ReactNode
}) {
  return (
    <div className="rounded-lg border border-[var(--line)] overflow-hidden mb-6">
      <div className="px-5 py-4 border-b border-[var(--line)] flex items-center gap-2">
        {icon}
        <div>
          <span className="text-[14px] font-semibold text-[var(--ink)]">{title}</span>
          {hint && <p className="text-[12px] text-[var(--ink-faint)] mt-0.5">{hint}</p>}
        </div>
      </div>
      <div className="bg-[var(--surface)] px-5 py-4">{children}</div>
    </div>
  )
}

function Preview({ text }: { text: string }) {
  return (
    <div className="mt-2 rounded-md border border-dashed border-[var(--line)] bg-[var(--canvas)] px-3 py-2 text-[12px] text-[var(--ink-muted)] whitespace-pre-wrap">
      <span className="text-[10px] uppercase tracking-wide text-[var(--ink-faint)] block mb-1">Preview</span>
      {text}
    </div>
  )
}

export default function TrialPage() {
  const { data: remote, loading, revalidating, error } = useAdminFetch(
    useCallback(() => fetchTrialConfig(), []),
    { key: 'trial-config' },
  )
  const [config, setConfig] = useState<TrialConfig | null>(null)
  const [dirty, setDirty] = useState(false)
  const [saving, setSaving] = useState(false)
  const [saveError, setSaveError] = useState('')

  const [eligible, setEligible] = useState<number | null>(null)
  const [confirmOpen, setConfirmOpen] = useState(false)
  const [granting, setGranting] = useState(false)
  const [grantResult, setGrantResult] = useState('')

  useEffect(() => { if (remote) setConfig(remote) }, [remote])
  useEffect(() => {
    countTrialEligible().then((r) => setEligible(r.eligible)).catch(() => setEligible(null))
  }, [])

  function update<K extends keyof TrialConfig>(key: K, value: TrialConfig[K]) {
    setConfig((c) => (c ? { ...c, [key]: value } : c))
    setDirty(true)
  }

  // Sample values for the previews: a trial starting today.
  const vars = useMemo<Record<string, string | number>>(() => {
    const empty: Record<string, string | number> = {}
    if (!config) return empty
    const end = new Date(Date.now() + config.days * 86400_000)
    return {
      name: 'Amina', businessName: 'Duka la Amina', days: config.days,
      daysLeft: config.days, endDate: formatTrialDate(end),
      priceMonthly: 'TZS 6,000', priceYearly: 'TZS 60,000', payUrl: config.payUrl,
    }
  }, [config])
  const reminderVars = useMemo(() => ({ ...vars, daysLeft: config?.reminderDaysBefore ?? 2 }), [vars, config])

  const smsText = config ? fillTrialTemplate(config.expirySms, vars) : ''
  const smsParts = smsText.length <= 160 ? 1 : Math.ceil(smsText.length / 153)

  async function handleSave() {
    if (!config) return
    setSaving(true)
    setSaveError('')
    try {
      await saveTrialConfig(config)
      setDirty(false)
    } catch (e) {
      setSaveError((e as Error).message ?? 'Failed to save')
    } finally {
      setSaving(false)
    }
  }

  async function handleGrant() {
    setGranting(true)
    try {
      const r = await grantTrialToExisting()
      setGrantResult(`Gifted the trial to ${r.granted} businesses — ends ${formatTrialDate(new Date(r.endsAt))}.`)
      setEligible(0)
      setConfirmOpen(false)
    } catch (e) {
      setGrantResult(`Failed: ${(e as Error).message}`)
    } finally {
      setGranting(false)
    }
  }

  return (
    <div>
      {revalidating && <RevalidatingBar />}
      {loading && <SkeletonTable rows={3} cols={2} />}
      {error && !config && (
        <div className="mt-4 mb-4 flex items-center gap-3 rounded-lg border border-[var(--status-bad)] bg-[var(--status-bad-bg)] p-4 text-[var(--status-bad)]">
          <AlertCircle className="h-4 w-4 shrink-0" />
          <span className="text-[13px]">{error}</span>
        </div>
      )}
      {config && (<>
        <PageHeader
          title="Free Trial"
          description="Every new business gets a paid plan free for a few days, then drops to Starter unless it pays. Edit the length and the three messages users receive."
        />

        <Section title="Trial settings" icon={<Gift className="h-4 w-4 text-[var(--accent)]" />}>
          <Field label="Give new businesses a trial" hint="Off: new signups start on Starter. Running trials are not affected.">
            <Toggle checked={config.enabled} onChange={(v) => update('enabled', v)} />
          </Field>
          <Field label="Trial length (days)">
            <input type="number" min={1} max={90} value={config.days}
              onChange={(e) => update('days', Number(e.target.value))} className={`${inputClass} max-w-[120px]`} />
          </Field>
          <Field label="Plan given">
            <select value={config.tier} onChange={(e) => update('tier', e.target.value as TrialConfig['tier'])}
              className={`${inputClass} max-w-[200px]`}>
              <option value="growth">Growth</option>
              <option value="business">Business</option>
            </select>
          </Field>
          <Field label="Payment link" hint="Used as {payUrl} in the push and SMS.">
            <input value={config.payUrl} onChange={(e) => update('payUrl', e.target.value)} className={inputClass} />
          </Field>
        </Section>

        <div className="rounded-lg border border-[var(--line)] bg-[var(--surface)] px-5 py-3 mb-6">
          <p className="text-[12px] text-[var(--ink-muted)] mb-1.5">Placeholders you can use in any message:</p>
          <div className="flex flex-wrap gap-1.5">
            {TRIAL_PLACEHOLDERS.map((p) => (
              <span key={p.key} title={p.label}
                className="rounded bg-[var(--canvas)] border border-[var(--line)] px-1.5 py-0.5 font-mono text-[11px] text-[var(--ink)]">
                {p.key}
              </span>
            ))}
          </div>
        </div>

        <Section title="1 · Welcome popup (in the app, on the dashboard)" icon={<Gift className="h-4 w-4 text-[var(--accent)]" />}
          hint="Shown once to the owner when the trial starts. The app also shows the end date and days left under the message.">
          <Field label="Title — Swahili">
            <input value={config.welcomeTitleSw} onChange={(e) => update('welcomeTitleSw', e.target.value)} className={inputClass} />
          </Field>
          <Field label="Message — Swahili">
            <textarea rows={3} value={config.welcomeBodySw} onChange={(e) => update('welcomeBodySw', e.target.value)} className={inputClass} />
            <Preview text={`${fillTrialTemplate(config.welcomeTitleSw, vars)}\n${fillTrialTemplate(config.welcomeBodySw, vars)}`} />
          </Field>
          <Field label="Title — English">
            <input value={config.welcomeTitleEn} onChange={(e) => update('welcomeTitleEn', e.target.value)} className={inputClass} />
          </Field>
          <Field label="Message — English">
            <textarea rows={3} value={config.welcomeBodyEn} onChange={(e) => update('welcomeBodyEn', e.target.value)} className={inputClass} />
          </Field>
        </Section>

        <Section title="2 · Reminder push notification" icon={<Bell className="h-4 w-4 text-[var(--accent)]" />}
          hint="Sent once, between 08:00 and 20:00 EAT, to every device on that business. Tapping it opens the plans screen.">
          <Field label="Days before the end">
            <input type="number" min={1} max={config.days} value={config.reminderDaysBefore}
              onChange={(e) => update('reminderDaysBefore', Number(e.target.value))} className={`${inputClass} max-w-[120px]`} />
          </Field>
          <Field label="Title — Swahili">
            <input value={config.reminderTitleSw} onChange={(e) => update('reminderTitleSw', e.target.value)} className={inputClass} />
          </Field>
          <Field label="Message — Swahili">
            <textarea rows={2} value={config.reminderBodySw} onChange={(e) => update('reminderBodySw', e.target.value)} className={inputClass} />
            <Preview text={`${fillTrialTemplate(config.reminderTitleSw, reminderVars)}\n${fillTrialTemplate(config.reminderBodySw, reminderVars)}`} />
          </Field>
          <Field label="Title — English">
            <input value={config.reminderTitleEn} onChange={(e) => update('reminderTitleEn', e.target.value)} className={inputClass} />
          </Field>
          <Field label="Message — English">
            <textarea rows={2} value={config.reminderBodyEn} onChange={(e) => update('reminderBodyEn', e.target.value)} className={inputClass} />
          </Field>
        </Section>

        <Section title="3 · End-date SMS with payment directions" icon={<MessageSquare className="h-4 w-4 text-[var(--accent)]" />}
          hint="Sent by Beem to the owner's phone on the day the trial ends (08:00–20:00 EAT), only if they haven't paid.">
          <Field label="SMS text">
            <textarea rows={5} value={config.expirySms} onChange={(e) => update('expirySms', e.target.value)} className={inputClass} />
            <Preview text={smsText} />
            <p className={`mt-1 text-[11px] ${smsParts > 3 ? 'text-[var(--status-bad)]' : 'text-[var(--ink-faint)]'}`}>
              ~{smsText.length} characters · {smsParts} SMS part{smsParts === 1 ? '' : 's'} per user
            </p>
          </Field>
        </Section>

        <Section title="Existing users" icon={<Gift className="h-4 w-4 text-[var(--accent)]" />}
          hint="Businesses that signed up before the trial existed. Gift them the same trial once; they see the welcome popup next time they open the app.">
          <div className="flex flex-wrap items-center gap-3">
            <span className="text-[13px] text-[var(--ink)]">
              {eligible === null ? 'Counting…' : `${eligible} free businesses haven't had a trial yet.`}
            </span>
            <button
              onClick={() => setConfirmOpen(true)}
              disabled={!eligible || dirty}
              className="inline-flex items-center gap-1.5 rounded-md bg-[var(--navy)] px-4 py-1.5 text-[12px] font-medium text-white hover:bg-[var(--navy-soft)] disabled:opacity-50"
            >
              <Gift className="h-3.5 w-3.5" /> Gift {config.days}-day trial
            </button>
            {dirty && <span className="text-[11px] text-[var(--ink-faint)]">Save your changes first.</span>}
          </div>
          {grantResult && <p className="mt-2 text-[12px] text-[var(--ink-muted)]">{grantResult}</p>}
        </Section>

        <div className="h-20" />

        <ConfirmDialog
          open={confirmOpen}
          onClose={() => setConfirmOpen(false)}
          onConfirm={handleGrant}
          loading={granting}
          variant="warning"
          title={`Gift ${config.days} days of ${config.tier === 'growth' ? 'Growth' : 'Business'} to ${eligible ?? 0} businesses?`}
          description={`Their plan switches to the trial now and ends on ${formatTrialDate(new Date(Date.now() + config.days * 86400_000))}. They'll get the reminder push and the end-date SMS. This can't be undone in bulk.`}
          confirmLabel="Gift trial"
        />

        {dirty && (
          <div className="fixed bottom-0 left-0 md:left-[240px] right-0 z-20 border-t border-[var(--line)] bg-[var(--surface)] px-4 md:px-8 py-3 flex items-center justify-between shadow-lg">
            <div className="flex items-center gap-3">
              <span className="text-[13px] text-[var(--ink-muted)]">You have unsaved changes</span>
              {saveError && <span className="text-[12px] text-[var(--status-bad)]">{saveError}</span>}
            </div>
            <div className="flex gap-2">
              <button
                onClick={() => { setConfig(remote!); setDirty(false); setSaveError('') }}
                disabled={saving}
                className="rounded-md border border-[var(--line)] px-4 py-1.5 text-[12px] font-medium text-[var(--ink-muted)] hover:text-[var(--ink)]"
              >
                Discard
              </button>
              <button
                onClick={handleSave}
                disabled={saving}
                className="inline-flex items-center gap-1.5 rounded-md bg-[var(--navy)] px-4 py-1.5 text-[12px] font-medium text-white hover:bg-[var(--navy-soft)] disabled:opacity-50"
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
