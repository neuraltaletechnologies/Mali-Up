'use client'

import { useState, useCallback, useEffect, useMemo } from 'react'
import { PageHeader } from '@/components/ui/page-header'
import { DetailDrawer } from '@/components/ui/detail-drawer'
import { ConfirmDialog } from '@/components/ui/confirm-dialog'
import { SkeletonTable, RevalidatingBar } from '@/components/ui/skeleton'
import { fetchPlans, patchPlan, assignPlan, fetchBusinesses } from '@/lib/admin-api'
import { useAdminFetch, invalidateAdminCache } from '@/hooks/use-admin-fetch'
import { formatTZS } from '@/lib/format'
import type { PlanTier, PlanDefinition, PlanDefinitions } from '@/types'
import {
  Pencil, Users, FileText, CheckCircle2, XCircle, AlertCircle,
  Building2, Zap, Crown, Star, Layers, Gift, UserPlus,
} from 'lucide-react'

// ─── Constants ────────────────────────────────────────────────────────────────

const TIERS: PlanTier[] = ['starter', 'growth', 'business', 'enterprise']

const TIER_META: Record<PlanTier, {
  label: string
  target: string
  color: string
  bgGradient: string
  borderColor: string
  icon: React.ElementType
}> = {
  starter: {
    label: 'Starter',
    target: 'New businesses, solo owners',
    color: '#94A3B8',
    bgGradient: '',
    borderColor: 'rgba(255,255,255,0.09)',
    icon: Layers,
  },
  growth: {
    label: 'Growth',
    target: 'Active SMEs, 50+ transactions/month',
    color: '#2AB0D5',
    bgGradient: '',
    borderColor: 'rgba(42,176,213,0.3)',
    icon: Zap,
  },
  business: {
    label: 'Business',
    target: 'Multi-location, 5+ staff',
    color: '#6EB4D4',
    bgGradient: '',
    borderColor: 'rgba(42,176,213,0.45)',
    icon: Crown,
  },
  enterprise: {
    label: 'Enterprise',
    target: 'Chains, NGOs, franchises',
    color: '#FFC107',
    bgGradient: '',
    borderColor: 'rgba(255,193,7,0.4)',
    icon: Star,
  },
  lifetime: {
    label: 'Lifetime',
    target: 'Lifetime access holders',
    color: '#A78BFA',
    bgGradient: '',
    borderColor: 'rgba(167,139,250,0.4)',
    icon: Gift,
  },
}

const FEATURE_LABELS: Record<keyof Omit<PlanDefinition, 'pricePerCycle' | 'cycleMonths' | 'maxUsers' | 'monthlyInvoices' | 'maxBusinesses' | 'maxCustomers'>, string> = {
  cashFlow:             'Cash flow tracking',
  expenseTracking:      'Expense tracking',
  manualDebt:           'Manual debt entry',
  fullReports:          'Full reports',
  mpesaImport:          'M-Pesa import',
  smsReminders:         'SMS reminders',
  allExports:           'All exports',
  multiLocation:        'Multi-location stock',
  apiAccess:            'API access',
  prioritySupport:      'Priority support',
  customIntegrations:   'Custom integrations',
  whiteLabel:           'White-label options',
  dedicatedOnboarding:  'Dedicated onboarding',
}

const inputCls = 'w-full rounded-md border border-[var(--line)] bg-[var(--canvas)] px-3 py-2 text-[13px] text-[var(--ink)] focus:outline-none focus:ring-1 focus:ring-[var(--accent)]'
const labelCls = 'text-[12px] font-medium text-[var(--ink-muted)]'

// ─── Helpers ──────────────────────────────────────────────────────────────────

function Toggle({ checked, onChange }: { checked: boolean; onChange: (v: boolean) => void }) {
  return (
    <button
      type="button"
      onClick={() => onChange(!checked)}
      className={`relative inline-flex h-5 w-9 shrink-0 cursor-pointer rounded-full transition-colors duration-150 ${
        checked ? 'bg-[var(--accent)]' : 'bg-[var(--line)]'
      }`}
    >
      <span className={`inline-block h-4 w-4 rounded-full bg-white shadow-sm transition-transform duration-150 mt-0.5 ${
        checked ? 'translate-x-4' : 'translate-x-0.5'
      }`} />
    </button>
  )
}

