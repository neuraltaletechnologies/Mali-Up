'use client'

import { useState, useCallback } from 'react'
import { PageHeader } from '@/components/ui/page-header'
import { SkeletonTable, RevalidatingBar } from '@/components/ui/skeleton'
import {
  fetchLookups,
  saveLookupBusinessTypes,
  saveLookupCities,
  saveLookupDistricts,
} from '@/lib/admin-api'
import { useAdminFetch } from '@/hooks/use-admin-fetch'
import { AlertCircle, Plus, Pencil, Trash2, Save, X, Check, MapPin, Building2, Clock } from 'lucide-react'
import type { LookupBusinessType, LookupCity, AppLookups } from '@/types'

const ICONS = [
  'store','storefront','shopping_bag','inventory_2','phone_android','checkroom',
  'content_cut','face','restaurant','bakery_dining','lunch_dining','agriculture',
  'pets','build','construction','handyman','local_shipping','travel_explore',
  'hotel','medical_services','school','real_estate_agent','account_balance',
  'computer','print','directions_car','local_gas_station','campaign',
  'cleaning_services','security','category','sell','home','local_drink',
]

// ─── Inline edit row for Business Types ─────────────────────────────────────

function BizTypeRow({
  item,
  onSave,
  onDelete,
  isNew = false,
  onCancelNew,
}: {
  item: LookupBusinessType
  onSave: (updated: LookupBusinessType) => void
  onDelete: () => void
  isNew?: boolean
  onCancelNew?: () => void
}) {
  const [editing, setEditing] = useState(isNew)
  const [form, setForm] = useState(item)

  function save() {
    if (!form.value.trim() || !form.en.trim()) return
    onSave(form)
    if (!isNew) setEditing(false)
  }

  if (!editing) {
    return (
      <tr className="group border-b border-[var(--line)] last:border-0">
        <td className="px-4 py-2.5 text-[13px] font-mono text-[var(--ink-muted)] w-8">{item.icon}</td>
        <td className="px-4 py-2.5 text-[13px] font-medium text-[var(--ink)]">{item.en}</td>
        <td className="px-4 py-2.5 text-[13px] text-[var(--ink-muted)]">{item.sw}</td>
        <td className="px-4 py-2.5 text-[12px] font-mono text-[var(--ink-faint)]">{item.value}</td>
        <td className="px-4 py-2.5 w-16">
          <div className="flex gap-1 opacity-0 group-hover:opacity-100 transition-opacity">
            <button onClick={() => setEditing(true)} className="p-1 rounded hover:bg-[var(--canvas)] text-[var(--ink-faint)] hover:text-[var(--ink)]">
              <Pencil className="h-3.5 w-3.5" />
            </button>
            <button onClick={onDelete} className="p-1 rounded hover:bg-[var(--status-bad-bg)] text-[var(--ink-faint)] hover:text-[var(--status-bad)]">
              <Trash2 className="h-3.5 w-3.5" />
            </button>
          </div>
        </td>
      </tr>
    )
  }

  return (
    <tr className="border-b border-[var(--line)] bg-[var(--canvas)]">
      <td className="px-4 py-2">
        <select
          value={form.icon}
          onChange={(e) => setForm((f) => ({ ...f, icon: e.target.value }))}
          className="w-28 rounded border border-[var(--line)] bg-[var(--surface)] px-2 py-1 text-[12px] text-[var(--ink)]"
        >
          {ICONS.map((ic) => <option key={ic} value={ic}>{ic}</option>)}
        </select>
      </td>
      <td className="px-4 py-2">
        <input value={form.en} onChange={(e) => setForm((f) => ({ ...f, en: e.target.value }))}
          placeholder="English name" required
          className="w-full rounded border border-[var(--line)] bg-[var(--surface)] px-2 py-1 text-[13px] text-[var(--ink)]" />
      </td>
      <td className="px-4 py-2">
        <input value={form.sw} onChange={(e) => setForm((f) => ({ ...f, sw: e.target.value }))}
          placeholder="Jina la Kiswahili"
          className="w-full rounded border border-[var(--line)] bg-[var(--surface)] px-2 py-1 text-[13px] text-[var(--ink)]" />
      </td>
      <td className="px-4 py-2">
        <input value={form.value} onChange={(e) => setForm((f) => ({ ...f, value: e.target.value }))}
          placeholder="value key"
          className="w-full rounded border border-[var(--line)] bg-[var(--surface)] px-2 py-1 text-[12px] font-mono text-[var(--ink)]" />
      </td>
      <td className="px-4 py-2 w-16">
        <div className="flex gap-1">
          <button onClick={save} className="p-1 rounded bg-[var(--accent-soft)] text-[var(--accent)] hover:opacity-80">
            <Check className="h-3.5 w-3.5" />
          </button>
          <button onClick={() => { if (isNew) onCancelNew?.(); else setEditing(false) }}
            className="p-1 rounded hover:bg-[var(--line)] text-[var(--ink-faint)]">
            <X className="h-3.5 w-3.5" />
          </button>
        </div>
      </td>
    </tr>
  )
}

