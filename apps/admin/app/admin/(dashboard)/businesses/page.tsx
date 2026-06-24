'use client'

import { useState, useCallback } from 'react'
import { useRouter } from 'next/navigation'
import { PageHeader } from '@/components/ui/page-header'
import { DataTable } from '@/components/ui/data-table'
import { StatusDot } from '@/components/ui/status-dot'
import { PlanBadge } from '@/components/ui/plan-badge'
import { SegmentedControl } from '@/components/ui/segmented-control'
import { SkeletonTable, RevalidatingBar } from '@/components/ui/skeleton'
import { fetchBusinesses, createUser } from '@/lib/admin-api'
import { useAdminFetch } from '@/hooks/use-admin-fetch'
import { formatTZS, timeAgo } from '@/lib/format'
import { AlertCircle, Plus, X, Loader2 } from 'lucide-react'
import type { Business, BusinessStatus } from '@/types'
import type { ColumnDef } from '@tanstack/react-table'

const columns: ColumnDef<Business, unknown>[] = [
  {
    accessorKey: 'name',
    header: 'Business',
    cell: ({ row }) => (
      <div>
        <div className="font-medium text-[var(--ink)]">{row.original.name}</div>
        <div className="text-[11px] text-[var(--ink-muted)]">
          {row.original.industry}
          {row.original.location ? ` · ${row.original.location}` : ''}
        </div>
      </div>
    ),
  },
  {
    accessorKey: 'ownerName',
    header: 'Owner',
    cell: ({ row }) => (
      <div>
        <div className="text-[var(--ink)]">{row.original.ownerName || '—'}</div>
        <div className="text-[11px] text-[var(--ink-faint)] font-mono">{row.original.ownerPhone}</div>
      </div>
    ),
  },
  {
    accessorKey: 'plan',
    header: 'Plan',
    cell: ({ row }) => <PlanBadge tier={row.original.plan} />,
  },
  {
    accessorKey: 'status',
    header: 'Status',
    cell: ({ row }) => {
      const s = row.original.status
      return (
        <StatusDot
          status={s === 'active' ? 'good' : s === 'suspended' ? 'bad' : s === 'pending' ? 'warn' : 'neutral'}
          label={s.charAt(0).toUpperCase() + s.slice(1)}
        />
      )
    },
  },
  {
    accessorKey: 'staffCount',
    header: 'Staff',
    cell: ({ row }) => <span className="font-mono text-[var(--ink)]">{row.original.staffCount}</span>,
  },
  {
    accessorKey: 'lastActive',
    header: 'Last Active',
    cell: ({ row }) => <span className="text-[var(--ink-muted)]">{timeAgo(row.original.lastActive)}</span>,
  },
  {
    accessorKey: 'mrr',
    header: 'MRR',
    cell: ({ row }) => (
      <span className="font-mono text-[var(--ink)] tabular-nums">
        {row.original.mrr > 0
          ? formatTZS(row.original.mrr)
          : <span className="text-[var(--ink-faint)]">—</span>
        }
      </span>
    ),
  },
]

interface CreateForm {
  name: string
  phone: string
  email: string
  businessName: string
  businessCategory: string
  placeOfBusiness: string
}

const EMPTY_FORM: CreateForm = {
  name: '', phone: '', email: '', businessName: '', businessCategory: '', placeOfBusiness: '',
}