function FeatureCheck({ ok }: { ok: boolean }) {
  return ok
    ? <CheckCircle2 className="h-3.5 w-3.5 text-[var(--status-good)] shrink-0" />
    : <XCircle     className="h-3.5 w-3.5 text-[var(--ink-faint)] shrink-0" />
}

function planPrice(plan: PlanDefinition) {
  if (plan.pricePerCycle === 0) return 'Free'
  const perMonth = Math.round(plan.pricePerCycle / plan.cycleMonths)
  return `${formatTZS(perMonth)}/mo`
}

// ─── Tier Card ────────────────────────────────────────────────────────────────

function TierCard({
  tier,
  plan,
  onEdit,
}: {
  tier: PlanTier
  plan: PlanDefinition
  onEdit: () => void
}) {
  const meta = TIER_META[tier] ?? TIER_META.starter
  const Icon = meta.icon

  return (
    <div
      className="relative flex flex-col rounded-xl border bg-[var(--surface)] p-5 gap-3"
      style={{ borderColor: meta.borderColor }}
    >
      {/* Header */}
      <div className="flex items-start justify-between gap-2">
        <div className="flex items-center gap-2.5">
          <div className="p-1.5 rounded-lg" style={{ backgroundColor: `${meta.color}18` }}>
            <Icon className="h-4 w-4" style={{ color: meta.color }} />
          </div>
          <div>
            <div className="text-[14px] font-bold text-[var(--ink)]">{meta.label}</div>
            <div className="text-[11px] text-[var(--ink-faint)] mt-0.5">{meta.target}</div>
          </div>
        </div>
        <button
          onClick={onEdit}
          className="p-1.5 rounded-lg border border-[var(--line)] bg-[var(--surface)] text-[var(--ink-faint)] hover:text-[var(--ink)] hover:border-[var(--accent)] transition-colors"
        >
          <Pencil className="h-3.5 w-3.5" />
        </button>
      </div>

      {/* Pricing */}
      <div className="flex items-end gap-2 border-t border-[var(--line)] pt-3">
        <div>
          <div className="text-[22px] font-black tracking-tight" style={{ color: meta.color }}>
            {planPrice(plan)}
          </div>
          {plan.pricePerCycle > 0 && (
            <div className="text-[11px] text-[var(--ink-faint)]">
              {formatTZS(plan.pricePerCycle)} billed every {plan.cycleMonths} months
            </div>
          )}
          {tier === 'enterprise' && (
            <div className="text-[11px] text-[var(--ink-faint)]">Custom pricing</div>
          )}
        </div>
      </div>

      {/* Limits */}
      <div className="flex flex-wrap gap-x-4 gap-y-1.5 text-[12px]">
        <div className="flex items-center gap-1.5 text-[var(--ink-muted)]">
          <Users className="h-3.5 w-3.5" />
          <span>{plan.maxUsers === -1 ? 'Unlimited' : plan.maxUsers} users</span>
        </div>
        <div className="flex items-center gap-1.5 text-[var(--ink-muted)]">
          <FileText className="h-3.5 w-3.5" />
          <span>{plan.monthlyInvoices === -1 ? 'Unlimited' : `${plan.monthlyInvoices}/mo`} invoices</span>
        </div>
        <div className="flex items-center gap-1.5 text-[var(--ink-muted)]">
          <Building2 className="h-3.5 w-3.5" />
          <span>{plan.maxBusinesses === -1 ? 'Unlimited' : plan.maxBusinesses} businesses</span>
        </div>
        <div className="flex items-center gap-1.5 text-[var(--ink-muted)]">
          <UserPlus className="h-3.5 w-3.5" />
          <span>{plan.maxCustomers === -1 ? 'Unlimited' : plan.maxCustomers} customers</span>
        </div>
      </div>

      {/* Features */}
      <div className="grid grid-cols-2 gap-x-3 gap-y-1.5 border-t border-[var(--line)] pt-3">
        {(Object.keys(FEATURE_LABELS) as (keyof typeof FEATURE_LABELS)[]).map((key) => (
          <div key={key} className="flex items-center gap-1.5">
            <FeatureCheck ok={plan[key]} />
            <span className="text-[11px] text-[var(--ink-muted)]">{FEATURE_LABELS[key]}</span>
          </div>
        ))}
      </div>
    </div>
  )
}

