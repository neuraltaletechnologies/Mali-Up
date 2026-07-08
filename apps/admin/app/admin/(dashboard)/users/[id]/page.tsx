'use client'

import { useState, useCallback, useEffect } from 'react'
import { useParams, useRouter } from 'next/navigation'
import { PageHeader } from '@/components/ui/page-header'
import { StatusDot } from '@/components/ui/status-dot'
import { PlanBadge } from '@/components/ui/plan-badge'
import { Tabs } from '@/components/ui/tabs'
import { ConfirmDialog } from '@/components/ui/confirm-dialog'
import { DeleteConfirmDialog } from '@/components/ui/delete-confirm-dialog'
import { Skeleton } from '@/components/ui/skeleton'
import { fetchUser, patchUser, editUser, deleteUser, assignPlan, fetchUserActivity } from '@/lib/admin-api'
import type { ActivityEntry } from '@/lib/admin-api'
import { useAdminFetch, invalidateAdminCache } from '@/hooks/use-admin-fetch'
import { formatDate, timeAgo } from '@/lib/format'
import { ArrowLeft, Ban, RotateCcw, AlertCircle, Pencil, X, Loader2, Building2,
  ShoppingCart, FileText, CreditCard, RefreshCw, XCircle, Trash2, Users, UserPlus,
  UserMinus, UserCheck, Tag, Bell, Settings, Shield, TrendingUp } from 'lucide-react'
import Link from 'next/link'
import type { AdminUser, Business, PlanTier } from '@/types'

const TABS = [
  { id: 'overview',   label: 'Overview' },
  { id: 'businesses', label: 'Businesses' },
  { id: 'activity',   label: 'Activity' },
]

// ─── Edit Drawer ──────────────────────────────────────────────────────────────

const PLAN_OPTIONS: PlanTier[] = ['starter', 'growth', 'business', 'enterprise', 'lifetime']