function CreateDrawer({
  open,
  onClose,
  onCreated,
}: {
  open: boolean
  onClose: () => void
  onCreated: (uid: string, businessId: string | null) => void
}) {
  const [form, setForm] = useState<CreateForm>(EMPTY_FORM)
  const [saving, setSaving] = useState(false)
  const [err, setErr] = useState<string | null>(null)

  function set(field: keyof CreateForm, value: string) {
    setForm((f) => ({ ...f, [field]: value }))
    setErr(null)
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    if (!form.name.trim() || !form.phone.trim()) {
      setErr('Name and phone are required.')
      return
    }
    setSaving(true)
    setErr(null)
    try {
      const res = await createUser({
        name:             form.name.trim(),
        phone:            form.phone.trim(),
        email:            form.email.trim() || undefined,
        businessName:     form.businessName.trim() || undefined,
        businessCategory: form.businessCategory.trim() || undefined,
        placeOfBusiness:  form.placeOfBusiness.trim() || undefined,
      })
      setForm(EMPTY_FORM)
      onCreated(res.uid, res.businessId)
    } catch (e: unknown) {
      setErr(e instanceof Error ? e.message : 'Failed to create user')
    } finally {
      setSaving(false)
    }
  }

  if (!open) return null

  return (
    <div className="fixed inset-0 z-50 flex">
      {/* backdrop */}
      <div className="flex-1 bg-black/50" onClick={onClose} />

      {/* panel */}
      <div className="w-[420px] bg-[var(--navy)] border-l border-white/[0.09] flex flex-col overflow-y-auto">
        <div className="flex items-center justify-between px-6 py-5 border-b border-white/[0.07]">
          <h2 className="text-[15px] font-semibold text-white">New User &amp; Business</h2>
          <button onClick={onClose} className="p-1 rounded-md text-slate-400 hover:text-white hover:bg-white/10 transition-colors">
            <X className="h-4 w-4" />
          </button>
        </div>

        <form onSubmit={handleSubmit} className="flex-1 px-6 py-5 flex flex-col gap-5">
          {/* User section */}
          <div>
            <p className="text-[11px] font-semibold text-slate-400 uppercase tracking-widest mb-3">User Account</p>
            <div className="flex flex-col gap-3">
              <Field label="Full Name *" value={form.name} onChange={(v) => set('name', v)} placeholder="e.g. Amina Juma" />
              <Field label="Phone (TZ) *" value={form.phone} onChange={(v) => set('phone', v)} placeholder="712345678" type="tel" />
              <Field label="Email (optional)" value={form.email} onChange={(v) => set('email', v)} placeholder="amina@example.com" type="email" />
            </div>
          </div>

          <div className="border-t border-white/[0.07]" />

          {/* Business section */}
          <div>
            <p className="text-[11px] font-semibold text-slate-400 uppercase tracking-widest mb-1">Business (optional)</p>
            <p className="text-[11px] text-slate-500 mb-3">Leave blank to create a user-only account.</p>
            <div className="flex flex-col gap-3">
              <Field label="Business Name" value={form.businessName} onChange={(v) => set('businessName', v)} placeholder="e.g. Amina Duka" />
              <Field label="Business Category" value={form.businessCategory} onChange={(v) => set('businessCategory', v)} placeholder="e.g. retail, pharmacy…" />
              <Field label="Location / City" value={form.placeOfBusiness} onChange={(v) => set('placeOfBusiness', v)} placeholder="e.g. Dar es Salaam" />
            </div>
          </div>

          {err && (
            <div className="flex items-center gap-2 rounded-md border border-red-500/40 bg-red-500/10 px-3 py-2">
              <AlertCircle className="h-3.5 w-3.5 text-red-400 shrink-0" />
              <span className="text-[12px] text-red-300">{err}</span>
            </div>
          )}

          <div className="mt-auto pt-4 flex gap-3">
            <button
              type="button"
              onClick={onClose}
              className="flex-1 rounded-md border border-white/10 px-4 py-2 text-[13px] text-slate-300 hover:bg-white/10 transition-colors"
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={saving}
              className="flex-1 inline-flex items-center justify-center gap-1.5 rounded-md bg-[var(--brand)] px-4 py-2 text-[13px] font-medium text-[#040C18] hover:opacity-90 transition-opacity disabled:opacity-60"
            >
              {saving ? <Loader2 className="h-3.5 w-3.5 animate-spin" /> : <Plus className="h-3.5 w-3.5" />}
              {saving ? 'Creating…' : 'Create'}
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}

function Field({
  label, value, onChange, placeholder, type = 'text',
}: {
  label: string; value: string; onChange: (v: string) => void; placeholder?: string; type?: string
}) {
  return (
    <label className="flex flex-col gap-1">
      <span className="text-[11px] text-slate-400">{label}</span>
      <input
        type={type}
        value={value}
        onChange={(e) => onChange(e.target.value)}
        placeholder={placeholder}
        className="rounded-md border border-white/10 bg-white/[0.05] px-3 py-2 text-[13px] text-white placeholder:text-slate-600 focus:outline-none focus:ring-1 focus:ring-[var(--accent)]"
      />
    </label>
  )
}

export default function BusinessesPage() {
  const [statusFilter, setStatusFilter] = useState<'all' | BusinessStatus>('all')
  const [showCreate, setShowCreate] = useState(false)
  const router = useRouter()
  const { data, loading, revalidating, error, refetch } = useAdminFetch(
    useCallback(() => fetchBusinesses(), []),
    { key: 'businesses' },
  )

  const businesses = data?.businesses ?? []
  const filtered = statusFilter === 'all' ? businesses : businesses.filter((b) => b.status === statusFilter)

  function handleCreated(uid: string, businessId: string | null) {
    setShowCreate(false)
    refetch()
    if (businessId) {
      router.push(`/admin/businesses/${uid}/${businessId}`)
    }
  }

  return (
    <div>
      <PageHeader
        title="Businesses"
        description={loading ? 'Loading…' : `${data?.total ?? 0} registered businesses`}
      >
        <button
          onClick={() => setShowCreate(true)}
          className="inline-flex items-center gap-1.5 rounded-md bg-[var(--brand)] px-3 py-1.5 text-[12px] font-medium text-[#040C18] hover:opacity-90 transition-opacity"
        >
          <Plus className="h-3.5 w-3.5" />
          New business
        </button>
      </PageHeader>
      {revalidating && <RevalidatingBar />}

      {loading ? (
        <SkeletonTable rows={8} cols={7} />
      ) : error && !data ? (
        <div className="mt-4 flex items-center gap-3 rounded-lg border border-[var(--status-bad)] bg-[var(--status-bad-bg)] p-4 text-[var(--status-bad)]">
          <AlertCircle className="h-4 w-4 shrink-0" />
          <span className="text-[13px]">{error}</span>
        </div>
      ) : (
        <>
          <div className="mb-4">
            <SegmentedControl
              options={[
                { value: 'all',       label: 'All',       count: businesses.length },
                { value: 'active',    label: 'Active',    count: businesses.filter(b => b.status === 'active').length },
                { value: 'suspended', label: 'Suspended', count: businesses.filter(b => b.status === 'suspended').length },
                { value: 'inactive',  label: 'Inactive',  count: businesses.filter(b => b.status === 'inactive').length },
              ]}
              value={statusFilter}
              onChange={(v) => setStatusFilter(v as 'all' | BusinessStatus)}
            />
          </div>
          <DataTable
            data={filtered}
            columns={columns}
            searchPlaceholder="Search businesses…"
            onRowClick={(b) => router.push(`/admin/businesses/${b.ownerId}/${b.id}`)}
            exportFilename="businesses"
            emptyState={
              <div className="text-center py-8">
                <p className="text-[var(--ink-muted)] text-[13px]">No businesses match this filter</p>
              </div>
            }
          />
        </>
      )}

      <CreateDrawer
        open={showCreate}
        onClose={() => setShowCreate(false)}
        onCreated={handleCreated}
      />
    </div>
  )
}