// ─── Edit Drawer ──────────────────────────────────────────────────────────────

function EditPlanDrawer({
  tier,
  plan,
  open,
  saving,
  onClose,
  onSave,
}: {
  tier: PlanTier
  plan: PlanDefinition
  open: boolean
  saving: boolean
  onClose: () => void
  onSave: (patch: Partial<PlanDefinition>) => void
}) {
  const [form, setForm] = useState<PlanDefinition>(plan)
  const meta = TIER_META[tier] ?? TIER_META.starter

  useEffect(() => { if (open) setForm(plan) }, [open, plan])

  function num(field: keyof PlanDefinition) {
    return (e: React.ChangeEvent<HTMLInputElement>) =>
      setForm((f) => ({ ...f, [field]: Number(e.target.value) }))
  }
  function bool(field: keyof PlanDefinition) {
    return (v: boolean) => setForm((f) => ({ ...f, [field]: v }))
  }

  function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    onSave(form)
  }

  return (
    <DetailDrawer open={open} onClose={onClose} title={`Edit ${meta.label} Plan`} description="Update pricing, limits and features" width="w-[520px]">
      <form onSubmit={handleSubmit} className="flex flex-col gap-6">

        {/* Pricing */}
        <div>
          <div className="text-[11px] uppercase tracking-wide font-semibold text-[var(--ink-faint)] mb-3">Pricing</div>
          <div className="grid grid-cols-2 gap-3">
            <div className="flex flex-col gap-1.5">
              <label className={labelCls}>Price per billing cycle (TZS)</label>
              <div className="relative">
                <span className="absolute left-3 top-1/2 -translate-y-1/2 text-[12px] text-[var(--ink-faint)]">TZS</span>
                <input
                  type="number" min="0"
                  value={form.pricePerCycle}
                  onChange={num('pricePerCycle')}
                  className={`${inputCls} pl-10`}
                  disabled={tier === 'starter'}
                />
              </div>
              {tier === 'starter' && <p className="text-[11px] text-[var(--ink-faint)]">Starter is always free</p>}
            </div>
            <div className="flex flex-col gap-1.5">
              <label className={labelCls}>Billing cycle (months)</label>
              <input
                type="number" min="1" max="24"
                value={form.cycleMonths}
                onChange={num('cycleMonths')}
                className={inputCls}
                disabled={tier === 'starter' || tier === 'enterprise'}
              />
              {form.pricePerCycle > 0 && form.cycleMonths > 0 && (
                <p className="text-[11px] text-[var(--ink-faint)]">
                  ≈ {formatTZS(Math.round(form.pricePerCycle / form.cycleMonths))}/month
                </p>
              )}
            </div>
          </div>
        </div>

        {/* Limits */}
        <div>
          <div className="text-[11px] uppercase tracking-wide font-semibold text-[var(--ink-faint)] mb-3">Limits</div>
          <div className="grid grid-cols-2 gap-3">
            <div className="flex flex-col gap-1.5">
              <label className={labelCls}>Max users (−1 = unlimited)</label>
              <input type="number" min="-1" value={form.maxUsers} onChange={num('maxUsers')} className={inputCls} />
            </div>
            <div className="flex flex-col gap-1.5">
              <label className={labelCls}>Monthly invoices (−1 = unlimited)</label>
              <input type="number" min="-1" value={form.monthlyInvoices} onChange={num('monthlyInvoices')} className={inputCls} />
            </div>
            <div className="flex flex-col gap-1.5">
              <label className={labelCls}>Max businesses (−1 = unlimited)</label>
              <input type="number" min="-1" value={form.maxBusinesses ?? 0} onChange={num('maxBusinesses')} className={inputCls} />
            </div>
            <div className="flex flex-col gap-1.5">
              <label className={labelCls}>Max customers (−1 = unlimited)</label>
              <input type="number" min="-1" value={form.maxCustomers ?? 0} onChange={num('maxCustomers')} className={inputCls} />
            </div>
          </div>
        </div>

        {/* Features */}
        <div>
          <div className="text-[11px] uppercase tracking-wide font-semibold text-[var(--ink-faint)] mb-3">Features</div>
          <div className="flex flex-col gap-3">
            {(Object.keys(FEATURE_LABELS) as (keyof typeof FEATURE_LABELS)[]).map((key) => (
              <div key={key} className="flex items-center justify-between py-1 border-b border-[var(--line)] last:border-0">
                <span className="text-[13px] text-[var(--ink-muted)]">{FEATURE_LABELS[key]}</span>
                <Toggle checked={form[key]} onChange={bool(key)} />
              </div>
            ))}
          </div>
        </div>

        <div className="flex gap-2 justify-end border-t border-[var(--line)] pt-4">
          <button type="button" onClick={onClose}
            className="rounded-md border border-[var(--line)] px-4 py-2 text-[12px] font-medium text-[var(--ink-muted)] hover:text-[var(--ink)]">
            Cancel
          </button>
          <button type="submit" disabled={saving}
            style={{ backgroundColor: '#0D1B3E' }}
            className="rounded-md px-4 py-2 text-[12px] font-medium text-white hover:opacity-90 transition-opacity disabled:opacity-50">
            {saving ? 'Saving…' : 'Save changes'}
          </button>
        </div>
      </form>
    </DetailDrawer>
  )
}