// ─── Inline edit row for Cities ─────────────────────────────────────────────

function CityRow({
  item,
  onSave,
  onDelete,
  isNew = false,
  onCancelNew,
}: {
  item: LookupCity
  onSave: (updated: LookupCity) => void
  onDelete: () => void
  isNew?: boolean
  onCancelNew?: () => void
}) {
  const [editing, setEditing] = useState(isNew)
  const [form, setForm] = useState(item)

  function save() {
    if (!form.en.trim()) return
    onSave(form)
    if (!isNew) setEditing(false)
  }

  if (!editing) {
    return (
      <tr className="group border-b border-[var(--line)] last:border-0">
        <td className="px-4 py-2.5 text-[13px] font-medium text-[var(--ink)]">{item.en}</td>
        <td className="px-4 py-2.5 text-[13px] text-[var(--ink-muted)]">{item.sw}</td>
        <td className="px-4 py-2.5 w-16">
          <div className="flex gap-1 opacity-0 group-hover:opacity-100 transition-opacity">
            <button onClick={() => setEditing(true)} className="p-1 rounded hover:bg-[var(--canvas)] text-[var(--ink-faint)] hover:text-[var(--ink)]">
              <Pencil className="h-3.5 w-3.5" />
            </button>
            <button onClick={onDelete} className="p-1 rounded hover:bg-[var(--status-bad-bg)] text-[var(--ink-faint)] hover:text-[var(--status-bad)]">
              <Trash2 className="h-3.5 w-3.5" />
            </button>
          </div>
        </td>
      </tr>
    )
  }

  return (
    <tr className="border-b border-[var(--line)] bg-[var(--canvas)]">
      <td className="px-4 py-2">
        <input value={form.en} onChange={(e) => setForm((f) => ({ ...f, en: e.target.value }))}
          placeholder="City name (English)" required
          className="w-full rounded border border-[var(--line)] bg-[var(--surface)] px-2 py-1 text-[13px] text-[var(--ink)]" />
      </td>
      <td className="px-4 py-2">
        <input value={form.sw} onChange={(e) => setForm((f) => ({ ...f, sw: e.target.value }))}
          placeholder="Jina la Kiswahili"
          className="w-full rounded border border-[var(--line)] bg-[var(--surface)] px-2 py-1 text-[13px] text-[var(--ink)]" />
      </td>
      <td className="px-4 py-2 w-16">
        <div className="flex gap-1">
          <button onClick={save} className="p-1 rounded bg-[var(--accent-soft)] text-[var(--accent)] hover:opacity-80">
            <Check className="h-3.5 w-3.5" />
          </button>
          <button onClick={() => { if (isNew) onCancelNew?.(); else setEditing(false) }}
            className="p-1 rounded hover:bg-[var(--line)] text-[var(--ink-faint)]">
            <X className="h-3.5 w-3.5" />
          </button>
        </div>
      </td>
    </tr>
  )
}

// ─── Districts panel ─────────────────────────────────────────────────────────

