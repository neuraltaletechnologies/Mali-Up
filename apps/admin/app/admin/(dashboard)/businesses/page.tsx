'use client'

import { useState, useCallback, useEffect, useRef } from 'react'
import { useRouter } from 'next/navigation'
import { PageHeader } from '@/components/ui/page-header'
import { DataTable } from '@/components/ui/data-table'
import { StatusDot } from '@/components/ui/status-dot'
import { PlanBadge } from '@/components/ui/plan-badge'
import { SegmentedControl } from '@/components/ui/segmented-control'
import { SkeletonTable, RevalidatingBar } from '@/components/ui/skeleton'
import { fetchBusinesses, fetchUsers, fetchLookups, createBusiness } from '@/lib/admin-api'
import { useAdminFetch, invalidateAdminCache } from '@/hooks/use-admin-fetch'
import { formatTZS, timeAgo } from '@/lib/format'
import { AlertCircle, Plus, X, Loader2, ChevronDown, Search } from 'lucide-react'
import type { Business, BusinessStatus, AdminUser, AppLookups } from '@/types'
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
  userId: string
  businessName: string
  businessCategory: string
  city: string
  district: string
}

const EMPTY_FORM: CreateForm = {
  userId: '', businessName: '', businessCategory: '', city: '', district: '',
}

