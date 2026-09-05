'use client'

import { useState, useCallback } from 'react'
import { useRouter } from 'next/navigation'
import { PageHeader } from '@/components/ui/page-header'
import { DataTable } from '@/components/ui/data-table'
import { StatusDot } from '@/components/ui/status-dot'
import { SegmentedControl } from '@/components/ui/segmented-control'
import { SkeletonTable, RevalidatingBar } from '@/components/ui/skeleton'
import {
  fetchUsers, createUser, fetchGeoRegions, fetchGeoDistricts, type GeoDivision,
} from '@/lib/admin-api'
import { useAdminFetch, invalidateAdminCache } from '@/hooks/use-admin-fetch'
import { formatDate, timeAgo } from '@/lib/format'
import { LOCATION_COUNTRIES, TZ_REGIONS, TZ_REGION_NAMES, flagForCountryCode } from '@/lib/locations'
import { BUSINESS_TYPES } from '@/lib/business-types'
import { AlertCircle, Plus, X, Loader2 } from 'lucide-react'
import type { AdminUser, UserStatus } from '@/types'
import type { ColumnDef } from '@tanstack/react-table'

const columns: ColumnDef<AdminUser, unknown>[] = [
  {
    accessorKey: 'name',
    header: 'Name',
    cell: ({ row }) => (
      <div>
        <div className="font-medium text-[var(--ink)]">{row.original.name}</div>
        <div className="text-[11px] font-mono text-[var(--ink-faint)]">{row.original.phone}</div>
      </div>
    ),
  },
  {
    accessorKey: 'email',
    header: 'Email',
    cell: ({ row }) => (
      <span className="text-[var(--ink-muted)] text-[12px]">
        {row.original.email ?? <span className="text-[var(--ink-faint)]">—</span>}
      </span>
    ),
  },
  {
    accessorKey: 'businessName',
    header: 'Business',
    cell: ({ row }) => (
      <span className="text-[var(--ink-muted)] text-[12px]">
        {row.original.businessName || <span className="text-[var(--ink-faint)]">—</span>}
      </span>
    ),
  },
  {
    accessorKey: 'status',
    header: 'Status',
    cell: ({ row }) => {
      const s = row.original.status
      return (
        <StatusDot
          status={s === 'active' ? 'good' : s === 'suspended' ? 'bad' : 'warn'}
          label={s.charAt(0).toUpperCase() + s.slice(1)}
        />
      )
    },
  },
  {
    accessorKey: 'businessCount',
    header: 'Businesses',
    cell: ({ row }) => (
      <span className="font-mono text-[var(--ink)]">{row.original.businessCount}</span>
    ),
  },
  {
    accessorKey: 'lastLogin',
    header: 'Last Login',
    cell: ({ row }) => <span className="text-[var(--ink-muted)]">{timeAgo(row.original.lastLogin)}</span>,
  },
  {
    accessorKey: 'joinedAt',
    header: 'Joined',
    cell: ({ row }) => <span className="text-[var(--ink-muted)]">{formatDate(row.original.joinedAt)}</span>,
  },
]

interface CreateForm {
  firstName: string
  lastName: string
  phone: string
  email: string
  businessName: string
  businessCategory: string
  // Mirrors the mobile app's onboarding business-location step exactly —
  // country / region ("mkoa") / district ("wilaya"), picked from a list.
  businessCountry: string
  businessRegion: string
  businessDistrict: string
}

const EMPTY_FORM: CreateForm = {
  firstName: '', lastName: '', phone: '', email: '',
  businessName: '', businessCategory: '',
  businessCountry: 'TZ', businessRegion: '', businessDistrict: '',
}

function Field({
  label, value, onChange, placeholder, type = 'text', disabled = false,
}: {
  label: string; value: string; onChange: (v: string) => void; placeholder?: string; type?: string; disabled?: boolean
}) {
  return (
    <label className="flex flex-col gap-1">
      <span className="text-[11px] text-slate-400">{label}</span>
      <input
        type={type}
        value={value}
        disabled={disabled}
        onChange={(e) => onChange(e.target.value)}
        placeholder={placeholder}
        className="rounded-md border border-white/10 bg-white/[0.05] px-3 py-2 text-[13px] text-white placeholder:text-slate-600 focus:outline-none focus:ring-1 focus:ring-[var(--accent)] disabled:opacity-50"
      />
    </label>
  )
}