// ─── Assign Plan Form ─────────────────────────────────────────────────────────

function AssignPlanSection() {
  const [userNameInput, setUserNameInput] = useState('')
  const [selectedUid, setSelectedUid]     = useState('')
  const [businessId, setBusinessId]       = useState('')
  const [selectedTier, setSelectedTier]   = useState<PlanTier>('growth')
  const [cycleMonths, setCycleMonths]     = useState(6)
  const [saving, setSaving]               = useState(false)
  const [result, setResult]               = useState<{ ok: boolean; msg: string } | null>(null)
  const [confirmOpen, setConfirmOpen]     = useState(false)

  const { data: bizData } = useAdminFetch(useCallback(() => fetchBusinesses(500), []), {
    key: 'businesses-500',
    minStaleMs: 60_000,
  })
  const businesses = bizData?.businesses ?? []

  // Derive unique owners from the businesses list (sorted alphabetically)
  const uniqueUsers = useMemo(() => {
    const seen = new Set<string>()
    const list: { uid: string; name: string; phone: string }[] = []
    for (const b of businesses) {
      if (!seen.has(b.ownerId)) {
        seen.add(b.ownerId)
        list.push({ uid: b.ownerId, name: b.ownerName, phone: b.ownerPhone })
      }
    }
    return list.sort((a, b) => a.name.localeCompare(b.name))
  }, [businesses])

  // Match typed name to a real user
  useEffect(() => {
    const matched = uniqueUsers.find(
      (u) => u.name.toLowerCase() === userNameInput.toLowerCase(),
    )
    if (matched) {
      setSelectedUid(matched.uid)
    } else {
      setSelectedUid('')
      setBusinessId('')
    }
  }, [userNameInput, uniqueUsers])

  // Businesses belonging to the matched user
  const bizesForUser = useMemo(
    () => businesses.filter((b) => b.ownerId === selectedUid),
    [businesses, selectedUid],
  )

  // Auto-select when there is exactly one business
  useEffect(() => {
    if (bizesForUser.length === 1) setBusinessId(bizesForUser[0].id)
    else if (bizesForUser.length === 0) setBusinessId('')
  }, [selectedUid, bizesForUser])

  const selectedBiz  = businesses.find((b) => b.id === businessId)
  const selectedUser = uniqueUsers.find((u) => u.uid === selectedUid)

  async function handleAssign() {
    setSaving(true)
    setResult(null)
    try {
      await assignPlan(selectedUid, businessId, selectedTier, cycleMonths)
      setResult({ ok: true, msg: `Plan "${selectedTier}" assigned to ${selectedBiz?.name ?? businessId} successfully.` })
      invalidateAdminCache(['analytics', 'businesses'])
      setUserNameInput('')
      setSelectedUid('')
      setBusinessId('')
    } catch (e) {
      setResult({ ok: false, msg: (e as Error).message })
    } finally {
      setSaving(false)
      setConfirmOpen(false)
    }
  }

  return (
    <div className="rounded-xl border border-[var(--line)] bg-[var(--surface)] p-5">
      <div className="flex items-center gap-2.5 mb-5">
        <div className="p-1.5 rounded-lg bg-[var(--accent-soft)]">
          <Building2 className="h-4 w-4 text-[var(--accent)]" />
        </div>
        <div>
          <div className="text-[14px] font-semibold text-[var(--ink)]">Assign Plan to Business</div>
          <div className="text-[12px] text-[var(--ink-faint)]">Override a business's subscription tier directly</div>
        </div>
      </div>

      <div className="grid grid-cols-2 gap-4">
        {/* User name */}
        <div className="flex flex-col gap-1.5">
          <label className={labelCls}>User Name <span className="text-[var(--status-bad)]">*</span></label>
          <input
            value={userNameInput}
            onChange={(e) => setUserNameInput(e.target.value)}
            placeholder="Search by owner name…"
            list="user-name-suggestions"
            className={inputCls}
          />
          <datalist id="user-name-suggestions">
            {uniqueUsers.map((u) => (
              <option key={u.uid} value={u.name} />
            ))}
          </datalist>
          {selectedUser ? (
            <p className="text-[11px] text-[var(--status-good)]">
              ✓ {selectedUser.name} · {selectedUser.phone}
            </p>
          ) : userNameInput ? (
            <p className="text-[11px] text-[var(--ink-faint)]">No matching user — keep typing</p>
          ) : null}
        </div>

        {/* Business name */}
        <div className="flex flex-col gap-1.5">
          <label className={labelCls}>Business Name <span className="text-[var(--status-bad)]">*</span></label>
          {bizesForUser.length > 1 ? (
            <select
              value={businessId}
              onChange={(e) => setBusinessId(e.target.value)}
              className={`${inputCls} appearance-none`}
            >
              <option value="">Select business…</option>
              {bizesForUser.map((b) => (
                <option key={b.id} value={b.id}>{b.name}</option>
              ))}
            </select>
          ) : (
            <input
              readOnly
              value={selectedBiz?.name ?? ''}
              placeholder={
                !selectedUid
                  ? 'Select a user first…'
                  : bizesForUser.length === 0
                  ? 'No businesses found'
                  : ''
              }
              className={`${inputCls} cursor-default bg-[var(--canvas)] text-[var(--ink-muted)]`}
            />
          )}
          {selectedBiz && (
            <p className="text-[11px] text-[var(--status-good)]">
              ✓ current plan: <strong>{selectedBiz.plan}</strong>
            </p>
          )}
        </div>

        {/* Tier */}
        <div className="flex flex-col gap-1.5">
          <label className={labelCls}>New Plan Tier</label>
          <select
            value={selectedTier}
            onChange={(e) => setSelectedTier(e.target.value as PlanTier)}
            className={`${inputCls} appearance-none`}
          >
            {TIERS.map((t) => (
              <option key={t} value={t}>{TIER_META[t].label}</option>
            ))}
          </select>
        </div>

        {/* Duration */}
        <div className="flex flex-col gap-1.5">
          <label className={labelCls}>Duration (months)</label>
          <input
            type="number" min="1" max="60"
            value={cycleMonths}
            onChange={(e) => setCycleMonths(Number(e.target.value))}
            className={inputCls}
            disabled={selectedTier === 'starter'}
          />
          {selectedTier !== 'starter' && (
            <p className="text-[11px] text-[var(--ink-faint)]">
              Expires {new Date(Date.now() + cycleMonths * 30 * 86400000).toLocaleDateString('en-GB', { day: 'numeric', month: 'short', year: 'numeric' })}
            </p>
          )}
        </div>
      </div>

      {result && (
        <div className={`mt-4 flex items-center gap-2.5 rounded-lg border p-3 text-[12px] ${
          result.ok
            ? 'border-[var(--status-good)] bg-[var(--status-good-bg)] text-[var(--status-good)]'
            : 'border-[var(--status-bad)] bg-[var(--status-bad-bg)] text-[var(--status-bad)]'
        }`}>
          <AlertCircle className="h-4 w-4 shrink-0" />
          {result.msg}
        </div>
      )}

      <div className="mt-4 flex justify-end">
        <button
          onClick={() => setConfirmOpen(true)}
          disabled={!selectedUid || !businessId || saving}
          style={{ backgroundColor: '#0D1B3E' }}
          className="inline-flex items-center gap-1.5 rounded-md px-4 py-2 text-[12px] font-medium text-white hover:opacity-90 transition-opacity disabled:opacity-40"
        >
          <Building2 className="h-3.5 w-3.5" />
          Assign Plan
        </button>
      </div>

      <ConfirmDialog
        open={confirmOpen}
        onClose={() => setConfirmOpen(false)}
        onConfirm={handleAssign}
        title="Assign plan"
        description={`Set plan to "${TIER_META[selectedTier]?.label}" for ${selectedBiz?.name ?? businessId} (owner: ${selectedUser?.name ?? selectedUid})${
          selectedTier !== 'starter' ? ` for ${cycleMonths} months` : ''
        }. This takes effect immediately.`}
        confirmLabel={saving ? 'Saving…' : 'Confirm'}
      />
    </div>
  )
}