function CreatePanel({
  open,
  onClose,
  onCreated,
  existingBusinesses,
}: {
  open: boolean
  onClose: () => void
  onCreated: (uid: string, businessId: string) => void
  existingBusinesses: Business[]
}) {
  const [form, setForm] = useState<CreateForm>(EMPTY_FORM)
  const [saving, setSaving] = useState(false)
  const [err, setErr] = useState<string | null>(null)

  const [users, setUsers] = useState<AdminUser[]>([])
  const [lookups, setLookups] = useState<AppLookups | null>(null)
  const [loadingData, setLoadingData] = useState(false)

  const [userSearch, setUserSearch] = useState('')
  const [userDropOpen, setUserDropOpen] = useState(false)
  const [selectedUser, setSelectedUser] = useState<AdminUser | null>(null)

  const searchRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    if (!open) return
    setLoadingData(true)
    Promise.all([fetchUsers(500), fetchLookups()])
      .then(([usersRes, lookupsRes]) => {
        setUsers(usersRes.users)
        setLookups(lookupsRes)
      })
      .catch(() => setErr('Failed to load users / lookups'))
      .finally(() => setLoadingData(false))
  }, [open])

  useEffect(() => {
    if (!open) {
      setForm(EMPTY_FORM)
      setUserSearch('')
      setSelectedUser(null)
      setErr(null)
      setUserDropOpen(false)
    }
  }, [open])

  useEffect(() => {
    function onMouseDown(e: MouseEvent) {
      if (searchRef.current && !searchRef.current.contains(e.target as Node)) {
        setUserDropOpen(false)
      }
    }
    document.addEventListener('mousedown', onMouseDown)
    return () => document.removeEventListener('mousedown', onMouseDown)
  }, [])

  const filteredUsers = users.filter((u) => {
    const q = userSearch.toLowerCase()
    return u.name.toLowerCase().includes(q) || u.phone.includes(q)
  })

  const availableDistricts: string[] = lookups?.districts[form.city] ?? []

  function pickUser(u: AdminUser) {
    setForm((f) => ({ ...f, userId: u.id }))
    setSelectedUser(u)
    setUserSearch(`${u.name} · ${u.phone}`)
    setUserDropOpen(false)
    setErr(null)
  }

  function set(field: keyof CreateForm, value: string) {
    setForm((f) => ({ ...f, [field]: value }))
    setErr(null)
  }

  function setCity(value: string) {
    setForm((f) => ({ ...f, city: value, district: '' }))
    setErr(null)
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    if (!form.userId) { setErr('Please select a user.'); return }
    if (!form.businessName.trim()) { setErr('Business name is required.'); return }
    if (!form.businessCategory) { setErr('Business type is required.'); return }
    if (!form.city) { setErr('City is required.'); return }

    // Duplicate check — prevent saving if this user already has a business with the same name
    const duplicate = existingBusinesses.some(
      (b) =>
        b.ownerId === form.userId &&
        b.name.toLowerCase() === form.businessName.trim().toLowerCase(),
    )
    if (duplicate) {
      setErr(`"${form.businessName.trim()}" already exists for this user.`)
      return
    }

    setSaving(true)
    setErr(null)
    try {
      const res = await createBusiness({
        uid:              form.userId,
        businessName:     form.businessName.trim(),
        businessCategory: form.businessCategory,
        city:             form.city,
        district:         form.district || undefined,
      })
      setForm(EMPTY_FORM)
      onCreated(res.uid, res.businessId)
    } catch (e: unknown) {
      setErr(e instanceof Error ? e.message : 'Failed to create business')
    } finally {
      setSaving(false)
    }
  }

  if (!open) return null

  const inputCls =
    'rounded-md border border-white/10 bg-white/[0.05] px-3 py-2 text-[13px] text-white placeholder:text-slate-600 focus:outline-none focus:ring-1 focus:ring-[var(--accent)] w-full'

  const selectCls =
    'rounded-md border border-white/10 bg-white/[0.05] px-3 py-2 text-[13px] text-white focus:outline-none focus:ring-1 focus:ring-[var(--accent)] w-full appearance-none disabled:opacity-40'

  return (
    <div className="mb-5 rounded-xl border border-white/[0.09] bg-[var(--navy)] overflow-hidden">
      {/* Panel header */}
      <div className="flex items-center justify-between px-6 py-4 border-b border-white/[0.07]">
        <h2 className="text-[14px] font-semibold text-white">New Business</h2>
        <button
          onClick={onClose}
          className="p-1 rounded-md text-slate-400 hover:text-white hover:bg-white/10 transition-colors"
        >
          <X className="h-4 w-4" />
        </button>
      </div>

      {loadingData ? (
        <div className="flex items-center justify-center gap-2 text-slate-400 text-[13px] py-8">
          <Loader2 className="h-4 w-4 animate-spin" />
          Loading…
        </div>
      ) : (
        <form onSubmit={handleSubmit} className="px-6 py-5">
          {/* Two-column layout: left = Owner + Name + Type  |  right = City + District */}
          <div className="grid grid-cols-2 gap-x-8 gap-y-4">

            {/* ── LEFT COLUMN ─────────────────────────────── */}
            <div className="flex flex-col gap-4">

              {/* Owner */}
              <div>
                <p className="text-[11px] font-semibold text-slate-400 uppercase tracking-widest mb-2">Owner *</p>
                <div ref={searchRef} className="relative">
                  <div className="relative">
                    <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-3.5 w-3.5 text-slate-500 pointer-events-none" />
                    <input
                      type="text"
                      placeholder="Search by name or phone…"
                      value={userSearch}
                      onChange={(e) => {
                        setUserSearch(e.target.value)
                        setSelectedUser(null)
                        setForm((f) => ({ ...f, userId: '' }))
                        setUserDropOpen(true)
                      }}
                      onFocus={() => setUserDropOpen(true)}
                      className="rounded-md border border-white/10 bg-white/[0.05] pl-9 pr-3 py-2 text-[13px] text-white placeholder:text-slate-600 focus:outline-none focus:ring-1 focus:ring-[var(--accent)] w-full"
                    />
                  </div>
                  {userDropOpen && (
                    <div className="absolute z-20 mt-1 w-full max-h-48 overflow-y-auto rounded-md border border-white/10 bg-[var(--navy)] shadow-xl">
                      {filteredUsers.length === 0 ? (
                        <div className="px-4 py-3 text-[12px] text-slate-500">No users found</div>
                      ) : filteredUsers.slice(0, 50).map((u) => (
                        <button
                          key={u.id}
                          type="button"
                          onMouseDown={() => pickUser(u)}
                          className="w-full text-left px-4 py-2.5 hover:bg-white/[0.07] transition-colors"
                        >
                          <div className="text-[13px] text-white font-medium">{u.name}</div>
                          <div className="text-[11px] text-slate-400 font-mono">{u.phone}</div>
                        </button>
                      ))}
                    </div>
                  )}
                </div>
                {selectedUser && (
                  <p className="mt-1.5 text-[11px] text-[var(--accent)]">
                    ✓ {selectedUser.name} — {selectedUser.businessCount} existing business{selectedUser.businessCount !== 1 ? 'es' : ''}
                  </p>
                )}
              </div>

              {/* Business Name */}
              <label className="flex flex-col gap-1">
                <span className="text-[11px] font-semibold text-slate-400 uppercase tracking-widest">Business Name *</span>
                <input
                  type="text"
                  value={form.businessName}
                  onChange={(e) => set('businessName', e.target.value)}
                  placeholder="e.g. Amina Duka"
                  className={inputCls}
                />
              </label>

              {/* Business Type */}
              <label className="flex flex-col gap-1">
                <span className="text-[11px] font-semibold text-slate-400 uppercase tracking-widest">Business Type *</span>
                <div className="relative">
                  <select
                    value={form.businessCategory}
                    onChange={(e) => set('businessCategory', e.target.value)}
                    className={selectCls}
                  >
                    <option value="" disabled>Select type…</option>
                    {(lookups?.businessTypes ?? []).map((bt) => (
                      <option key={bt.value} value={bt.value}>
                        {bt.en} ({bt.sw})
                      </option>
                    ))}
                  </select>
                  <ChevronDown className="pointer-events-none absolute right-3 top-1/2 -translate-y-1/2 h-3.5 w-3.5 text-slate-400" />
                </div>
              </label>
            </div>

            {/* ── RIGHT COLUMN — City & District ──────────── */}
            <div className="flex flex-col gap-4">
              <p className="text-[11px] font-semibold text-slate-400 uppercase tracking-widest mb-0">Location</p>

              {/* City */}
              <label className="flex flex-col gap-1">
                <span className="text-[11px] text-slate-400">City *</span>
                <div className="relative">
                  <select
                    value={form.city}
                    onChange={(e) => setCity(e.target.value)}
                    className={selectCls}
                  >
                    <option value="" disabled>Select city…</option>
                    {(lookups?.cities ?? []).map((c) => (
                      <option key={c.en} value={c.en}>
                        {c.en} / {c.sw}
                      </option>
                    ))}
                  </select>
                  <ChevronDown className="pointer-events-none absolute right-3 top-1/2 -translate-y-1/2 h-3.5 w-3.5 text-slate-400" />
                </div>
              </label>

              {/* District */}
              <label className="flex flex-col gap-1">
                <span className="text-[11px] text-slate-400">
                  District{form.city && availableDistricts.length === 0 ? ' (none for this city)' : ''}
                </span>
                <div className="relative">
                  <select
                    value={form.district}
                    onChange={(e) => set('district', e.target.value)}
                    disabled={!form.city || availableDistricts.length === 0}
                    className={selectCls}
                  >
                    <option value="">Select district…</option>
                    {availableDistricts.map((d) => (
                      <option key={d} value={d}>{d}</option>
                    ))}
                  </select>
                  <ChevronDown className="pointer-events-none absolute right-3 top-1/2 -translate-y-1/2 h-3.5 w-3.5 text-slate-400" />
                </div>
              </label>
            </div>
          </div>

          {/* Error */}
          {err && (
            <div className="mt-4 flex items-center gap-2 rounded-md border border-red-500/40 bg-red-500/10 px-3 py-2">
              <AlertCircle className="h-3.5 w-3.5 text-red-400 shrink-0" />
              <span className="text-[12px] text-red-300">{err}</span>
            </div>
          )}

          {/* Actions */}
          <div className="mt-5 flex justify-end gap-3">
            <button
              type="button"
              onClick={onClose}
              className="rounded-md border border-white/10 px-4 py-2 text-[13px] text-slate-300 hover:bg-white/10 transition-colors"
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={saving}
              className="inline-flex items-center justify-center gap-1.5 rounded-md bg-[var(--brand)] px-5 py-2 text-[13px] font-semibold text-[#040C18] hover:opacity-90 transition-opacity disabled:opacity-60"
            >
              {saving ? <Loader2 className="h-3.5 w-3.5 animate-spin" /> : <Plus className="h-3.5 w-3.5" />}
              {saving ? 'Creating…' : 'Create Business'}
            </button>
          </div>
        </form>
      )}
    </div>
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

  function handleCreated(uid: string, businessId: string) {
    setShowCreate(false)
    invalidateAdminCache(['analytics', 'businesses'])
    refetch()
    router.push(`/admin/businesses/${uid}/${businessId}`)
  }

  return (
    <div>
      <PageHeader
        title="Businesses"
        description={loading ? 'Loading…' : `${data?.total ?? 0} registered businesses`}
      >
        <button
          onClick={() => setShowCreate((v) => !v)}
          className="inline-flex items-center gap-1.5 rounded-md bg-[var(--brand)] px-3 py-1.5 text-[12px] font-semibold text-[#040C18] hover:opacity-90 transition-opacity"
        >
          <Plus className="h-3.5 w-3.5" />
          New business
        </button>
      </PageHeader>
      {revalidating && <RevalidatingBar />}

      {/* Inline create panel — appears above the list */}
      <CreatePanel
        open={showCreate}
        onClose={() => setShowCreate(false)}
        onCreated={handleCreated}
        existingBusinesses={businesses}
      />

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
    </div>
  )
}