/** A "choose from the list" field — same intent as the mobile app's
 *  bottom-sheet pickers (country / region / district), just rendered as a
 *  native select to match the rest of this admin UI's form controls. */
function Select({
  label, value, onChange, options, disabled = false, placeholder,
}: {
  label: string
  value: string
  onChange: (v: string) => void
  options: { value: string; label: string }[]
  disabled?: boolean
  placeholder?: string
}) {
  return (
    <label className="flex flex-col gap-1">
      <span className="text-[11px] text-slate-400">{label}</span>
      <select
        value={value}
        disabled={disabled}
        onChange={(e) => onChange(e.target.value)}
        className="rounded-md border border-white/10 bg-white/[0.05] px-3 py-2 text-[13px] text-white focus:outline-none focus:ring-1 focus:ring-[var(--accent)] disabled:opacity-50"
      >
        {placeholder && <option value="">{placeholder}</option>}
        {options.map((o) => (
          <option key={o.value} value={o.value} className="bg-[var(--navy)] text-white">
            {o.label}
          </option>
        ))}
      </select>
    </label>
  )
}

function CreateDrawer({
  open,
  onClose,
  onCreated,
}: {
  open: boolean
  onClose: () => void
  onCreated: (uid: string) => void
}) {
  const [form, setForm] = useState<CreateForm>(EMPTY_FORM)
  const [saving, setSaving] = useState(false)
  const [err, setErr] = useState<string | null>(null)

  // Non-Tanzania region/district come live from the same Country-State-City
  // API the mobile app calls (see lib/admin-api.ts fetchGeoRegions/
  // fetchGeoDistricts) — Tanzania keeps its own curated TZ_REGIONS list
  // below, exactly like the app's onboarding flow.
  const [regions, setRegions] = useState<GeoDivision[]>([])
  const [districts, setDistricts] = useState<GeoDivision[]>([])
  const [regionStatus, setRegionStatus] = useState<'idle' | 'loading' | 'ready' | 'empty'>('idle')
  const [districtStatus, setDistrictStatus] = useState<'idle' | 'loading' | 'ready' | 'empty'>('idle')

  function set(field: keyof CreateForm, value: string) {
    setForm((f) => ({ ...f, [field]: value }))
    setErr(null)
  }

  async function loadRegions(code: string) {
    setRegionStatus('loading')
    setDistricts([])
    setDistrictStatus('idle')
    try {
      const list = await fetchGeoRegions(code)
      setRegions(list)
      setRegionStatus(list.length ? 'ready' : 'empty')
    } catch {
      setRegions([])
      setRegionStatus('empty')
    }
  }

  async function loadDistricts(code: string, regionCode: string) {
    setDistrictStatus('loading')
    try {
      const list = await fetchGeoDistricts(code, regionCode)
      setDistricts(list)
      setDistrictStatus(list.length ? 'ready' : 'empty')
    } catch {
      setDistricts([])
      setDistrictStatus('empty')
    }
  }

  // Country changes clear region + district; region changes clear district —
  // same cascade as the mobile app's business-location picker.
  function setCountry(code: string) {
    setForm((f) => ({ ...f, businessCountry: code, businessRegion: '', businessDistrict: '' }))
    setErr(null)
    setRegions([])
    setDistricts([])
    setRegionStatus('idle')
    setDistrictStatus('idle')
    if (code !== 'TZ') void loadRegions(code)
  }

  function setRegion(region: string) {
    setForm((f) => ({ ...f, businessRegion: region, businessDistrict: '' }))
    setErr(null)
    if (isTz) return
    setDistricts([])
    const code = regions.find((r) => r.name === region)?.code
    if (code) {
      void loadDistricts(form.businessCountry, code)
    } else {
      setDistrictStatus('empty')
    }
  }

  const isTz = form.businessCountry === 'TZ'
  const tzDistrictOptions = isTz ? (TZ_REGIONS[form.businessRegion] ?? []) : []
  // `empty` = the live lookup finished with nothing usable (or no API key is
  // configured), so the field becomes free text — the app does the same.
  const regionFreeText = !isTz && regionStatus === 'empty'
  const districtFreeText = !isTz && districtStatus === 'empty'

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    const firstName = form.firstName.trim()
    const lastName = form.lastName.trim()
    if (!firstName || !lastName) {
      setErr('First name and last name are required.')
      return
    }
    if (/\d/.test(firstName) || /\d/.test(lastName)) {
      setErr('Name must not contain numbers.')
      return
    }
    if (!form.phone.trim()) {
      setErr('Phone is required.')
      return
    }
    setSaving(true)
    setErr(null)
    try {
      const res = await createUser({
        firstName,
        lastName,
        phone:             form.phone.trim(),
        email:             form.email.trim() || undefined,
        businessName:      form.businessName.trim() || undefined,
        businessCategory:  form.businessCategory.trim() || undefined,
        businessCountry:   form.businessName.trim() ? form.businessCountry : undefined,
        businessRegion:    form.businessName.trim() ? form.businessRegion.trim() || undefined : undefined,
        businessDistrict:  form.businessName.trim() ? form.businessDistrict.trim() || undefined : undefined,
      })
      setForm(EMPTY_FORM)
      setRegions([])
      setDistricts([])
      setRegionStatus('idle')
      setDistrictStatus('idle')
      onCreated(res.uid)
    } catch (e: unknown) {
      setErr(e instanceof Error ? e.message : 'Failed to create user')
    } finally {
      setSaving(false)
    }
  }

  if (!open) return null

  return (
    <div className="fixed inset-0 z-50 flex">
      <div className="flex-1 bg-black/50" onClick={onClose} />

      <div className="w-[420px] bg-[var(--navy)] border-l border-white/[0.09] flex flex-col overflow-y-auto">
        <div className="flex items-center justify-between px-6 py-5 border-b border-white/[0.07]">
          <h2 className="text-[15px] font-semibold text-white">New User</h2>
          <button onClick={onClose} className="p-1 rounded-md text-slate-400 hover:text-white hover:bg-white/10 transition-colors">
            <X className="h-4 w-4" />
          </button>
        </div>

        <form onSubmit={handleSubmit} className="flex-1 px-6 py-5 flex flex-col gap-5">
          <div>
            <p className="text-[11px] font-semibold text-slate-400 uppercase tracking-widest mb-3">User Account</p>
            <div className="flex flex-col gap-3">
              <div className="grid grid-cols-2 gap-3">
                <Field label="First Name *" value={form.firstName} onChange={(v) => set('firstName', v)} placeholder="e.g. Amina" />
                <Field label="Last Name *" value={form.lastName} onChange={(v) => set('lastName', v)} placeholder="e.g. Juma" />
              </div>
              <Field label="Phone (TZ) *" value={form.phone} onChange={(v) => set('phone', v)} placeholder="712345678" type="tel" />
              <Field label="Email (optional)" value={form.email} onChange={(v) => set('email', v)} placeholder="amina@example.com" type="email" />
            </div>
          </div>

          <div className="border-t border-white/[0.07]" />

          <div>
            <p className="text-[11px] font-semibold text-slate-400 uppercase tracking-widest mb-1">Business (optional)</p>
            <p className="text-[11px] text-slate-500 mb-3">Leave blank to create a user-only account.</p>
            <div className="flex flex-col gap-3">
              <Field label="Business Name" value={form.businessName} onChange={(v) => set('businessName', v)} placeholder="e.g. Amina Duka" />
              <Select
                label="Business Category"
                value={form.businessCategory}
                onChange={(v) => set('businessCategory', v)}
                placeholder="Select business type…"
                options={BUSINESS_TYPES.map((t) => ({ value: t.key, label: t.label }))}
              />

              <p className="text-[11px] font-semibold text-slate-400 uppercase tracking-widest mt-2">Business Location</p>

              <Select
                label="Country"
                value={form.businessCountry}
                onChange={setCountry}
                options={LOCATION_COUNTRIES.map((c) => ({
                  value: c.code,
                  label: `${flagForCountryCode(c.code)}  ${c.name}`,
                }))}
              />

              <div className="grid grid-cols-2 gap-3">
                {isTz ? (
                  <Select
                    label="Region (Mkoa)"
                    value={form.businessRegion}
                    onChange={setRegion}
                    placeholder="Select region…"
                    options={TZ_REGION_NAMES.map((r) => ({ value: r, label: r }))}
                  />
                ) : regionFreeText ? (
                  <Field
                    label="Region (Mkoa)"
                    value={form.businessRegion}
                    onChange={setRegion}
                    placeholder="Type region"
                  />
                ) : (
                  <Select
                    label="Region (Mkoa)"
                    value={form.businessRegion}
                    onChange={setRegion}
                    placeholder={regionStatus === 'loading' ? 'Loading regions…' : 'Select region…'}
                    disabled={regionStatus === 'loading'}
                    options={regions.map((r) => ({ value: r.name, label: r.name }))}
                  />
                )}

                {isTz ? (
                  <Select
                    label="District (Wilaya)"
                    value={form.businessDistrict}
                    onChange={(v) => set('businessDistrict', v)}
                    placeholder={form.businessRegion ? 'Select district…' : 'Choose a region first'}
                    disabled={!form.businessRegion}
                    options={tzDistrictOptions.map((d) => ({ value: d, label: d }))}
                  />
                ) : districtFreeText ? (
                  <Field
                    label="District (Wilaya)"
                    value={form.businessDistrict}
                    onChange={(v) => set('businessDistrict', v)}
                    placeholder={form.businessRegion ? 'Type district' : 'Choose a region first'}
                    disabled={!form.businessRegion}
                  />
                ) : (
                  <Select
                    label="District (Wilaya)"
                    value={form.businessDistrict}
                    onChange={(v) => set('businessDistrict', v)}
                    placeholder={
                      !form.businessRegion ? 'Choose a region first'
                        : districtStatus === 'loading' ? 'Loading districts…' : 'Select district…'
                    }
                    disabled={!form.businessRegion || districtStatus === 'loading'}
                    options={districts.map((d) => ({ value: d.name, label: d.name }))}
                  />
                )}
              </div>
              {(regionFreeText || districtFreeText) && (
                <p className="text-[11px] text-slate-500">
                  We couldn&apos;t load this country&apos;s regions — type them in instead.
                </p>
              )}
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

export default function UsersPage() {
  const [statusFilter, setStatusFilter] = useState<'all' | UserStatus>('all')
  const [showCreate, setShowCreate] = useState(false)
  const router = useRouter()
  const { data, loading, revalidating, error, refetch } = useAdminFetch(
    useCallback(() => fetchUsers(), []),
    { key: 'users' },
  )

  const users = data?.users ?? []
  const filtered = statusFilter === 'all' ? users : users.filter((u) => u.status === statusFilter)

  function handleCreated(uid: string) {
    setShowCreate(false)
    invalidateAdminCache(['analytics', 'users'])
    refetch()
    router.push(`/admin/users/${uid}`)
  }

  return (
    <div>
      <PageHeader
        title="Users"
        description={loading ? 'Loading…' : `${data?.total ?? 0} platform users`}
      >
        <button
          onClick={() => setShowCreate(true)}
          className="inline-flex items-center gap-1.5 rounded-md bg-[var(--brand)] px-3 py-1.5 text-[12px] font-medium text-[#040C18] hover:opacity-90 transition-opacity"
        >
          <Plus className="h-3.5 w-3.5" />
          New user
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
                { value: 'all', label: 'All', count: users.length },
                { value: 'active', label: 'Active', count: users.filter(u => u.status === 'active').length },
                { value: 'suspended', label: 'Suspended', count: users.filter(u => u.status === 'suspended').length },
                { value: 'pending', label: 'Pending', count: users.filter(u => u.status === 'pending').length },
              ]}
              value={statusFilter}
              onChange={(v) => setStatusFilter(v as 'all' | UserStatus)}
            />
          </div>
          <DataTable
            data={filtered}
            columns={columns}
            searchPlaceholder="Search users…"
            onRowClick={(u) => router.push(`/admin/users/${u.id}`)}
            exportFilename="users"
            emptyState={
              <div className="text-center py-8">
                <p className="text-[var(--ink-muted)] text-[13px]">No users match this filter</p>
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