function EditUserDrawer({
  user,
  businesses,
  open,
  onClose,
  onSaved,
}: {
  user: AdminUser
  businesses: Business[]
  open: boolean
  onClose: () => void
  onSaved: () => void
}) {
  const [name,  setName]  = useState(user.name)
  const [phone, setPhone] = useState(user.phone.replace(/^\+255/, ''))
  const [email,  setEmail]  = useState(user.email ?? '')
  const [saving, setSaving] = useState(false)
  const [err,    setErr]    = useState<string | null>(null)

  // Plan change state
  const [planBizId, setPlanBizId] = useState(businesses[0]?.id ?? '')
  const [newPlan,   setNewPlan]   = useState<string>(businesses[0]?.plan ?? 'starter')
  const [cycleMonths, setCycleMonths] = useState(6)

  // Reset all fields when the drawer opens (or when user/businesses data changes)
  useEffect(() => {
    if (!open) return
    setName(user.name)
    setPhone(user.phone.replace(/^\+255/, ''))
    setEmail(user.email ?? '')
    setErr(null)
    const first = businesses[0]
    setPlanBizId(first?.id ?? '')
    setNewPlan(first?.plan ?? 'starter')
    setCycleMonths(6)
  }, [open, user, businesses])

  // When the selected business changes, reflect its current plan
  useEffect(() => {
    const biz = businesses.find((b) => b.id === planBizId)
    if (biz) setNewPlan(biz.plan)
  }, [planBizId, businesses])

  const selectedBiz  = businesses.find((b) => b.id === planBizId)
  const planChanged  = !!selectedBiz && newPlan !== selectedBiz.plan
  const paidPlan     = newPlan !== 'starter' && newPlan !== 'enterprise' && newPlan !== 'lifetime'

  async function handleSave(e: React.FormEvent) {
    e.preventDefault()
    if (!name.trim()) { setErr('Name is required.'); return }
    setSaving(true); setErr(null)
    try {
      await editUser(user.id, {
        name:  name.trim(),
        phone: phone.trim() || undefined,
        email: email.trim() || undefined,
      })
      if (planBizId && planChanged) {
        await assignPlan(user.id, planBizId, newPlan as PlanTier, cycleMonths)
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
          <h2 className="text-[15px] font-semibold text-white">Edit User</h2>
          <button onClick={onClose} className="p-1 rounded-md text-slate-400 hover:text-white hover:bg-white/10 transition-colors">
            <X className="h-4 w-4" />
          </button>
        </div>
        <form onSubmit={handleSave} className="flex-1 overflow-y-auto px-6 py-5 flex flex-col gap-4">
          <DrawerField label="Full Name" value={name} onChange={setName} placeholder="e.g. Amina Juma" required />
          <DrawerField label="Phone (TZ digits)" value={phone} onChange={setPhone} placeholder="712345678" type="tel" />
          <DrawerField label="Email (optional)" value={email} onChange={setEmail} placeholder="user@example.com" type="email" />

          {/* ── Plan change ── */}
          {businesses.length > 0 && (
            <div className="flex flex-col gap-3 pt-3 border-t border-white/[0.07]">
              <span className="text-[11px] uppercase tracking-wide text-slate-500">Subscription Plan</span>

              {businesses.length > 1 && (
                <label className="flex flex-col gap-1">
                  <span className="text-[11px] text-slate-400">Business</span>
                  <select
                    value={planBizId}
                    onChange={(e) => setPlanBizId(e.target.value)}
                    className="rounded-md border border-white/10 bg-white/[0.05] px-3 py-2 text-[13px] text-white focus:outline-none focus:ring-1 focus:ring-[var(--accent)]"
                  >
                    {businesses.map((b) => (
                      <option key={b.id} value={b.id} className="bg-[#0D1B3E]">{b.name}</option>
                    ))}
                  </select>
                </label>
              )}

              <label className="flex flex-col gap-1">
                <span className="text-[11px] text-slate-400">
                  Plan{selectedBiz ? ` — current: ${selectedBiz.plan}` : ''}
                </span>
                <select
                  value={newPlan}
                  onChange={(e) => setNewPlan(e.target.value)}
                  className="rounded-md border border-white/10 bg-white/[0.05] px-3 py-2 text-[13px] text-white focus:outline-none focus:ring-1 focus:ring-[var(--accent)]"
                >
                  {PLAN_OPTIONS.map((p) => (
                    <option key={p} value={p} className="bg-[#0D1B3E]">
                      {p.charAt(0).toUpperCase() + p.slice(1)}
                    </option>
                  ))}
                </select>
              </label>

              {paidPlan && (
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
                  Plan: {selectedBiz?.plan} → {newPlan}{paidPlan ? ` (${cycleMonths} months)` : ''}
                </p>
              )}
            </div>
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

function DrawerField({
  label, value, onChange, placeholder, type = 'text', required,
}: {
  label: string; value: string; onChange: (v: string) => void
  placeholder?: string; type?: string; required?: boolean
}) {
  return (
    <label className="flex flex-col gap-1">
      <span className="text-[11px] text-slate-400">{label}{required && <span className="text-red-400 ml-0.5">*</span>}</span>
      <input
        type={type}
        value={value}
        onChange={(e) => onChange(e.target.value)}
        placeholder={placeholder}
        required={required}
        className="rounded-md border border-white/10 bg-white/[0.05] px-3 py-2 text-[13px] text-white placeholder:text-slate-600 focus:outline-none focus:ring-1 focus:ring-[var(--accent)]"
      />
    </label>
  )
}

// ─── Page ─────────────────────────────────────────────────────────────────────

export default function UserDetailPage() {
  const { id } = useParams<{ id: string }>()
  const router  = useRouter()

  const [tab,          setTab]          = useState('overview')
  const [showSuspend,  setShowSuspend]  = useState(false)
  const [actionPending, setActionPending] = useState(false)
  const [showEdit,     setShowEdit]     = useState(false)
  const [showDelete,   setShowDelete]   = useState(false)
  const [deleting,     setDeleting]     = useState(false)

  const { data, loading, error, refetch } = useAdminFetch(
    useCallback(() => fetchUser(id), [id])
  )

  const { data: activityData, loading: activityLoading } = useAdminFetch(
    useCallback(() => fetchUserActivity(id), [id])
  )

  const user       = data?.user
  const businesses = data?.businesses ?? []
  const isSuspended = user?.status === 'suspended'

  async function handleToggleSuspend() {
    if (!user) return
    setActionPending(true)
    try {
      await patchUser(user.id, isSuspended)
      invalidateAdminCache(['analytics', 'users'])
      refetch()
    } finally {
      setActionPending(false)
      setShowSuspend(false)
    }
  }

  async function handleDelete() {
    if (!user) return
    setDeleting(true)
    try {
      await deleteUser(user.id)
      invalidateAdminCache(['analytics', 'users', 'businesses'])
      router.push('/admin/users')
    } finally {
      setDeleting(false)
      setShowDelete(false)
    }
  }

  if (loading) {
    return (
      <div>
        <Skeleton className="h-4 w-24 mb-4" />
        <Skeleton className="h-8 w-64 mb-2" />
        <Skeleton className="h-4 w-48 mb-6" />
        <div className="space-y-2">
          {Array.from({ length: 4 }).map((_, i) => <Skeleton key={i} className="h-12 w-full" />)}
        </div>
      </div>
    )
  }

  if (error || !user) {
    return (
      <div className="text-center py-16">
        <div className="inline-flex items-center gap-2 text-[var(--status-bad)] mb-3">
          <AlertCircle className="h-4 w-4" />
          <span className="text-[13px]">{error ?? 'User not found'}</span>
        </div>
        <br />
        <button onClick={() => router.back()} className="text-[12px] text-[var(--accent)] hover:underline">
          Go back
        </button>
      </div>
    )
  }

  return (
    <div>
      <button
        onClick={() => router.back()}
        className="flex items-center gap-1.5 text-[12px] text-[var(--ink-muted)] hover:text-[var(--ink)] mb-4 transition-colors"
      >
        <ArrowLeft className="h-3.5 w-3.5" />
        Back to users
      </button>

      <PageHeader title={user.name} description={user.phone}>
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
              onClick={() => setShowSuspend(true)}
              className="inline-flex items-center gap-1.5 rounded-md bg-[var(--status-good)] px-3 py-1.5 text-[12px] font-medium text-white hover:opacity-90"
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

      <div className="flex flex-wrap items-center gap-4 mb-5 p-4 rounded-lg border border-[var(--line)] bg-[var(--surface)]">
        <StatusDot
          status={user.status === 'active' ? 'good' : user.status === 'suspended' ? 'bad' : 'warn'}
          label={user.status.charAt(0).toUpperCase() + user.status.slice(1)}
        />
        <div className="flex items-center gap-1.5 text-[12px] text-[var(--ink-muted)]">
          <Building2 className="h-3.5 w-3.5" />
          {businesses.length} business{businesses.length !== 1 ? 'es' : ''}
        </div>
        <span className="text-[12px] text-[var(--ink-muted)]">
          Last login {timeAgo(user.lastLogin)}
        </span>
        <span className="text-[12px] font-mono text-[var(--ink-faint)] ml-auto text-[11px]">
          uid: {user.id}
        </span>
      </div>

      <Tabs tabs={TABS} active={tab} onChange={setTab} className="mb-6" />

      {/* Overview */}
      {tab === 'overview' && (
        <div className="rounded-lg border border-[var(--line)] bg-[var(--surface)] p-6">
          <div className="grid grid-cols-2 gap-6 text-[13px]">
            <Field label="Full name"  value={user.name} />
            <Field label="Phone"      value={user.phone} mono />
            {user.email && <Field label="Email" value={user.email} />}
            <Field label="Status"     value={user.status.charAt(0).toUpperCase() + user.status.slice(1)} />
            <Field label="Last login" value={timeAgo(user.lastLogin)} />
            <Field label="Joined"     value={formatDate(user.joinedAt)} />
          </div>
        </div>
      )}

      {/* Businesses */}
      {tab === 'businesses' && (
        <div className="flex flex-col gap-3">
          {businesses.length === 0 ? (
            <div className="rounded-lg border border-[var(--line)] bg-[var(--surface)] p-8 text-center">
              <Building2 className="h-8 w-8 text-[var(--ink-faint)] mx-auto mb-2" />
              <p className="text-[13px] text-[var(--ink-muted)]">No businesses found for this user.</p>
              <p className="text-[12px] text-[var(--ink-faint)] mt-1">
                The user may not have created a business during onboarding yet.
              </p>
            </div>
          ) : (
            businesses.map((b) => (
              <Link
                key={b.id}
                href={`/admin/businesses/${user.id}/${b.id}`}
                className="flex items-center justify-between rounded-lg border border-[var(--line)] bg-[var(--surface)] p-4 hover:border-[var(--accent)] transition-colors group"
              >
                <div className="min-w-0">
                  <div className="font-medium text-[var(--ink)] group-hover:text-[var(--accent)] transition-colors truncate">
                    {b.name}
                  </div>
                  <div className="text-[11px] text-[var(--ink-muted)] mt-0.5">
                    {b.industry}
                    {b.location ? ` · ${b.location}` : ''}
                    {` · ${b.staffCount} staff`}
                  </div>
                </div>
                <div className="flex items-center gap-3 shrink-0 ml-4">
                  <PlanBadge tier={b.plan} />
                  <StatusDot
                    status={b.status === 'active' ? 'good' : b.status === 'suspended' ? 'bad' : 'warn'}
                    label={b.status.charAt(0).toUpperCase() + b.status.slice(1)}
                  />
                </div>
              </Link>
            ))
          )}
        </div>
      )}

      {/* Activity */}
      {tab === 'activity' && (
        <ActivityTab entries={activityData?.entries ?? []} loading={activityLoading} />
      )}

      <ConfirmDialog
        open={showSuspend}
        onClose={() => setShowSuspend(false)}
        onConfirm={handleToggleSuspend}
        title={isSuspended ? `Unsuspend ${user.name}?` : `Suspend ${user.name}?`}
        consequence={
          isSuspended
            ? 'Restoring access allows this user to sign in immediately across all their businesses.'
            : 'Suspending blocks sign-in immediately. Their business data is untouched.'
        }
        confirmLabel={actionPending ? 'Saving…' : isSuspended ? 'Unsuspend user' : 'Suspend user'}
        variant={isSuspended ? 'warning' : 'destructive'}
      />

      <DeleteConfirmDialog
        open={showDelete}
        onClose={() => setShowDelete(false)}
        onConfirm={handleDelete}
        resourceLabel="user"
        resourceName={user.name}
        consequence={`This permanently deletes ${user.name}'s account, sign-in, and ${businesses.length} owned business${businesses.length !== 1 ? 'es' : ''} (including all invoices, customers, staff, and other data). This cannot be undone.`}
        loading={deleting}
      />

      {user && (
        <EditUserDrawer
          user={user}
          businesses={businesses}
          open={showEdit}
          onClose={() => setShowEdit(false)}
          onSaved={() => { setShowEdit(false); invalidateAdminCache(['users', 'analytics']); refetch() }}
        />
      )}
    </div>
  )
}

// ─── Activity Tab ─────────────────────────────────────────────────────────────

const ACTION_ICONS: Record<string, React.ElementType> = {
  sale_created:        ShoppingCart,
  invoice_edited:      FileText,
  payment_received:    CreditCard,
  return_processed:    RefreshCw,
  invoice_cancelled:   XCircle,
  invoice_deleted:     Trash2,
  quotation_converted: FileText,
  customer_created:    UserPlus,
  customer_updated:    Users,
  customer_deleted:    UserMinus,
  credit_limit_changed: TrendingUp,
  tag_added:           Tag,
  tag_removed:         Tag,
  reminder_sent:       Bell,
  member_invited:      UserPlus,
  member_removed:      UserMinus,
  member_suspended:    UserMinus,
  member_activated:    UserCheck,
  role_changed:        Shield,
  permissions_changed: Shield,
  edit_user:           Settings,
  suspend_user:        Ban,
  unsuspend_user:      RotateCcw,
}

const ACTION_LABELS: Record<string, string> = {
  sale_created:        'Sale created',
  invoice_edited:      'Invoice edited',
  payment_received:    'Payment received',
  return_processed:    'Return processed',
  invoice_cancelled:   'Invoice cancelled',
  invoice_deleted:     'Invoice deleted',
  quotation_converted: 'Quotation converted',
  customer_created:    'Customer added',
  customer_updated:    'Customer updated',
  customer_deleted:    'Customer deleted',
  credit_limit_changed:'Credit limit changed',
  tag_added:           'Tag added',
  tag_removed:         'Tag removed',
  reminder_sent:       'Reminder sent',
  member_invited:      'Member invited',
  member_removed:      'Member removed',
  member_suspended:    'Member suspended',
  member_activated:    'Member activated',
  role_changed:        'Role changed',
  permissions_changed: 'Permissions changed',
  edit_user:           'Profile edited',
  suspend_user:        'User suspended',
  unsuspend_user:      'User unsuspended',
}

function actionColor(action: string): string {
  if (action.includes('cancel') || action.includes('delete') || action.includes('suspend') || action.includes('removed')) {
    return 'text-[var(--status-bad)] bg-[var(--status-bad-bg)]'
  }
  if (action.includes('payment') || action.includes('sale') || action.includes('created') || action.includes('invited') || action.includes('activated') || action.includes('unsuspend')) {
    return 'text-[var(--status-good)] bg-green-500/10'
  }
  return 'text-[var(--accent)] bg-[var(--accent)]/10'
}

function ActivityTab({ entries, loading }: { entries: ActivityEntry[]; loading: boolean }) {
  if (loading) {
    return (
      <div className="space-y-3">
        {Array.from({ length: 6 }).map((_, i) => (
          <div key={i} className="flex gap-3 items-start">
            <div className="h-7 w-7 rounded-full bg-white/[0.07] shrink-0" />
            <div className="flex-1 space-y-1.5">
              <div className="h-3.5 w-48 rounded bg-white/[0.07]" />
              <div className="h-3 w-32 rounded bg-white/[0.05]" />
            </div>
          </div>
        ))}
      </div>
    )
  }

  if (entries.length === 0) {
    return (
      <div className="rounded-lg border border-[var(--line)] bg-[var(--surface)] p-10 text-center">
        <FileText className="h-8 w-8 text-[var(--ink-faint)] mx-auto mb-2" />
        <p className="text-[13px] text-[var(--ink-muted)]">No activity recorded yet.</p>
        <p className="text-[12px] text-[var(--ink-faint)] mt-1">Actions performed inside the business app will appear here.</p>
      </div>
    )
  }

  return (
    <div className="rounded-lg border border-[var(--line)] bg-[var(--surface)] divide-y divide-[var(--line)]">
      {entries.map((entry) => {
        const Icon = ACTION_ICONS[entry.action] ?? Settings
        const label = ACTION_LABELS[entry.action] ?? entry.action.replace(/_/g, ' ')
        const colorClass = actionColor(entry.action)

        return (
          <div key={entry.id} className="flex items-start gap-3 px-5 py-3.5">
            <div className={`mt-0.5 h-7 w-7 rounded-full flex items-center justify-center shrink-0 ${colorClass}`}>
              <Icon className="h-3.5 w-3.5" />
            </div>
            <div className="flex-1 min-w-0">
              <div className="flex items-baseline justify-between gap-2">
                <span className="text-[13px] font-medium text-[var(--ink)]">{label}</span>
                <span className="text-[11px] text-[var(--ink-faint)] shrink-0 tabular-nums">
                  {timeAgo(entry.timestamp)}
                </span>
              </div>
              <div className="mt-0.5 flex flex-wrap items-center gap-x-2 gap-y-0.5 text-[11px] text-[var(--ink-muted)]">
                {entry.entityName && (
                  <span className="truncate max-w-[200px]">{entry.entityName}</span>
                )}
                {entry.amount != null && (
                  <span className="font-mono">TZS {entry.amount.toLocaleString()}</span>
                )}
                {entry.businessName && (
                  <span className="text-[var(--ink-faint)]">· {entry.businessName}</span>
                )}
                {entry.performedByName && entry.source === 'admin_log' && (
                  <span className="text-[var(--ink-faint)]">by {entry.performedByName}</span>
                )}
              </div>
              {entry.details && (
                <p className="mt-1 text-[11px] text-[var(--ink-faint)] italic truncate">{entry.details}</p>
              )}
            </div>
          </div>
        )
      })}
    </div>
  )
}

function Field({ label, value, mono }: { label: string; value: string; mono?: boolean }) {
  return (
    <div>
      <div className="text-[11px] uppercase tracking-wide text-[var(--ink-faint)] mb-1">{label}</div>
      <div className={`text-[var(--ink)] ${mono ? 'font-mono' : 'font-medium'}`}>{value}</div>
    </div>
  )
}
