'use client'

import { useState, useCallback, useEffect, useMemo } from 'react'
import { PageHeader } from '@/components/ui/page-header'
import { KPICard } from '@/components/ui/kpi-card'
import { MRRTrendChart } from '@/components/charts/mrr-trend-chart'
import { FreeVsPaidChart } from '@/components/charts/free-vs-paid-chart'
import { KPIRowSkeleton, ChartSkeleton, RevalidatingBar, SkeletonTable } from '@/components/ui/skeleton'
import { StatusDot } from '@/components/ui/status-dot'
import { fetchAnalytics, fetchConfig, saveConfig, fetchPlans } from '@/lib/admin-api'
import { useAdminFetch } from '@/hooks/use-admin-fetch'
import { formatTZS, formatTZSCompact, formatPhone, formatDate } from '@/lib/format'
import { cn } from '@/lib/utils'
import { AlertCircle, ChevronDown, ChevronRight, Save } from 'lucide-react'
import type { PlatformConfig } from '@/types'

const INF_SENTINEL = 9999

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
        type="button"
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

function NumberInput({
  value,
  suffix,
  onChange,
}: {
  value: number
  suffix?: string
  onChange: (v: number) => void
}) {
  return (
    <div className="inline-flex items-center gap-2">
      <input
        type="number"
        value={value}
        onChange={(e) => onChange(Number(e.target.value))}
        className="w-32 rounded-md border border-[var(--line)] bg-[var(--canvas)] px-3 py-1.5 text-[13px] font-mono text-[var(--ink)] focus:outline-none focus:ring-1 focus:ring-[var(--accent)]"
      />
      {suffix && <span className="text-[12px] text-[var(--ink-faint)]">{suffix}</span>}
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

export default function RevenuePage() {
  const { data, loading: analyticsLoading, revalidating, error: analyticsError } = useAdminFetch(
    () => fetchAnalytics(),
    { key: 'analytics' },
  )

  const { data: remoteConfig, loading: configLoading, error: configError } = useAdminFetch(
    useCallback(() => fetchConfig(), []),
    { key: 'config' },
  )

  // Live per-tier pricing — sourced from the Plans page's data, not a hardcoded copy.
  const { data: plansData } = useAdminFetch(useCallback(() => fetchPlans(), []), { key: 'plans' })
  const planFees = useMemo(() => {
    const fees: Record<string, number> = {}
    if (plansData?.plans) {
      for (const [tier, def] of Object.entries(plansData.plans)) {
        fees[tier] = def.cycleMonths > 0 ? Math.round(def.pricePerCycle / def.cycleMonths) : 0
      }
    }
    return fees
  }, [plansData])

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

  // Real ClickPesa revenue breakdown — actual completed transactions, not a
  // plan-count × price estimate.
  const revenueByTier = data?.clickPesaRevenueByTier ?? []
  const maxTierRevenue = Math.max(...revenueByTier.map((t) => t.value), 1)
  const totalClickPesaAttempts =
    (data?.clickPesaSuccessCount ?? 0) + (data?.clickPesaFailedCount ?? 0)
  const clickPesaSuccessRate = totalClickPesaAttempts > 0
    ? Math.round(((data?.clickPesaSuccessCount ?? 0) / totalClickPesaAttempts) * 100)
    : null

  // Free (Starter/Trial) vs paid — how much of the base is still to be converted
  const totalBusinesses = data?.totalBusinesses ?? 0
  const freeCount = (data?.planDistribution ?? []).find((p) => p.name.toLowerCase() === 'starter')?.value ?? 0
  const paidCount = Math.max(totalBusinesses - freeCount, 0)
  const freePct = totalBusinesses > 0 ? Math.round((freeCount / totalBusinesses) * 100) : 0
  const paidPct = totalBusinesses > 0 ? 100 - freePct : 0

  return (
    <div>
      <PageHeader
        title="Revenue"
        description="Real ClickPesa transactions and platform-wide billing settings"
      />
      {revalidating && <RevalidatingBar />}

      {/* ── Analytics ── */}
      {analyticsLoading ? (
        <>
          <KPIRowSkeleton count={4} />
          <div className="grid grid-cols-1 lg:grid-cols-5 gap-4">
            <div className="lg:col-span-3"><ChartSkeleton height="h-72" /></div>
            <div className="lg:col-span-2"><ChartSkeleton height="h-72" /></div>
          </div>
        </>
      ) : analyticsError && !data ? (
        <div className="mt-4 flex items-center gap-3 rounded-lg border border-[var(--status-bad)] bg-[var(--status-bad-bg)] p-4 text-[var(--status-bad)]">
          <AlertCircle className="h-4 w-4 shrink-0" />
          <span className="text-[13px]">{analyticsError}</span>
        </div>
      ) : data && (
        <>
          {/* KPI row — real completed ClickPesa transactions, not a projection */}
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
            <KPICard
              label="ClickPesa Revenue (Month)"
              value={`TZS ${formatTZSCompact(data.clickPesaRevenueThisMonth)}`}
              deltaLabel="completed this calendar month"
            />
            <KPICard
              label="ClickPesa Revenue (All Time)"
              value={`TZS ${formatTZSCompact(data.clickPesaRevenueAllTime)}`}
            />
            <KPICard
              label="Successful Payments"
              value={data.clickPesaSuccessCount.toLocaleString()}
              mono={false}
            />
            <KPICard
              label="Success Rate"
              value={clickPesaSuccessRate !== null ? `${clickPesaSuccessRate}%` : '—'}
              deltaLabel={
                totalClickPesaAttempts > 0
                  ? `${data.clickPesaFailedCount} declined of ${totalClickPesaAttempts}`
                  : 'no attempts yet'
              }
            />
          </div>

          <div className="grid grid-cols-1 lg:grid-cols-5 gap-4">
            {/* ClickPesa revenue trend */}
            <div className="lg:col-span-3 rounded-lg border border-[var(--line)] bg-[var(--surface)] p-5">
              <h2 className="text-[14px] font-semibold text-[var(--ink)] mb-1">ClickPesa Revenue Trend</h2>
              <p className="text-[12px] text-[var(--ink-muted)] mb-4">Actual money collected per month, last 12 months</p>
              <MRRTrendChart data={data.clickPesaRevenueTrend} />
            </div>

            {/* Per-plan revenue breakdown — real completed payments, not price × count */}
            <div className="lg:col-span-2 rounded-lg border border-[var(--line)] bg-[var(--surface)] p-5">
              <h2 className="text-[14px] font-semibold text-[var(--ink)] mb-1">Revenue by Plan</h2>
              <p className="text-[12px] text-[var(--ink-muted)] mb-5">Completed ClickPesa payments, all time</p>

              {revenueByTier.length === 0 ? (
                <p className="text-[13px] text-[var(--ink-faint)] pt-4">No completed ClickPesa payments yet.</p>
              ) : (
                <div className="flex flex-col gap-4">
                  {revenueByTier.map(({ name, value, count, color }) => (
                    <div key={name} className="flex items-center gap-3">
                      <div className="w-24 shrink-0">
                        <div className="text-[12px] font-medium text-[var(--ink)]">{name}</div>
                        <div className="text-[11px] text-[var(--ink-faint)]">{count} payment{count === 1 ? '' : 's'}</div>
                      </div>
                      <div className="flex-1 h-6 rounded overflow-hidden bg-[var(--canvas)]">
                        <div
                          className="h-full rounded transition-all"
                          style={{
                            width: `${(value / maxTierRevenue) * 100}%`,
                            background: color,
                            opacity: 0.85,
                          }}
                        />
                      </div>
                      <span className="font-mono text-[12px] w-24 text-right shrink-0 text-[var(--ink)]">
                        TZS {formatTZSCompact(value)}
                      </span>
                    </div>
                  ))}

                  {/* Total */}
                  <div className="pt-3 border-t border-[var(--line)] flex items-center justify-between">
                    <span className="text-[12px] font-semibold text-[var(--ink)]">Total Collected</span>
                    <span className="font-mono text-[13px] font-semibold text-[var(--ink)]">
                      TZS {formatTZSCompact(data.clickPesaRevenueAllTime)}
                    </span>
                  </div>
                </div>
              )}
            </div>
          </div>

          {/* Recent ClickPesa transactions — real ledger, not an estimate */}
          <div className="mt-4 rounded-lg border border-[var(--line)] bg-[var(--surface)] p-5">
            <h2 className="text-[14px] font-semibold text-[var(--ink)] mb-1">Recent Transactions</h2>
            <p className="text-[12px] text-[var(--ink-muted)] mb-4">Most recent ClickPesa payment attempts, newest first</p>
            {data.recentClickPesaPayments.length === 0 ? (
              <p className="text-[13px] text-[var(--ink-faint)] py-4">No ClickPesa payments yet.</p>
            ) : (
              <div className="overflow-x-auto">
                <table className="w-full text-[12px]">
                  <thead>
                    <tr className="border-b border-[var(--line)] text-left text-[11px] uppercase tracking-wide text-[var(--ink-faint)]">
                      <th className="py-2 pr-4 font-medium">Plan</th>
                      <th className="py-2 pr-4 font-medium">Amount</th>
                      <th className="py-2 pr-4 font-medium">Channel</th>
                      <th className="py-2 pr-4 font-medium">Phone</th>
                      <th className="py-2 pr-4 font-medium">Status</th>
                      <th className="py-2 pr-4 font-medium">Date</th>
                    </tr>
                  </thead>
                  <tbody>
                    {data.recentClickPesaPayments.map((p) => (
                      <tr key={p.id} className="border-b border-[var(--line)] last:border-0">
                        <td className="py-2.5 pr-4 text-[var(--ink)] capitalize">{p.tier || '—'}</td>
                        <td className="py-2.5 pr-4 font-mono text-[var(--ink)]">{formatTZS(p.amount)}</td>
                        <td className="py-2.5 pr-4 text-[var(--ink-muted)]">{p.channel || '—'}</td>
                        <td className="py-2.5 pr-4 font-mono text-[var(--ink-muted)]">{formatPhone(p.phoneNumber) || '—'}</td>
                        <td className="py-2.5 pr-4">
                          <StatusDot
                            status={p.status === 'completed' ? 'good' : p.status === 'failed' ? 'bad' : 'warn'}
                            label={p.status.charAt(0).toUpperCase() + p.status.slice(1)}
                          />
                        </td>
                        <td className="py-2.5 pr-4 text-[var(--ink-muted)]">
                          {p.createdAt ? formatDate(p.createdAt) : '—'}
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )}
          </div>

          {/* Free vs Paid conversion opportunity */}
          {totalBusinesses > 0 && (
            <div className="mt-4 rounded-lg border border-[var(--line)] bg-[var(--surface)] p-5">
              <h2 className="text-[14px] font-semibold text-[var(--ink)] mb-1">Free vs Paid</h2>
              <p className="text-[12px] text-[var(--ink-muted)] mb-4">
                Share of businesses still on the free Starter plan — the pool to target for upgrade pushes
              </p>

              <div className="flex items-center gap-6">
                <div className="relative w-[160px] h-[160px] shrink-0">
                  <FreeVsPaidChart freeCount={freeCount} paidCount={paidCount} />
                  <div className="absolute inset-0 flex flex-col items-center justify-center pointer-events-none">
                    <span className="text-[20px] font-mono font-semibold text-[var(--ink)]">{freePct}%</span>
                    <span className="text-[10px] text-[var(--ink-faint)]">free</span>
                  </div>
                </div>

                <div className="flex-1 flex flex-col gap-3">
                  <div className="flex items-center justify-between text-[12px]">
                    <span className="inline-flex items-center gap-1.5 text-[var(--ink-muted)]">
                      <span className="h-2 w-2 rounded-full shrink-0" style={{ background: '#94A3B8' }} />
                      Free (Starter)
                    </span>
                    <span className="font-mono text-[var(--ink)]">{freeCount.toLocaleString()} ({freePct}%)</span>
                  </div>
                  <div className="flex items-center justify-between text-[12px]">
                    <span className="inline-flex items-center gap-1.5 text-[var(--ink-muted)]">
                      <span className="h-2 w-2 rounded-full shrink-0" style={{ background: '#1A6E8A' }} />
                      Paid (Growth+)
                    </span>
                    <span className="font-mono text-[var(--ink)]">{paidCount.toLocaleString()} ({paidPct}%)</span>
                  </div>
                </div>
              </div>

              {freePct >= 50 && (
                <div className="mt-4 rounded-md border border-[var(--status-warn)] bg-[var(--status-warn-bg)] px-3 py-2.5 text-[12px] text-[var(--status-warn)]">
                  {freePct}% of businesses ({freeCount.toLocaleString()}) are still on the free plan — a strong pool to target with upgrade prompts or campaigns.
                </div>
              )}
            </div>
          )}

          {/* Plan counts table */}
          {data.planDistribution.length > 0 && (
            <div className="mt-4 rounded-lg border border-[var(--line)] bg-[var(--surface)] p-5">
              <h2 className="text-[14px] font-semibold text-[var(--ink)] mb-4">Plan Distribution Detail</h2>
              <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-5 gap-3">
                {data.planDistribution.map(({ name, value, color }) => {
                  const fee = planFees[name.toLowerCase()] ?? 0
                  return (
                    <div key={name} className="rounded-md border border-[var(--line)] p-3">
                      <div className="flex items-center gap-2 mb-2">
                        <span className="h-2 w-2 rounded-full shrink-0" style={{ background: color }} />
                        <span className="text-[12px] font-medium text-[var(--ink)]">{name}</span>
                      </div>
                      <div className="text-[22px] font-mono font-semibold text-[var(--ink)]">
                        {value.toLocaleString()}
                      </div>
                      <div className="text-[11px] text-[var(--ink-faint)] mt-0.5">
                        {fee > 0 ? `TZS ${formatTZSCompact(fee)}/mo` : 'Free'}
                      </div>
                    </div>
                  )
                })}
              </div>
            </div>
          )}
        </>
      )}

      {/* ── Platform Settings ── */}
      <div className="mt-8 mb-2 flex items-center gap-3">
        <span className="text-[11px] uppercase tracking-widest font-semibold text-[var(--ink-faint)]">Platform Settings</span>
        <div className="flex-1 h-px bg-[var(--line)]" />
      </div>

      {configLoading && <SkeletonTable rows={3} cols={2} />}
      {configError && !config && (
        <div className="mt-4 flex items-center gap-3 rounded-lg border border-[var(--status-bad)] bg-[var(--status-bad-bg)] p-4 text-[var(--status-bad)]">
          <AlertCircle className="h-4 w-4 shrink-0" />
          <span className="text-[13px]">{configError}</span>
        </div>
      )}
      {config && (<>
        <div className="flex flex-col gap-4 mb-24">
          {/* Billing (SMS credits / exports — per-tier pricing & limits live on the Plans page) */}
          <ConfigSection title="Billing Settings" defaultOpen>
            <div className="divide-y divide-[var(--line)]">
              <Field label="SMS credit price">
                <NumberInput value={config.pricing.smsCreditPrice} suffix="TZS/credit"
                  onChange={(v) => update('pricing', { smsCreditPrice: v })} />
              </Field>
              <Field label="Export bundle price">
                <NumberInput value={config.pricing.exportBundlePrice} suffix="TZS"
                  onChange={(v) => update('pricing', { exportBundlePrice: v })} />
              </Field>
            </div>
          </ConfigSection>

          {/* Tax */}
          <ConfigSection title="Tax (VAT)">
            <div className="divide-y divide-[var(--line)]">
              <Field label="VAT enabled">
                <Toggle checked={config.tax.vatEnabled}
                  onChange={(v) => update('tax', { vatEnabled: v })} />
              </Field>
              <Field label="VAT rate">
                <NumberInput value={config.tax.vatRate} suffix="%"
                  onChange={(v) => update('tax', { vatRate: v })} />
              </Field>
            </div>
          </ConfigSection>

          {/* Lifetime Program */}
          <ConfigSection title="Lifetime Program">
            <div className="divide-y divide-[var(--line)]">
              <Field label="UTT AMIS monthly return rate">
                <NumberInput value={config.lifetimeProgram.uttAMISMonthlyRate} suffix="% / month"
                  onChange={(v) => update('lifetimeProgram', { uttAMISMonthlyRate: v })} />
              </Field>
              <Field label="Cancellation fees (Growth)">
                <div className="text-[12px] text-[var(--ink-muted)] font-mono space-y-1">
                  {config.lifetimeProgram.cancellationFees.growth.map(([maxM, fee], i) => (
                    <div key={i}>≤{(maxM === Infinity || maxM >= INF_SENTINEL) ? '∞' : maxM} months: {formatTZS(fee)}</div>
                  ))}
                </div>
              </Field>
              <Field label="Cancellation fees (Business)">
                <div className="text-[12px] text-[var(--ink-muted)] font-mono space-y-1">
                  {config.lifetimeProgram.cancellationFees.business.map(([maxM, fee], i) => (
                    <div key={i}>≤{(maxM === Infinity || maxM >= INF_SENTINEL) ? '∞' : maxM} months: {formatTZS(fee)}</div>
                  ))}
                </div>
              </Field>
            </div>
          </ConfigSection>
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