function DistrictsPanel({
  districts,
  onChange,
}: {
  districts: Record<string, string[]>
  onChange: (updated: Record<string, string[]>) => void
}) {
  const [selectedRegion, setSelectedRegion] = useState<string>(Object.keys(districts)[0] ?? '')
  const [newRegion, setNewRegion] = useState('')
  const [addingRegion, setAddingRegion] = useState(false)
  const [newDistrict, setNewDistrict] = useState('')
  const [addingDistrict, setAddingDistrict] = useState(false)
  const [editingDistrict, setEditingDistrict] = useState<{ idx: number; val: string } | null>(null)

  const regions = Object.keys(districts).sort()
  const currentDistricts = districts[selectedRegion] ?? []

  function addRegion() {
    if (!newRegion.trim() || districts[newRegion.trim()]) return
    const updated = { ...districts, [newRegion.trim()]: [] }
    onChange(updated)
    setSelectedRegion(newRegion.trim())
    setNewRegion('')
    setAddingRegion(false)
  }

  function deleteRegion(r: string) {
    const updated = { ...districts }
    delete updated[r]
    onChange(updated)
    setSelectedRegion(Object.keys(updated)[0] ?? '')
  }

  function addDistrict() {
    if (!newDistrict.trim() || !selectedRegion) return
    const updated = { ...districts, [selectedRegion]: [...currentDistricts, newDistrict.trim()] }
    onChange(updated)
    setNewDistrict('')
    setAddingDistrict(false)
  }

  function deleteDistrict(idx: number) {
    const list = currentDistricts.filter((_, i) => i !== idx)
    onChange({ ...districts, [selectedRegion]: list })
  }

  function saveDistrict(idx: number, val: string) {
    if (!val.trim()) return
    const list = [...currentDistricts]
    list[idx] = val.trim()
    onChange({ ...districts, [selectedRegion]: list })
    setEditingDistrict(null)
  }

  return (
    <div className="flex gap-5 mt-2">
      {/* Region sidebar */}
      <div className="w-52 shrink-0">
        <div className="text-[11px] uppercase tracking-wide font-semibold text-[var(--ink-faint)] mb-2 px-1">
          Regions ({regions.length})
        </div>
        <div className="rounded-lg border border-[var(--line)] overflow-hidden bg-[var(--surface)]">
          {regions.map((r) => (
            <div key={r} className={`group flex items-center border-b border-[var(--line)] last:border-0 ${selectedRegion === r ? 'bg-[var(--accent-soft)]' : ''}`}>
              <button
                onClick={() => setSelectedRegion(r)}
                className={`flex-1 text-left px-3 py-2 text-[12.5px] transition-colors ${selectedRegion === r ? 'text-[var(--accent)] font-medium' : 'text-[var(--ink-muted)] hover:text-[var(--ink)]'}`}
              >
                {r}
                <span className="ml-1.5 text-[11px] text-[var(--ink-faint)]">({(districts[r] ?? []).length})</span>
              </button>
              <button
                onClick={() => deleteRegion(r)}
                className="opacity-0 group-hover:opacity-100 p-1 mr-1 rounded hover:bg-[var(--status-bad-bg)] text-[var(--ink-faint)] hover:text-[var(--status-bad)] transition-all"
              >
                <Trash2 className="h-3 w-3" />
              </button>
            </div>
          ))}
        </div>

        {addingRegion ? (
          <div className="mt-2 flex gap-1">
            <input
              autoFocus
              value={newRegion}
              onChange={(e) => setNewRegion(e.target.value)}
              onKeyDown={(e) => e.key === 'Enter' && addRegion()}
              placeholder="Region name"
              className="flex-1 rounded border border-[var(--line)] bg-[var(--surface)] px-2 py-1.5 text-[12px] text-[var(--ink)]"
            />
            <button onClick={addRegion} className="p-1.5 rounded bg-[var(--accent-soft)] text-[var(--accent)]"><Check className="h-3.5 w-3.5" /></button>
            <button onClick={() => { setAddingRegion(false); setNewRegion('') }} className="p-1.5 rounded hover:bg-[var(--line)] text-[var(--ink-faint)]"><X className="h-3.5 w-3.5" /></button>
          </div>
        ) : (
          <button onClick={() => setAddingRegion(true)} className="mt-2 w-full flex items-center gap-1.5 rounded-md border border-dashed border-[var(--line)] px-3 py-1.5 text-[12px] text-[var(--ink-muted)] hover:text-[var(--ink)] hover:border-[var(--ink-faint)] transition-colors">
            <Plus className="h-3.5 w-3.5" /> Add region
          </button>
        )}
      </div>

      {/* Districts list */}
      <div className="flex-1 min-w-0">
        {selectedRegion ? (
          <>
            <div className="text-[11px] uppercase tracking-wide font-semibold text-[var(--ink-faint)] mb-2 px-1">
              Districts in {selectedRegion} ({currentDistricts.length})
            </div>
            <div className="rounded-lg border border-[var(--line)] overflow-hidden bg-[var(--surface)]">
              {currentDistricts.length === 0 && (
                <div className="py-8 text-center text-[13px] text-[var(--ink-faint)]">No districts yet</div>
              )}
              {currentDistricts.map((d, idx) => (
                <div key={idx} className="group flex items-center gap-2 border-b border-[var(--line)] last:border-0 px-4 py-2.5">
                  {editingDistrict?.idx === idx ? (
                    <>
                      <input
                        autoFocus
                        value={editingDistrict.val}
                        onChange={(e) => setEditingDistrict({ idx, val: e.target.value })}
                        onKeyDown={(e) => { if (e.key === 'Enter') saveDistrict(idx, editingDistrict.val); if (e.key === 'Escape') setEditingDistrict(null) }}
                        className="flex-1 rounded border border-[var(--line)] bg-[var(--canvas)] px-2 py-0.5 text-[13px] text-[var(--ink)]"
                      />
                      <button onClick={() => saveDistrict(idx, editingDistrict.val)} className="p-1 rounded bg-[var(--accent-soft)] text-[var(--accent)]"><Check className="h-3.5 w-3.5" /></button>
                      <button onClick={() => setEditingDistrict(null)} className="p-1 rounded hover:bg-[var(--line)] text-[var(--ink-faint)]"><X className="h-3.5 w-3.5" /></button>
                    </>
                  ) : (
                    <>
                      <span className="flex-1 text-[13px] text-[var(--ink)]">{d}</span>
                      <div className="flex gap-1 opacity-0 group-hover:opacity-100 transition-opacity">
                        <button onClick={() => setEditingDistrict({ idx, val: d })} className="p-1 rounded hover:bg-[var(--canvas)] text-[var(--ink-faint)] hover:text-[var(--ink)]">
                          <Pencil className="h-3.5 w-3.5" />
                        </button>
                        <button onClick={() => deleteDistrict(idx)} className="p-1 rounded hover:bg-[var(--status-bad-bg)] text-[var(--ink-faint)] hover:text-[var(--status-bad)]">
                          <Trash2 className="h-3.5 w-3.5" />
                        </button>
                      </div>
                    </>
                  )}
                </div>
              ))}
            </div>

            {addingDistrict ? (
              <div className="mt-2 flex gap-1">
                <input
                  autoFocus
                  value={newDistrict}
                  onChange={(e) => setNewDistrict(e.target.value)}
                  onKeyDown={(e) => e.key === 'Enter' && addDistrict()}
                  placeholder="District name"
                  className="flex-1 rounded border border-[var(--line)] bg-[var(--surface)] px-3 py-1.5 text-[13px] text-[var(--ink)]"
                />
                <button onClick={addDistrict} className="p-1.5 rounded bg-[var(--accent-soft)] text-[var(--accent)]"><Check className="h-4 w-4" /></button>
                <button onClick={() => { setAddingDistrict(false); setNewDistrict('') }} className="p-1.5 rounded hover:bg-[var(--line)] text-[var(--ink-faint)]"><X className="h-4 w-4" /></button>
              </div>
            ) : (
              <button onClick={() => setAddingDistrict(true)} className="mt-2 flex items-center gap-1.5 rounded-md border border-dashed border-[var(--line)] px-3 py-1.5 text-[12px] text-[var(--ink-muted)] hover:text-[var(--ink)] hover:border-[var(--ink-faint)] transition-colors">
                <Plus className="h-3.5 w-3.5" /> Add district
              </button>
            )}
          </>
        ) : (
          <div className="py-16 text-center text-[13px] text-[var(--ink-faint)]">Select a region to manage its districts</div>
        )}
      </div>
    </div>
  )
}

