'use client'

import { useState } from 'react'
import { PageHeader } from '@/components/ui/page-header'
import { mockConfig } from '@/lib/mock-data'
import { formatTZS } from '@/lib/format'
import { cn } from '@/lib/utils'
import { ChevronDown, ChevronRight, Save } from 'lucide-react'

function ConfigSection({
  title,
  defaultOpen = false,
  children,
}: {
  title: string
  defaultOpen?: boolean
  children: React.ReactNode
}) {
  const [open, setOpen] = useState(defaultOpen)
  return (
    <div className="rounded-lg border border-[var(--line)] overflow-hidden">
      <button
        onClick={() => setOpen(!open)}
        className="w-full flex items-center justify-between px-5 py-4 text-left hover:bg-[var(--canvas)] transition-colors"
      >
        <span className="text-[14px] font-semibold text-[var(--ink)]">{title}</span>
        {open ? <ChevronDown className="h-4 w-4 text-[var(--ink-faint)]" /> : <ChevronRight className="h-4 w-4 text-[var(--ink-faint)]" />}
      </button>
      {open && <div className="border-t border-[var(--line)] bg-[var(--surface)] px-5 py-5">{children}</div>}
    </div>
  )
}

function Field({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <div className="flex items-center gap-4 py-2.5 border-b border-[var(--line)] last:border-0">
      <label className="text-[13px] text-[var(--ink-muted)] w-64 shrink-0">{label}</label>
      <div className="flex-1">{children}</div>
    </div>
  )
}

function NumberInput({ value, suffix }: { value: number; suffix?: string }) {
  const [v, setV] = useState(value)
  return (
    <div className="inline-flex items-center gap-2">
      <input
        type="number"
        value={v}
        onChange={(e) => setV(Number(e.target.value))}
        className="w-32 rounded-md border border-[var(--line)] bg-[var(--canvas)] px-3 py-1.5 text-[13px] font-mono text-[var(--ink)] focus:outline-none focus:ring-1 focus:ring-[var(--accent)]"
      />
      {suffix && <span className="text-[12px] text-[var(--ink-faint)]">{suffix}</span>}
    </div>
  )
}

function Toggle({ checked }: { checked: boolean }) {
  const [v, setV] = useState(checked)
  return (
    <button
      onClick={() => setV(!v)}
      className={cn(
        'relative inline-flex h-5 w-9 shrink-0 cursor-pointer rounded-full transition-colors duration-200',
        v ? 'bg-[var(--accent)]' : 'bg-[var(--line)]'
      )}
    >
      <span className={cn(
        'inline-block h-4 w-4 rounded-full bg-white shadow-sm transition-transform duration-200 mt-0.5',
        v ? 'translate-x-4' : 'translate-x-0.5'
      )} />
    </button>
  )
}

