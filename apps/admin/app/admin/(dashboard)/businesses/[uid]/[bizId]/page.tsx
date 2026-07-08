'use client'

import { useState, useCallback, useEffect } from 'react'
import { useParams, useRouter } from 'next/navigation'
import { useSession } from 'next-auth/react'
import { PageHeader } from '@/components/ui/page-header'
import { StatusDot } from '@/components/ui/status-dot'
import { PlanBadge } from '@/components/ui/plan-badge'
import { Tabs } from '@/components/ui/tabs'
import { ConfirmDialog } from '@/components/ui/confirm-dialog'
import { DeleteConfirmDialog } from '@/components/ui/delete-confirm-dialog'
import { KPICard } from '@/components/ui/kpi-card'
import { Skeleton } from '@/components/ui/skeleton'
import { fetchBusiness, patchBusiness, postBusinessNote, editBusiness, deleteBusiness, assignPlan, fetchCatalog, attachCatalogToBusiness, fetchPlans, setEnterpriseTerms } from '@/lib/admin-api'
import { useAdminFetch, invalidateAdminCache } from '@/hooks/use-admin-fetch'
import { formatTZS, formatDate, timeAgo } from '@/lib/format'
import {
  ArrowLeft, Ban, RotateCcw, MessageSquarePlus, AlertCircle,
  Users, Receipt, ShoppingBag, UserCheck, Pencil, X, Loader2,
  PackagePlus, CheckSquare, Square, Trash2, Star,
} from 'lucide-react'
import type { Business, StaffMember, CatalogCategory, CatalogProduct, PlanTier, PlanDefinition } from '@/types'
import { Toggle } from '@/components/ui/toggle'

const PLAN_OPTIONS: PlanTier[] = ['starter', 'growth', 'business', 'enterprise', 'lifetime']

const TABS = [
  { id: 'overview',      label: 'Overview' },
  { id: 'team',          label: 'Team' },
  { id: 'financial',     label: 'Financial' },
  { id: 'subscription',  label: 'Subscription' },
  { id: 'catalog',       label: 'Catalog' },
  { id: 'notes',         label: 'Notes' },
]

function RoleBadge({ role }: { role: string }) {
  const colours: Record<string, string> = {
    owner:   'bg-amber-500/20 text-amber-300',
    admin:   'bg-blue-500/20 text-blue-300',
    manager: 'bg-teal-500/20 text-teal-300',
    cashier: 'bg-slate-500/20 text-slate-300',
    staff:   'bg-slate-500/20 text-slate-300',
  }
  const cls = colours[role.toLowerCase()] ?? colours.staff
  return (
    <span className={`inline-flex rounded px-1.5 py-0.5 text-[11px] font-medium ${cls}`}>
      {role.charAt(0).toUpperCase() + role.slice(1)}
    </span>
  )
}

// ─── Edit Business Drawer ─────────────────────────────────────────────────────