// ─── Page ─────────────────────────────────────────────────────────────────────

type Tab = 'business_types' | 'cities' | 'districts'

export default function LookupsPage() {
  const [activeTab, setActiveTab] = useState<Tab>('business_types')
  const [saving, setSaving] = useState(false)
  const [saveError, setSaveError] = useState('')
  const [dirty, setDirty] = useState(false)

  const { data: remote, loading, revalidating, error, refetch } = useAdminFetch(
    useCallback(() => fetchLookups(), []),
    { key: 'lookups' },
  )

  const [local, setLocal] = useState<AppLookups | null>(null)

  // Sync remote → local once on first load
  if (remote && !local) setLocal(remote)

  const [addingBizType, setAddingBizType] = useState(false)
  const [addingCity, setAddingCity] = useState(false)

  function markDirty(updated: AppLookups) {
    setLocal(updated)
    setDirty(true)
  }

  // ── Business Types ───────────────────────────────────────────────────────────

  function updateBizType(idx: number, updated: LookupBusinessType) {
    if (!local) return
    const list = [...local.businessTypes]
    list[idx] = updated
    markDirty({ ...local, businessTypes: list })
  }

  function addBizType(item: LookupBusinessType) {
    if (!local) return
    markDirty({ ...local, businessTypes: [...local.businessTypes, item] })
    setAddingBizType(false)
  }

  function deleteBizType(idx: number) {
    if (!local) return
    markDirty({ ...local, businessTypes: local.businessTypes.filter((_, i) => i !== idx) })
  }

  // ── Cities ───────────────────────────────────────────────────────────────────

  function updateCity(idx: number, updated: LookupCity) {
    if (!local) return
    const list = [...local.cities]
    list[idx] = updated
    markDirty({ ...local, cities: list })
  }

  function addCity(item: LookupCity) {
    if (!local) return
    markDirty({ ...local, cities: [...local.cities, item] })
    setAddingCity(false)
  }

  function deleteCity(idx: number) {
    if (!local) return
    markDirty({ ...local, cities: local.cities.filter((_, i) => i !== idx) })
  }

  // ── Districts ────────────────────────────────────────────────────────────────

  function updateDistricts(updated: Record<string, string[]>) {
    if (!local) return
    markDirty({ ...local, districts: updated })
  }

  // ── Save ─────────────────────────────────────────────────────────────────────

  async function handleSave() {
    if (!local) return
    setSaving(true)
    setSaveError('')
    try {
      await Promise.all([
        saveLookupBusinessTypes(local.businessTypes),
        saveLookupCities(local.cities),
        saveLookupDistricts(local.districts),
      ])
      setDirty(false)
      refetch()
    } catch (e) {
      setSaveError((e as Error).message ?? 'Save failed')
    } finally {
      setSaving(false)
    }
  }

  const tabs: { id: Tab; label: string; icon: typeof Building2; count: number }[] = local ? [
    { id: 'business_types', label: 'Business Types', icon: Building2, count: local.businessTypes.length },
    { id: 'cities',         label: 'Cities',         icon: MapPin,    count: local.cities.length },
    { id: 'districts',      label: 'Districts',      icon: Clock,     count: Object.keys(local.districts).length },
  ] : []

  return (
    <div>
      <PageHeader
        title="Lookup Data"
        description="Business types, cities, and districts shown in the mobile app"
      >
        {dirty && (
          <button
            onClick={handleSave}
            disabled={saving}
            style={{ backgroundColor: '#0D1B3E' }}
            className="inline-flex items-center gap-1.5 rounded-md px-3 py-1.5 text-[12px] font-medium text-white transition-colors hover:opacity-90 disabled:opacity-50"
          >
            <Save className="h-3.5 w-3.5" />
            {saving ? 'Saving…' : 'Save all changes'}
          </button>
        )}
      </PageHeader>
      {revalidating && <RevalidatingBar />}

      {loading && <SkeletonTable rows={6} cols={4} />}
      {error && !local && (
        <div className="mt-4 flex items-center gap-3 rounded-lg border border-[var(--status-bad)] bg-[var(--status-bad-bg)] p-4 text-[var(--status-bad)]">
          <AlertCircle className="h-4 w-4 shrink-0" />
          <span className="text-[13px]">{error}</span>
        </div>
      )}
      {saveError && (
        <div className="mt-4 flex items-center gap-3 rounded-lg border border-[var(--status-bad)] bg-[var(--status-bad-bg)] p-4 text-[var(--status-bad)]">
          <AlertCircle className="h-4 w-4 shrink-0" />
          <span className="text-[13px]">{saveError}</span>
        </div>
      )}

      {local && (<>
        {/* Tabs */}
        <div className="flex gap-0.5 mb-5 border-b border-[var(--line)]">
          {tabs.map(({ id, label, icon: Icon, count }) => (
            <button
              key={id}
              onClick={() => setActiveTab(id)}
              className={`flex items-center gap-1.5 px-4 py-2.5 text-[13px] font-medium border-b-2 transition-colors -mb-px ${
                activeTab === id
                  ? 'border-[var(--accent)] text-[var(--accent)]'
                  : 'border-transparent text-[var(--ink-muted)] hover:text-[var(--ink)]'
              }`}
            >
              <Icon className="h-3.5 w-3.5" />
              {label}
              <span className="ml-1 rounded-full bg-[var(--line)] px-1.5 py-0.5 text-[10px] font-medium text-[var(--ink-faint)]">
                {count}
              </span>
            </button>
          ))}
        </div>

        {/* ── Business Types ── */}
        {activeTab === 'business_types' && (
          <div>
            <div className="rounded-lg border border-[var(--line)] overflow-hidden bg-[var(--surface)]">
              <table className="w-full border-collapse">
                <thead>
                  <tr className="border-b border-[var(--line)] bg-[var(--canvas)]">
                    <th className="px-4 py-2.5 text-left text-[11px] font-semibold uppercase tracking-wide text-[var(--ink-muted)]">Icon</th>
                    <th className="px-4 py-2.5 text-left text-[11px] font-semibold uppercase tracking-wide text-[var(--ink-muted)]">English</th>
                    <th className="px-4 py-2.5 text-left text-[11px] font-semibold uppercase tracking-wide text-[var(--ink-muted)]">Kiswahili</th>
                    <th className="px-4 py-2.5 text-left text-[11px] font-semibold uppercase tracking-wide text-[var(--ink-muted)]">Key (value)</th>
                    <th className="w-16" />
                  </tr>
                </thead>
                <tbody>
                  {local.businessTypes.map((bt, idx) => (
                    <BizTypeRow
                      key={bt.value + idx}
                      item={bt}
                      onSave={(updated) => updateBizType(idx, updated)}
                      onDelete={() => deleteBizType(idx)}
                    />
                  ))}
                  {addingBizType && (
                    <BizTypeRow
                      key="__new__"
                      item={{ value: '', en: '', sw: '', icon: 'store' }}
                      onSave={addBizType}
                      onDelete={() => {}}
                      isNew
                      onCancelNew={() => setAddingBizType(false)}
                    />
                  )}
                </tbody>
              </table>
            </div>
            <button
              onClick={() => setAddingBizType(true)}
              className="mt-3 flex items-center gap-1.5 rounded-md border border-dashed border-[var(--line)] px-3 py-2 text-[12.5px] text-[var(--ink-muted)] hover:text-[var(--ink)] hover:border-[var(--ink-faint)] transition-colors"
            >
              <Plus className="h-3.5 w-3.5" /> Add business type
            </button>
          </div>
        )}

        {/* ── Cities ── */}
        {activeTab === 'cities' && (
          <div>
            <div className="rounded-lg border border-[var(--line)] overflow-hidden bg-[var(--surface)]">
              <table className="w-full border-collapse">
                <thead>
                  <tr className="border-b border-[var(--line)] bg-[var(--canvas)]">
                    <th className="px-4 py-2.5 text-left text-[11px] font-semibold uppercase tracking-wide text-[var(--ink-muted)]">English</th>
                    <th className="px-4 py-2.5 text-left text-[11px] font-semibold uppercase tracking-wide text-[var(--ink-muted)]">Kiswahili</th>
                    <th className="w-16" />
                  </tr>
                </thead>
                <tbody>
                  {local.cities.map((city, idx) => (
                    <CityRow
                      key={city.en + idx}
                      item={city}
                      onSave={(updated) => updateCity(idx, updated)}
                      onDelete={() => deleteCity(idx)}
                    />
                  ))}
                  {addingCity && (
                    <CityRow
                      key="__new__"
                      item={{ en: '', sw: '' }}
                      onSave={addCity}
                      onDelete={() => {}}
                      isNew
                      onCancelNew={() => setAddingCity(false)}
                    />
                  )}
                </tbody>
              </table>
            </div>
            <button
              onClick={() => setAddingCity(true)}
              className="mt-3 flex items-center gap-1.5 rounded-md border border-dashed border-[var(--line)] px-3 py-2 text-[12.5px] text-[var(--ink-muted)] hover:text-[var(--ink)] hover:border-[var(--ink-faint)] transition-colors"
            >
              <Plus className="h-3.5 w-3.5" /> Add city
            </button>
          </div>
        )}

        {/* ── Districts ── */}
        {activeTab === 'districts' && (
          <DistrictsPanel districts={local.districts} onChange={updateDistricts} />
        )}
      </>)}
    </div>
  )
}