export default function ConfigPage() {
  const [dirty, setDirty] = useState(false)
  const config = mockConfig

  return (
    <div onKeyDown={() => setDirty(true)} onClick={() => {}}>
      <PageHeader
        title="Platform Config"
        description="Pricing, limits, VAT, lifetime program, and maintenance settings"
      />

      <div className="flex flex-col gap-4 mb-24">
        {/* Pricing */}
        <ConfigSection title="Pricing" defaultOpen>
          <div className="divide-y divide-[var(--line)]">
            <Field label="Starter (free)"><span className="text-[13px] text-[var(--ink-faint)] font-mono">TZS 0</span></Field>
            <Field label="Growth (monthly)"><NumberInput value={config.pricing.growth} suffix="TZS/mo" /></Field>
            <Field label="Business (monthly)"><NumberInput value={config.pricing.business} suffix="TZS/mo" /></Field>
            <Field label="Enterprise (monthly)"><NumberInput value={config.pricing.enterprise} suffix="TZS/mo" /></Field>
            <Field label="Lifetime multiplier"><NumberInput value={config.pricing.lifetimeMultiplier} suffix="× monthly fee" /></Field>
            <Field label="SMS credit price"><NumberInput value={config.pricing.smsCreditPrice} suffix="TZS/credit" /></Field>
            <Field label="Export bundle price"><NumberInput value={config.pricing.exportBundlePrice} suffix="TZS" /></Field>
          </div>
        </ConfigSection>

        {/* Plan Limits */}
        <ConfigSection title="Plan Limits">
          <div className="divide-y divide-[var(--line)]">
            {Object.entries(config.planLimits).map(([plan, limits]) => (
              <Field key={plan} label={`${plan.charAt(0).toUpperCase() + plan.slice(1)} — max users`}>
                <NumberInput value={limits.users} suffix="users" />
              </Field>
            ))}
          </div>
        </ConfigSection>

        {/* Tax */}
        <ConfigSection title="Tax">
          <div className="divide-y divide-[var(--line)]">
            <Field label="VAT enabled"><Toggle checked={config.tax.vatEnabled} /></Field>
            <Field label="VAT rate"><NumberInput value={config.tax.vatRate} suffix="%" /></Field>
          </div>
        </ConfigSection>

        {/* Lifetime Program */}
        <ConfigSection title="Lifetime Program">
          <div className="divide-y divide-[var(--line)]">
            <Field label="UTT AMIS monthly return rate"><NumberInput value={config.lifetimeProgram.uttAMISMonthlyRate} suffix="% / month" /></Field>
            <Field label="Cancellation fees (Growth)">
              <div className="text-[12px] text-[var(--ink-muted)] font-mono space-y-1">
                {config.lifetimeProgram.cancellationFees.growth.map(([maxM, fee], i) => (
                  <div key={i}>≤{maxM === Infinity ? '∞' : maxM} months: {formatTZS(fee)}</div>
                ))}
              </div>
            </Field>
            <Field label="Cancellation fees (Business)">
              <div className="text-[12px] text-[var(--ink-muted)] font-mono space-y-1">
                {config.lifetimeProgram.cancellationFees.business.map(([maxM, fee], i) => (
                  <div key={i}>≤{maxM === Infinity ? '∞' : maxM} months: {formatTZS(fee)}</div>
                ))}
              </div>
            </Field>
          </div>
        </ConfigSection>

        {/* Platform */}
        <ConfigSection title="Platform">
          <div className="divide-y divide-[var(--line)]">
            <Field label="Maintenance mode"><Toggle checked={config.platform.maintenanceMode} /></Field>
            <Field label="Maintenance banner text">
              <input
                defaultValue={config.platform.maintenanceBanner}
                placeholder="Message shown to users during maintenance…"
                className="w-full rounded-md border border-[var(--line)] bg-[var(--canvas)] px-3 py-1.5 text-[13px] text-[var(--ink)] focus:outline-none focus:ring-1 focus:ring-[var(--accent)]"
                onChange={() => setDirty(true)}
              />
            </Field>
          </div>
        </ConfigSection>
      </div>

      {/* Sticky save bar */}
      {dirty && (
        <div className="fixed bottom-0 left-[240px] right-0 z-20 border-t border-[var(--line)] bg-[var(--surface)] px-8 py-3 flex items-center justify-between shadow-lg">
          <span className="text-[13px] text-[var(--ink-muted)]">You have unsaved changes</span>
          <div className="flex gap-2">
            <button
              onClick={() => setDirty(false)}
              className="rounded-md border border-[var(--line)] px-4 py-1.5 text-[12px] font-medium text-[var(--ink-muted)] hover:text-[var(--ink)]"
            >
              Discard
            </button>
            <button
              onClick={() => setDirty(false)}
              className="inline-flex items-center gap-1.5 rounded-md bg-[var(--navy)] px-4 py-1.5 text-[12px] font-medium text-white hover:bg-[var(--navy-soft)] transition-colors"
            >
              <Save className="h-3.5 w-3.5" />
              Save changes
            </button>
          </div>
        </div>
      )}
    </div>
  )
}