function EditBusinessDrawer({
  business, uid, bizId, open, onClose, onSaved,
}: {
  business: Business; uid: string; bizId: string
  open: boolean; onClose: () => void; onSaved: () => void
}) {
  const [name,     setName]     = useState(business.name)
  const [category, setCategory] = useState(business.industry)
  const [location, setLocation] = useState(business.location ?? '')
  const [plan,     setPlan]     = useState<PlanTier>(business.plan)
  const [cycleMonths, setCycleMonths] = useState(6)
  const [saving,   setSaving]   = useState(false)
  const [err,      setErr]      = useState<string | null>(null)

  const planChanged = plan !== business.plan
  const paidPlan     = plan !== 'starter' && plan !== 'enterprise' && plan !== 'lifetime'

  async function handleSave(e: React.FormEvent) {
    e.preventDefault()
    if (!name.trim()) { setErr('Business name is required.'); return }
    setSaving(true); setErr(null)
    try {
      await editBusiness(uid, bizId, {
        businessName:     name.trim(),
        businessCategory: category.trim() || undefined,
        placeOfBusiness:  location.trim() || undefined,
      })
      if (planChanged) {
        await assignPlan(uid, bizId, plan, cycleMonths)
      }
      onSaved()
    } catch (e: unknown) {
      setErr(e instanceof Error ? e.message : 'Failed to save')
    } finally {
      setSaving(false)
    }
  }

  if (!open) return null

  return (
    <div className="fixed inset-0 z-50 flex">
      <div className="flex-1 bg-black/50" onClick={onClose} />
      <div className="w-[400px] bg-[var(--navy)] border-l border-white/[0.09] flex flex-col">
        <div className="flex items-center justify-between px-6 py-5 border-b border-white/[0.07]">
          <h2 className="text-[15px] font-semibold text-white">Edit Business</h2>
          <button onClick={onClose} className="p-1 rounded-md text-slate-400 hover:text-white hover:bg-white/10 transition-colors">
            <X className="h-4 w-4" />
          </button>
        </div>
        <form onSubmit={handleSave} className="flex-1 overflow-y-auto px-6 py-5 flex flex-col gap-4">
          <DField label="Business Name" value={name} onChange={setName} required />
          <DField label="Industry / Category" value={category} onChange={setCategory} placeholder="e.g. retail, pharmacy…" />
          <DField label="Location / City" value={location} onChange={setLocation} placeholder="e.g. Dar es Salaam" />

          <label className="flex flex-col gap-1">
            <span className="text-[11px] text-slate-400">Plan — current: {business.plan}</span>
            <select
              value={plan}
              onChange={(e) => setPlan(e.target.value as PlanTier)}
              className="rounded-md border border-white/10 bg-white/[0.05] px-3 py-2 text-[13px] text-white focus:outline-none focus:ring-1 focus:ring-[var(--accent)]"
            >
              {PLAN_OPTIONS.map((p) => (
                <option key={p} value={p} className="bg-[#0D1B3E]">
                  {p.charAt(0).toUpperCase() + p.slice(1)}
                </option>
              ))}
            </select>
          </label>

          {planChanged && paidPlan && (
            <label className="flex flex-col gap-1">
              <span className="text-[11px] text-slate-400">Duration (months)</span>
              <input
                type="number" min="1" max="60"
                value={cycleMonths}
                onChange={(e) => setCycleMonths(Number(e.target.value))}
                className="rounded-md border border-white/10 bg-white/[0.05] px-3 py-2 text-[13px] text-white focus:outline-none focus:ring-1 focus:ring-[var(--accent)]"
              />
            </label>
          )}

          {planChanged && (
            <p className="text-[11px] text-amber-400">
              Plan: {business.plan} → {plan}{paidPlan ? ` (${cycleMonths} months)` : ''}
            </p>
          )}

          {err && (
            <div className="flex items-center gap-2 rounded-md border border-red-500/40 bg-red-500/10 px-3 py-2">
              <AlertCircle className="h-3.5 w-3.5 text-red-400 shrink-0" />
              <span className="text-[12px] text-red-300">{err}</span>
            </div>
          )}

          <div className="mt-auto pt-4 flex gap-3">
            <button type="button" onClick={onClose} className="flex-1 rounded-md border border-white/10 px-4 py-2 text-[13px] text-slate-300 hover:bg-white/10 transition-colors">
              Cancel
            </button>
            <button type="submit" disabled={saving} className="flex-1 inline-flex items-center justify-center gap-1.5 rounded-md bg-[var(--brand)] px-4 py-2 text-[13px] font-medium text-[#040C18] hover:opacity-90 disabled:opacity-60 transition-opacity">
              {saving ? <Loader2 className="h-3.5 w-3.5 animate-spin" /> : null}
              {saving ? 'Saving…' : 'Save changes'}
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}

function DField({
  label, value, onChange, placeholder, required,
}: {
  label: string; value: string; onChange: (v: string) => void; placeholder?: string; required?: boolean
}) {
  return (
    <label className="flex flex-col gap-1">
      <span className="text-[11px] text-slate-400">{label}{required && <span className="text-red-400 ml-0.5">*</span>}</span>
      <input
        value={value}
        onChange={(e) => onChange(e.target.value)}
        placeholder={placeholder}
        required={required}
        className="rounded-md border border-white/10 bg-white/[0.05] px-3 py-2 text-[13px] text-white placeholder:text-slate-600 focus:outline-none focus:ring-1 focus:ring-[var(--accent)]"
      />
    </label>
  )
}

// ─── Catalog Attach Panel ─────────────────────────────────────────────────────

function CatalogAttachPanel({
  uid, bizId, businessName, industry,
}: {
  uid: string; bizId: string; businessName: string; industry: string
}) {
  const { data, loading, error } = useAdminFetch(
    useCallback(() => fetchCatalog(), []),
    { key: 'catalog-all' },
  )

  const categories = data?.categories ?? []
  const products   = data?.products   ?? []

  const [businessType, setBusinessType] = useState('')
  const [categorySlug, setCategorySlug] = useState('')
  const [selected,     setSelected]     = useState<Set<string>>(new Set())
  const [attaching,    setAttaching]    = useState(false)
  const [result,       setResult]       = useState<{ imported: number; skipped: number } | null>(null)
  const [err,          setErr]          = useState<string | null>(null)

  // Default the business-type filter to the business's own industry, once, if it matches.
  const [defaulted, setDefaulted] = useState(false)
  if (!defaulted && data && !businessType) {
    const match = data.businessTypes.find(
      (t) => t.toLowerCase() === industry.toLowerCase(),
    )
    if (match) setBusinessType(match)
    setDefaulted(true)
  }

  const filteredCategories = businessType
    ? categories.filter((c) => c.businessTypes.includes(businessType))
    : categories

  const categoryProducts = categorySlug
    ? products.filter((p) => p.categorySlug === categorySlug &&
        (!businessType || p.businessTypes.includes(businessType)))
    : []

  const selectedCategory = categories.find((c) => c.categorySlug === categorySlug)

  function toggleProduct(id: string) {
    setSelected((s) => {
      const next = new Set(s)
      if (next.has(id)) next.delete(id); else next.add(id)
      return next
    })
  }

  function toggleAll() {
    setSelected((s) =>
      s.size === categoryProducts.length
        ? new Set()
        : new Set(categoryProducts.map((p) => p.id)),
    )
  }

  async function handleAttach() {
    if (selected.size === 0) return
    setAttaching(true); setErr(null); setResult(null)
    try {
      const res = await attachCatalogToBusiness(uid, bizId, {
        categorySlug,
        categoryName: selectedCategory?.categoryName,
        productIds: [...selected],
      })
      setResult({ imported: res.imported, skipped: res.skipped })
      setSelected(new Set())
    } catch (e: unknown) {
      setErr(e instanceof Error ? e.message : 'Failed to attach products')
    } finally {
      setAttaching(false)
    }
  }

  if (loading) return <SkeletonPanel />

  if (error) {
    return (
      <div className="flex items-center gap-2 rounded-lg border border-[var(--status-bad)] bg-[var(--status-bad-bg)] p-4 text-[var(--status-bad)]">
        <AlertCircle className="h-4 w-4 shrink-0" />
        <span className="text-[13px]">{error}</span>
      </div>
    )
  }

  return (
    <div className="rounded-lg border border-[var(--line)] bg-[var(--surface)] p-6">
      <div className="flex items-center gap-2 mb-1">
        <PackagePlus className="h-4 w-4 text-[var(--accent)]" />
        <h3 className="text-[14px] font-semibold text-[var(--ink)]">Attach Catalog Products</h3>
      </div>
      <p className="text-[12px] text-[var(--ink-muted)] mb-5">
        Pick a category from the Master Catalog and attach its products directly to {businessName}&apos;s inventory.
        Items are created with zero stock and no price — the business fills those in.
      </p>

      <div className="grid grid-cols-2 gap-3 mb-4">
        <label className="flex flex-col gap-1">
          <span className="text-[11px] text-[var(--ink-faint)]">Business Type</span>
          <select
            value={businessType}
            onChange={(e) => { setBusinessType(e.target.value); setCategorySlug(''); setSelected(new Set()) }}
            className="rounded-md border border-[var(--line)] bg-[var(--canvas)] px-3 py-2 text-[13px] text-[var(--ink)] focus:outline-none focus:ring-1 focus:ring-[var(--accent)]"
          >
            <option value="">All business types</option>
            {data?.businessTypes.map((t) => <option key={t} value={t}>{t}</option>)}
          </select>
        </label>
        <label className="flex flex-col gap-1">
          <span className="text-[11px] text-[var(--ink-faint)]">Category</span>
          <select
            value={categorySlug}
            onChange={(e) => { setCategorySlug(e.target.value); setSelected(new Set()) }}
            className="rounded-md border border-[var(--line)] bg-[var(--canvas)] px-3 py-2 text-[13px] text-[var(--ink)] focus:outline-none focus:ring-1 focus:ring-[var(--accent)]"
          >
            <option value="">Select a category…</option>
            {filteredCategories.map((c) => (
              <option key={c.id} value={c.categorySlug}>
                {c.categoryName} ({c.productCount})
              </option>
            ))}
          </select>
        </label>
      </div>

      {categorySlug && (
        <>
          <div className="flex items-center justify-between mb-2">
            <button
              onClick={toggleAll}
              className="inline-flex items-center gap-1.5 text-[12px] font-medium text-[var(--accent)] hover:underline"
            >
              {selected.size === categoryProducts.length && categoryProducts.length > 0
                ? <CheckSquare className="h-3.5 w-3.5" />
                : <Square className="h-3.5 w-3.5" />}
              {selected.size === categoryProducts.length && categoryProducts.length > 0 ? 'Deselect all' : 'Select all'}
            </button>
            <span className="text-[11px] text-[var(--ink-faint)]">
              {selected.size} of {categoryProducts.length} selected
            </span>
          </div>

          <div className="max-h-72 overflow-y-auto rounded-md border border-[var(--line)] divide-y divide-[var(--line)] mb-4">
            {categoryProducts.length === 0 ? (
              <div className="p-4 text-center text-[12px] text-[var(--ink-faint)]">No products in this category.</div>
            ) : (
              categoryProducts.map((p: CatalogProduct) => (
                <label
                  key={p.id}
                  className="flex items-center gap-3 px-3 py-2.5 hover:bg-[var(--canvas)] cursor-pointer"
                >
                  <input
                    type="checkbox"
                    checked={selected.has(p.id)}
                    onChange={() => toggleProduct(p.id)}
                    className="rounded border-[var(--line)]"
                  />
                  <div className="flex-1 min-w-0">
                    <div className="text-[13px] font-medium text-[var(--ink)] truncate">{p.productName}</div>
                    {p.productNameSw && (
                      <div className="text-[11px] text-[var(--ink-faint)] truncate">{p.productNameSw}</div>
                    )}
                  </div>
                  <span className="text-[11px] text-[var(--ink-muted)] shrink-0">{p.unit}</span>
                </label>
              ))
            )}
          </div>

          {err && (
            <div className="flex items-center gap-2 rounded-md border border-[var(--status-bad)] bg-[var(--status-bad-bg)] p-3 mb-3 text-[12px] text-[var(--status-bad)]">
              <AlertCircle className="h-3.5 w-3.5 shrink-0" /> {err}
            </div>
          )}

          {result && (
            <div className="rounded-md border border-[var(--status-good)] bg-[var(--status-good-bg)] p-3 mb-3 text-[12px] text-[var(--status-good)]">
              Attached {result.imported} product{result.imported === 1 ? '' : 's'}.
              {result.skipped > 0 && ` ${result.skipped} already in inventory, skipped.`}
            </div>
          )}

          <button
            onClick={handleAttach}
            disabled={attaching || selected.size === 0}
            style={{ backgroundColor: '#FFC107', color: '#0D1B3E' }}
            className="inline-flex items-center gap-1.5 rounded-md px-4 py-2 text-[12px] font-medium hover:opacity-90 transition-opacity disabled:opacity-50"
          >
            {attaching ? <Loader2 className="h-3.5 w-3.5 animate-spin" /> : <PackagePlus className="h-3.5 w-3.5" />}
            {attaching ? 'Attaching…' : `Attach ${selected.size || ''} to ${businessName}`}
          </button>
        </>
      )}
    </div>
  )
}

// ─── Enterprise Deal Terms Panel ───────────────────────────────────────────────

const OVERRIDE_FEATURE_LABELS: Record<keyof Omit<PlanDefinition, 'pricePerCycle' | 'cycleMonths' | 'maxUsers' | 'monthlyInvoices' | 'maxBusinesses' | 'maxCustomers'>, string> = {
  cashFlow:            'Cash flow tracking',
  expenseTracking:     'Expense tracking',
  manualDebt:          'Manual debt entry',
  fullReports:         'Full reports',
  mpesaImport:         'M-Pesa import',
  smsReminders:        'SMS reminders',
  allExports:          'All exports',
  multiLocation:       'Multi-location stock',
  apiAccess:           'API access',
  prioritySupport:     'Priority support',
  customIntegrations:  'Custom integrations',
  whiteLabel:          'White-label options',
  dedicatedOnboarding: 'Dedicated onboarding',
}

function EnterpriseTermsPanel({
  uid, bizId, business, onSaved,
}: {
  uid: string; bizId: string; business: Business; onSaved: () => void
}) {
  const { data: plansData } = useAdminFetch(useCallback(() => fetchPlans(), []), { key: 'plans' })
  const baseline = plansData?.plans.enterprise

  const [form, setForm] = useState<PlanDefinition | null>(null)
  const [notes, setNotes] = useState('')
  const [saving, setSaving] = useState(false)
  const [err, setErr] = useState<string | null>(null)

  useEffect(() => {
    if (!baseline) return
    setForm({ ...baseline, ...business.enterpriseOverrides })
    setNotes(business.enterpriseOverrides?.notes ?? '')
  }, [baseline, business.enterpriseOverrides])

  function num(field: keyof PlanDefinition) {
    return (e: React.ChangeEvent<HTMLInputElement>) =>
      setForm((f) => f ? { ...f, [field]: Number(e.target.value) } : f)
  }
  function bool(field: keyof PlanDefinition) {
    return (v: boolean) => setForm((f) => f ? { ...f, [field]: v } : f)
  }

  async function handleSave() {
    if (!form) return
    setSaving(true); setErr(null)
    try {
      await setEnterpriseTerms(uid, bizId, { ...form, notes: notes.trim() || undefined })
      onSaved()
    } catch (e: unknown) {
      setErr(e instanceof Error ? e.message : 'Failed to save terms')
    } finally {
      setSaving(false)
    }
  }

  async function handleClear() {
    setSaving(true); setErr(null)
    try {
      await setEnterpriseTerms(uid, bizId, {})
      onSaved()
    } catch (e: unknown) {
      setErr(e instanceof Error ? e.message : 'Failed to clear terms')
    } finally {
      setSaving(false)
    }
  }

  if (!form) return <SkeletonPanel />

  const hasOverride = !!business.enterpriseOverrides

  return (
    <div className="rounded-lg border border-[var(--line)] bg-[var(--surface)] p-6">
      <div className="flex items-center justify-between mb-1">
        <div className="flex items-center gap-2">
          <Star className="h-4 w-4 text-[var(--accent)]" />
          <h3 className="text-[14px] font-semibold text-[var(--ink)]">Enterprise Deal Terms</h3>
        </div>
        {hasOverride && (
          <button
            onClick={handleClear}
            disabled={saving}
            className="text-[12px] font-medium text-[var(--ink-muted)] hover:text-[var(--status-bad)] transition-colors disabled:opacity-50"
          >
            Clear custom terms
          </button>
        )}
      </div>
      <p className="text-[12px] text-[var(--ink-muted)] mb-5">
        {hasOverride
          ? `Custom terms set${business.enterpriseOverrides?.setBy ? ` by ${business.enterpriseOverrides.setBy}` : ''}${business.enterpriseOverrides?.setAt ? ` on ${formatDate(business.enterpriseOverrides.setAt)}` : ''}. Overrides the shared Enterprise defaults for this business only.`
          : 'This business uses the shared Enterprise defaults. Set custom pricing, limits, or features for this specific deal below.'}
      </p>

      <div className="grid grid-cols-2 gap-3 mb-5">
        <div className="flex flex-col gap-1.5">
          <label className={labelCls}>Price per billing cycle (TZS)</label>
          <input type="number" min="0" value={form.pricePerCycle} onChange={num('pricePerCycle')} className={inputCls} />
        </div>
        <div className="flex flex-col gap-1.5">
          <label className={labelCls}>Billing cycle (months)</label>
          <input type="number" min="1" max="24" value={form.cycleMonths} onChange={num('cycleMonths')} className={inputCls} />
        </div>
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
          <input type="number" min="-1" value={form.maxBusinesses} onChange={num('maxBusinesses')} className={inputCls} />
        </div>
        <div className="flex flex-col gap-1.5">
          <label className={labelCls}>Max customers (−1 = unlimited)</label>
          <input type="number" min="-1" value={form.maxCustomers} onChange={num('maxCustomers')} className={inputCls} />
        </div>
      </div>

      <div className="grid grid-cols-2 gap-x-6 gap-y-2 mb-5">
        {(Object.keys(OVERRIDE_FEATURE_LABELS) as (keyof typeof OVERRIDE_FEATURE_LABELS)[]).map((key) => (
          <div key={key} className="flex items-center justify-between py-1 border-b border-[var(--line)] last:border-0">
            <span className="text-[13px] text-[var(--ink-muted)]">{OVERRIDE_FEATURE_LABELS[key]}</span>
            <Toggle checked={form[key]} onChange={bool(key)} />
          </div>
        ))}
      </div>

      <div className="flex flex-col gap-1.5 mb-4">
        <label className={labelCls}>Deal notes (internal)</label>
        <textarea
          value={notes}
          onChange={(e) => setNotes(e.target.value)}
          rows={2}
          placeholder="e.g. negotiated Jan 2026, 24-month contract, discount for early payment…"
          className={`${inputCls} resize-none`}
        />
      </div>

      {err && (
        <div className="mb-4 flex items-center gap-2.5 rounded-lg border border-[var(--status-bad)] bg-[var(--status-bad-bg)] p-3 text-[12px] text-[var(--status-bad)]">
          <AlertCircle className="h-4 w-4 shrink-0" />
          {err}
        </div>
      )}

      <div className="flex justify-end">
        <button
          onClick={handleSave}
          disabled={saving}
          style={{ backgroundColor: '#0D1B3E' }}
          className="rounded-md px-4 py-2 text-[12px] font-medium text-white hover:opacity-90 transition-opacity disabled:opacity-50"
        >
          {saving ? 'Saving…' : 'Save deal terms'}
        </button>
      </div>
    </div>
  )
}

const inputCls = 'w-full rounded-md border border-[var(--line)] bg-[var(--canvas)] px-3 py-2 text-[13px] text-[var(--ink)] focus:outline-none focus:ring-1 focus:ring-[var(--accent)]'
const labelCls = 'text-[12px] font-medium text-[var(--ink-muted)]'

function SkeletonPanel() {
  return (
    <div className="rounded-lg border border-[var(--line)] bg-[var(--surface)] p-6 space-y-3">
      <div className="h-4 w-48 bg-[var(--canvas)] rounded animate-pulse" />
      <div className="h-9 w-full bg-[var(--canvas)] rounded animate-pulse" />
      <div className="h-24 w-full bg-[var(--canvas)] rounded animate-pulse" />
    </div>
  )
}

// ─── Page ─────────────────────────────────────────────────────────────────────

export default function BusinessDetailPage() {
  const { uid, bizId } = useParams<{ uid: string; bizId: string }>()
  const router = useRouter()
  const { data: session } = useSession()

  const [tab, setTab] = useState('overview')
  const [showSuspend, setShowSuspend] = useState(false)
  const [showUnsuspend, setShowUnsuspend] = useState(false)
  const [actionPending, setActionPending] = useState(false)
  const [noteInput, setNoteInput] = useState('')
  const [savingNote, setSavingNote] = useState(false)
  const [showEdit, setShowEdit] = useState(false)
  const [showDelete, setShowDelete] = useState(false)
  const [deleting, setDeleting] = useState(false)

  const { data, loading, error, refetch } = useAdminFetch(
    useCallback(() => fetchBusiness(uid, bizId), [uid, bizId])
  )

  const business = data?.business
  const isSuspended = business?.status === 'suspended'

  async function handleToggleSuspend() {
    if (!business) return
    setActionPending(true)
    try {
      await patchBusiness(uid, bizId, isSuspended)
      invalidateAdminCache(['analytics', 'businesses'])
      refetch()
    } finally {
      setActionPending(false)
      setShowSuspend(false)
      setShowUnsuspend(false)
    }
  }

  async function handleDelete() {
    if (!business) return
    setDeleting(true)
    try {
      await deleteBusiness(uid, bizId)
      invalidateAdminCache(['analytics', 'businesses', 'users'])
      router.push('/admin/businesses')
    } finally {
      setDeleting(false)
      setShowDelete(false)
    }
  }

  async function handleAddNote() {
    if (!noteInput.trim()) return
    setSavingNote(true)
    try {
      await postBusinessNote(uid, bizId, noteInput.trim(), session?.user?.name ?? 'Admin')
      setNoteInput('')
      refetch()
    } finally {
      setSavingNote(false)
    }
  }

  if (loading) {
    return (
      <div>
        <Skeleton className="h-4 w-28 mb-4" />
        <Skeleton className="h-8 w-72 mb-2" />
        <Skeleton className="h-4 w-48 mb-6" />
        <div className="space-y-2">
          {Array.from({ length: 4 }).map((_, i) => <Skeleton key={i} className="h-12 w-full" />)}
        </div>
      </div>
    )
  }

  if (error || !business) {
    return (
      <div className="text-center py-16">
        <div className="inline-flex items-center gap-2 text-[var(--status-bad)] mb-3">
          <AlertCircle className="h-4 w-4" />
          <span className="text-[13px]">{error ?? 'Business not found'}</span>
        </div>
        <br />
        <button onClick={() => router.back()} className="text-[12px] text-[var(--accent)] hover:underline">
          Go back
        </button>
      </div>
    )
  }

  const staff: StaffMember[] = business.staffMembers ?? []

  return (
    <div>
      <button
        onClick={() => router.back()}
        className="flex items-center gap-1.5 text-[12px] text-[var(--ink-muted)] hover:text-[var(--ink)] mb-4 transition-colors"
      >
        <ArrowLeft className="h-3.5 w-3.5" />
        Back to businesses
      </button>

      <PageHeader
        title={business.name}
        description={`${business.industry}${business.location ? ` · ${business.location}` : ''}`}
      >
        <div className="flex items-center gap-2">
          <button
            onClick={() => setShowEdit(true)}
            className="inline-flex items-center gap-1.5 rounded-md border border-white/10 bg-white/[0.05] px-3 py-1.5 text-[12px] font-medium text-slate-300 hover:text-white hover:bg-white/10 transition-colors"
          >
            <Pencil className="h-3.5 w-3.5" />
            Edit
          </button>
          {isSuspended ? (
            <button
              onClick={() => setShowUnsuspend(true)}
              className="inline-flex items-center gap-1.5 rounded-md bg-[var(--status-good)] px-3 py-1.5 text-[12px] font-medium text-white hover:opacity-90 transition-opacity"
            >
              <RotateCcw className="h-3.5 w-3.5" />
              Unsuspend
            </button>
          ) : (
            <button
              onClick={() => setShowSuspend(true)}
              className="inline-flex items-center gap-1.5 rounded-md border border-[var(--status-bad)] bg-[var(--status-bad-bg)] px-3 py-1.5 text-[12px] font-medium text-[var(--status-bad)] hover:bg-[var(--status-bad)] hover:text-white transition-colors"
            >
              <Ban className="h-3.5 w-3.5" />
              Suspend
            </button>
          )}
          <button
            onClick={() => setShowDelete(true)}
            className="inline-flex items-center gap-1.5 rounded-md bg-[var(--status-bad)] px-3 py-1.5 text-[12px] font-medium text-white hover:opacity-90 transition-opacity"
          >
            <Trash2 className="h-3.5 w-3.5" />
            Delete
          </button>
        </div>
      </PageHeader>

      {/* Header strip */}
      <div className="flex flex-wrap items-center gap-6 mb-5 p-4 rounded-lg border border-[var(--line)] bg-[var(--surface)]">
        <div className="flex items-center gap-2">
          <PlanBadge tier={business.plan} />
          <StatusDot
            status={business.status === 'active' ? 'good' : business.status === 'suspended' ? 'bad' : 'warn'}
            label={business.status.charAt(0).toUpperCase() + business.status.slice(1)}
            meta={timeAgo(business.lastActive)}
          />
        </div>
        <div className="text-[12px] text-[var(--ink-muted)]">
          Owner: <span className="text-[var(--ink)] font-medium">{business.ownerName || '—'}</span>
          {business.ownerPhone && (
            <span className="ml-2 font-mono text-[var(--ink-faint)]">{business.ownerPhone}</span>
          )}
        </div>
        <div className="text-[12px] text-[var(--ink-muted)] font-mono">
          ID: <span className="text-[var(--ink-faint)]">{business.id}</span>
        </div>
        <div className="text-[12px] text-[var(--ink-muted)] ml-auto">
          Joined {formatDate(business.createdAt)}
        </div>
      </div>

      {/* Quick stat pills */}
      <div className="grid grid-cols-4 gap-3 mb-5">
        <div className="flex items-center gap-2.5 rounded-lg border border-[var(--line)] bg-[var(--surface)] px-4 py-3">
          <Users className="h-4 w-4 text-[var(--accent)]" />
          <div>
            <div className="text-[18px] font-semibold font-mono text-[var(--ink)]">{business.staffCount}</div>
            <div className="text-[11px] text-[var(--ink-faint)]">Team members</div>
          </div>
        </div>
        <div className="flex items-center gap-2.5 rounded-lg border border-[var(--line)] bg-[var(--surface)] px-4 py-3">
          <Receipt className="h-4 w-4 text-[var(--accent)]" />
          <div>
            <div className="text-[18px] font-semibold font-mono text-[var(--ink)]">{business.invoiceCount ?? 0}</div>
            <div className="text-[11px] text-[var(--ink-faint)]">Invoices</div>
          </div>
        </div>
        <div className="flex items-center gap-2.5 rounded-lg border border-[var(--line)] bg-[var(--surface)] px-4 py-3">
          <ShoppingBag className="h-4 w-4 text-[var(--accent)]" />
          <div>
            <div className="text-[18px] font-semibold font-mono text-[var(--ink)]">{business.customerCount ?? 0}</div>
            <div className="text-[11px] text-[var(--ink-faint)]">Customers</div>
          </div>
        </div>
        <div className="flex items-center gap-2.5 rounded-lg border border-[var(--line)] bg-[var(--surface)] px-4 py-3">
          <UserCheck className="h-4 w-4 text-[var(--accent)]" />
          <div>
            <div className="text-[12px] font-semibold text-[var(--ink)]">{timeAgo(business.lastActive)}</div>
            <div className="text-[11px] text-[var(--ink-faint)]">Last active</div>
          </div>
        </div>
      </div>

      <Tabs tabs={TABS} active={tab} onChange={setTab} className="mb-6" />

      {/* Overview */}
      {tab === 'overview' && (
        <div className="grid grid-cols-3 gap-4">
          <KPICard label="Plan" value={business.plan.charAt(0).toUpperCase() + business.plan.slice(1)} mono={false} />
          <KPICard label="Status" value={business.status.charAt(0).toUpperCase() + business.status.slice(1)} mono={false} />
          <KPICard label="Industry" value={business.industry} mono={false} />
          {business.location && <KPICard label="Location" value={business.location} mono={false} />}
          <KPICard label="Joined" value={formatDate(business.createdAt)} mono={false} />
          <KPICard label="Last Active" value={timeAgo(business.lastActive)} mono={false} />
          {business.totalRevenue != null && (
            <KPICard label="Total Revenue" value={formatTZS(business.totalRevenue)} />
          )}
          {business.receivables != null && (
            <KPICard label="Outstanding Receivables" value={formatTZS(business.receivables)} />
          )}
        </div>
      )}

      {/* Team */}
      {tab === 'team' && (
        <div className="rounded-lg border border-[var(--line)] bg-[var(--surface)] overflow-hidden">
          {staff.length === 0 ? (
            <div className="p-8 text-center">
              <Users className="h-8 w-8 text-[var(--ink-faint)] mx-auto mb-2" />
              <p className="text-[13px] text-[var(--ink-muted)]">No team members found.</p>
              <p className="text-[12px] text-[var(--ink-faint)] mt-1">The business may not have invited any staff yet.</p>
            </div>
          ) : (
            <table className="w-full text-[13px]">
              <thead>
                <tr className="border-b border-[var(--line)] bg-[var(--canvas)]">
                  <th className="px-4 py-2.5 text-left text-[11px] font-medium text-[var(--ink-faint)] uppercase tracking-wide">Member</th>
                  <th className="px-4 py-2.5 text-left text-[11px] font-medium text-[var(--ink-faint)] uppercase tracking-wide">Role</th>
                  <th className="px-4 py-2.5 text-left text-[11px] font-medium text-[var(--ink-faint)] uppercase tracking-wide">Status</th>
                  <th className="px-4 py-2.5 text-left text-[11px] font-medium text-[var(--ink-faint)] uppercase tracking-wide">Joined</th>
                </tr>
              </thead>
              <tbody>
                {staff.map((m, i) => (
                  <tr key={m.id} className={`border-b border-[var(--line)] last:border-0 ${i % 2 === 1 ? 'bg-[var(--canvas)]' : ''}`}>
                    <td className="px-4 py-3">
                      <div className="font-medium text-[var(--ink)]">{m.name}</div>
                      {m.phone && <div className="text-[11px] text-[var(--ink-faint)] font-mono">{m.phone}</div>}
                    </td>
                    <td className="px-4 py-3"><RoleBadge role={m.role} /></td>
                    <td className="px-4 py-3">
                      <StatusDot
                        status={m.status === 'active' ? 'good' : m.status === 'suspended' ? 'bad' : 'warn'}
                        label={m.status.charAt(0).toUpperCase() + m.status.slice(1)}
                      />
                    </td>
                    <td className="px-4 py-3 text-[var(--ink-muted)]">{formatDate(m.invitedAt)}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </div>
      )}

      {/* Financial */}
      {tab === 'financial' && (
        <div className="grid grid-cols-2 gap-4">
          <KPICard label="Total Invoices" value={(business.invoiceCount ?? 0).toString()} mono={false} />
          <KPICard label="Total Customers" value={(business.customerCount ?? 0).toString()} mono={false} />
          <KPICard
            label="Total Revenue"
            value={business.totalRevenue != null ? formatTZS(business.totalRevenue) : '—'}
          />
          <KPICard
            label="Outstanding Receivables"
            value={business.receivables != null ? formatTZS(business.receivables) : '—'}
          />
          <KPICard
            label="Total Expenses"
            value={business.expenseTotal != null ? formatTZS(business.expenseTotal) : '—'}
          />
          {business.mrr > 0 && (
            <KPICard label="Monthly Revenue (plan)" value={formatTZS(business.mrr)} />
          )}
        </div>
      )}

      {/* Subscription */}
      {tab === 'subscription' && (
        <div className="rounded-lg border border-[var(--line)] bg-[var(--surface)] p-6">
          <div className="flex items-center gap-3 mb-4">
            <PlanBadge tier={business.plan} />
            {business.plan === 'lifetime' && (
              <span className="text-[12px] text-[var(--ink-muted)]">Lifetime program — UTT AMIS invested</span>
            )}
          </div>
          {business.plan !== 'lifetime' && business.mrr > 0 && (
            <div className="text-[24px] font-mono font-semibold text-[var(--ink)]">
              {formatTZS(business.mrr)}
              <span className="text-[14px] text-[var(--ink-muted)] font-sans font-normal ml-2">/month</span>
            </div>
          )}
          {business.plan === 'starter' && (
            <p className="mt-2 text-[13px] text-[var(--ink-muted)]">Free trial — no recurring charge.</p>
          )}
          {business.plan === 'lifetime' && (
            <div className="mt-2 text-[13px] text-[var(--ink-muted)]">
              View full UTT AMIS details on the{' '}
              <a href="/admin/subscriptions?tab=lifetime" className="text-[var(--accent)] hover:underline">Subscriptions page</a>.
            </div>
          )}
        </div>
      )}
      {tab === 'subscription' && business.plan === 'enterprise' && (
        <div className="mt-4">
          <EnterpriseTermsPanel uid={uid} bizId={bizId} business={business} onSaved={refetch} />
        </div>
      )}

      {/* Catalog */}
      {tab === 'catalog' && (
        <CatalogAttachPanel
          uid={uid}
          bizId={bizId}
          businessName={business.name}
          industry={business.industry}
        />
      )}

      {/* Notes */}
      {tab === 'notes' && (
        <div className="rounded-lg border border-[var(--line)] bg-[var(--surface)] p-6">
          <h3 className="text-[14px] font-semibold text-[var(--ink)] mb-4">Internal Notes</h3>
          {(!business.notes || business.notes.length === 0) && (
            <p className="text-[13px] text-[var(--ink-faint)] mb-4">No notes yet. Add context for the support team.</p>
          )}
          {business.notes?.map((note) => (
            <div key={note.id} className="mb-3 rounded-md bg-[var(--canvas)] border border-[var(--line)] p-3">
              <div className="flex items-center gap-2 mb-1">
                <span className="text-[12px] font-medium text-[var(--ink)]">{note.author}</span>
                <span className="text-[11px] text-[var(--ink-faint)]">{formatDate(note.createdAt)}</span>
              </div>
              <p className="text-[13px] text-[var(--ink-muted)]">{note.content}</p>
            </div>
          ))}
          <div className="mt-4 flex gap-2">
            <input
              value={noteInput}
              onChange={(e) => setNoteInput(e.target.value)}
              onKeyDown={(e) => e.key === 'Enter' && !e.shiftKey && handleAddNote()}
              placeholder="Add a note…"
              className="flex-1 rounded-md border border-[var(--line)] bg-[var(--canvas)] px-3 py-2 text-[13px] focus:outline-none focus:ring-1 focus:ring-[var(--accent)]"
            />
            <button
              onClick={handleAddNote}
              disabled={savingNote || !noteInput.trim()}
              style={{ backgroundColor: '#FFC107', color: '#0D1B3E' }}
              className="inline-flex items-center gap-1.5 rounded-md px-3 py-2 text-[12px] font-medium hover:opacity-90 transition-opacity disabled:opacity-50"
            >
              <MessageSquarePlus className="h-3.5 w-3.5" />
              {savingNote ? 'Saving…' : 'Add'}
            </button>
          </div>
        </div>
      )}

      <ConfirmDialog
        open={showSuspend}
        onClose={() => setShowSuspend(false)}
        onConfirm={handleToggleSuspend}
        title={`Suspend ${business.name}?`}
        consequence="Suspending blocks sign-in immediately for all staff. Their business data is untouched and can be restored by unsuspending."
        confirmLabel={actionPending ? 'Saving…' : 'Suspend business'}
        variant="destructive"
      />
      <ConfirmDialog
        open={showUnsuspend}
        onClose={() => setShowUnsuspend(false)}
        onConfirm={handleToggleSuspend}
        title={`Unsuspend ${business.name}?`}
        consequence="Restoring access will allow all staff to sign in immediately. Make sure the reason for suspension has been resolved."
        confirmLabel={actionPending ? 'Saving…' : 'Unsuspend business'}
        variant="warning"
      />

      <DeleteConfirmDialog
        open={showDelete}
        onClose={() => setShowDelete(false)}
        onConfirm={handleDelete}
        resourceLabel="business"
        resourceName={business.name}
        consequence={`This permanently deletes ${business.name} and all of its data — invoices, customers, staff, inventory, expenses, and everything else. This cannot be undone.`}
        loading={deleting}
      />

      <EditBusinessDrawer
        business={business}
        uid={uid}
        bizId={bizId}
        open={showEdit}
        onClose={() => setShowEdit(false)}
        onSaved={() => { setShowEdit(false); invalidateAdminCache(['businesses', 'analytics']); refetch() }}
      />
    </div>
  )
}