// ─── Page ─────────────────────────────────────────────────────────────────────

export default function PlansPage() {
  const { data, loading, revalidating, error, refetch } = useAdminFetch(
    useCallback(() => fetchPlans(), []),
    { key: 'plans' },
  )

  const [editTier, setEditTier]     = useState<PlanTier | null>(null)
  const [localPlans, setLocalPlans] = useState<PlanDefinitions | null>(null)
  const [saving, setSaving]         = useState(false)
  const [saveError, setSaveError]   = useState('')

  useEffect(() => {
    if (data?.plans) setLocalPlans(data.plans)
  }, [data])

  async function handleSave(tier: PlanTier, patch: Partial<PlanDefinition>) {
    setSaving(true)
    setSaveError('')
    try {
      await patchPlan(tier, patch)
      setLocalPlans((prev) => prev ? { ...prev, [tier]: { ...prev[tier], ...patch } } : prev)
      setEditTier(null)
      invalidateAdminCache(['analytics', 'plans'])
      refetch()
    } catch (e) {
      setSaveError((e as Error).message)
    } finally {
      setSaving(false)
    }
  }

  return (
    <div>
      {revalidating && <RevalidatingBar />}
      {loading && <SkeletonTable rows={4} cols={5} />}
      {error && !localPlans && (
        <div className="mt-4 flex items-center gap-3 rounded-lg border border-[var(--status-bad)] bg-[var(--status-bad-bg)] p-4 text-[var(--status-bad)]">
          <AlertCircle className="h-4 w-4 shrink-0" />
          <span className="text-[13px]">{error}</span>
        </div>
      )}
      {localPlans && (<>
      <PageHeader
        title="Subscription Plans"
        description="Edit plan pricing, limits, and features — changes propagate to the mobile app immediately"
      />

      {saveError && (
        <div className="mb-4 flex items-center gap-2.5 rounded-lg border border-[var(--status-bad)] bg-[var(--status-bad-bg)] p-3 text-[12px] text-[var(--status-bad)]">
          <AlertCircle className="h-4 w-4 shrink-0" />
          {saveError}
        </div>
      )}

      {/* Tier cards grid */}
      <div className="grid grid-cols-2 gap-4 mb-8">
        {TIERS.map((tier) => (
          <TierCard
            key={tier}
            tier={tier}
            plan={localPlans[tier]}
            onEdit={() => setEditTier(tier)}
          />
        ))}
      </div>

      {/* Pricing summary table */}
      <div className="mb-8 rounded-xl border border-[var(--line)] overflow-hidden">
        <div className="px-5 py-3 bg-[var(--canvas)] border-b border-[var(--line)]">
          <span className="text-[13px] font-semibold text-[var(--ink)]">Pricing Anchor</span>
          <span className="ml-2 text-[12px] text-[var(--ink-faint)]">Growth costs less per month than one hour of a Dar es Salaam accountant's time</span>
        </div>
        <div className="overflow-x-auto">
          <table className="w-full text-[12px]">
            <thead>
              <tr className="border-b border-[var(--line)]">
                <th className="text-left px-5 py-3 text-[var(--ink-muted)] font-medium w-32">Tier</th>
                <th className="text-right px-5 py-3 text-[var(--ink-muted)] font-medium">Price / cycle</th>
                <th className="text-right px-5 py-3 text-[var(--ink-muted)] font-medium">Cycle</th>
                <th className="text-right px-5 py-3 text-[var(--ink-muted)] font-medium">Effective / mo</th>
                <th className="text-right px-5 py-3 text-[var(--ink-muted)] font-medium">Max users</th>
                <th className="text-right px-5 py-3 text-[var(--ink-muted)] font-medium">Invoices / mo</th>
                <th className="text-right px-5 py-3 text-[var(--ink-muted)] font-medium">Max businesses</th>
                <th className="text-right px-5 py-3 text-[var(--ink-muted)] font-medium">Max customers</th>
              </tr>
            </thead>
            <tbody>
              {TIERS.map((tier) => {
                const p = localPlans[tier]
                const perMonth = p.pricePerCycle > 0 && p.cycleMonths > 0
                  ? Math.round(p.pricePerCycle / p.cycleMonths)
                  : 0
                return (
                  <tr key={tier} className="border-b border-[var(--line)] last:border-0 hover:bg-[var(--canvas)] transition-colors">
                    <td className="px-5 py-3 font-medium text-[var(--ink)]">{TIER_META[tier].label}</td>
                    <td className="px-5 py-3 text-right font-mono text-[var(--ink)]">
                      {p.pricePerCycle === 0 ? (tier === 'enterprise' ? 'Custom' : 'Free') : formatTZS(p.pricePerCycle)}
                    </td>
                    <td className="px-5 py-3 text-right text-[var(--ink-muted)]">
                      {p.cycleMonths > 0 ? `${p.cycleMonths} mo` : '—'}
                    </td>
                    <td className="px-5 py-3 text-right font-mono text-[var(--ink-muted)]">
                      {perMonth > 0 ? formatTZS(perMonth) : '—'}
                    </td>
                    <td className="px-5 py-3 text-right text-[var(--ink-muted)]">
                      {p.maxUsers === -1 ? '∞' : p.maxUsers}
                    </td>
                    <td className="px-5 py-3 text-right text-[var(--ink-muted)]">
                      {p.monthlyInvoices === -1 ? '∞' : p.monthlyInvoices}
                    </td>
                    <td className="px-5 py-3 text-right text-[var(--ink-muted)]">
                      {p.maxBusinesses === -1 ? '∞' : p.maxBusinesses}
                    </td>
                    <td className="px-5 py-3 text-right text-[var(--ink-muted)]">
                      {p.maxCustomers === -1 ? '∞' : p.maxCustomers}
                    </td>
                  </tr>
                )
              })}
            </tbody>
          </table>
        </div>
      </div>

      {/* Assign plan section */}
      <AssignPlanSection />

      {/* Edit drawers */}
      {TIERS.map((tier) => (
        <EditPlanDrawer
          key={tier}
          tier={tier}
          plan={localPlans[tier]}
          open={editTier === tier}
          saving={saving}
          onClose={() => { setEditTier(null); setSaveError('') }}
          onSave={(patch) => handleSave(tier, patch)}
        />
      ))}
      </>)}
    </div>
  )
}
