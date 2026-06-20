'use client'

import { useState, useCallback } from 'react'
import { PageHeader } from '@/components/ui/page-header'
import { DataTable } from '@/components/ui/data-table'
import { DetailDrawer } from '@/components/ui/detail-drawer'
import { Skeleton } from '@/components/ui/skeleton'
import { fetchCatalog, postCatalogProduct } from '@/lib/admin-api'
import { useAdminFetch } from '@/hooks/use-admin-fetch'
import type { CatalogProduct } from '@/types'
import type { ColumnDef } from '@tanstack/react-table'
import { Plus, Upload, Pencil, Trash2, AlertCircle } from 'lucide-react'
import { formatTZS } from '@/lib/format'

const columns: ColumnDef<CatalogProduct, unknown>[] = [
  {
    accessorKey: 'productName',
    header: 'Product Name',
    cell: ({ row }) => (
      <div>
        <div className="font-medium text-[var(--ink)]">{row.original.productName}</div>
        {row.original.skuTemplate && (
          <div className="text-[11px] text-[var(--ink-faint)] font-mono">{row.original.skuTemplate}</div>
        )}
      </div>
    ),
  },
  {
    accessorKey: 'categoryName',
    header: 'Category',
    cell: ({ row }) => <span className="text-[var(--ink-muted)]">{row.original.categoryName || '—'}</span>,
  },
  {
    accessorKey: 'defaultUnit',
    header: 'Unit',
    cell: ({ row }) => <span className="font-mono text-[var(--ink-muted)]">{row.original.defaultUnit}</span>,
  },
  {
    accessorKey: 'barcode',
    header: 'Barcode',
    cell: ({ row }) => (
      <span className="font-mono text-[var(--ink-faint)] text-[11px]">
        {row.original.barcode || '—'}
      </span>
    ),
  },
  {
    accessorKey: 'suggestedSellingPrice',
    header: 'Selling Price',
    cell: ({ row }) => (
      <span className="font-mono text-[var(--ink)] tabular-nums">
        {row.original.suggestedSellingPrice > 0
          ? formatTZS(row.original.suggestedSellingPrice)
          : <span className="text-[var(--ink-faint)]">—</span>
        }
      </span>
    ),
  },
  {
    accessorKey: 'source',
    header: 'Source',
    cell: ({ row }) => (
      <span className={`rounded px-1.5 py-0.5 text-[10px] font-medium ${
        row.original.source === 'community'
          ? 'bg-[var(--status-warn-bg)] text-[var(--status-warn)]'
          : 'bg-[var(--line)] text-[var(--ink-muted)]'
      }`}>
        {row.original.source === 'community' ? 'Community' : 'Admin'}
      </span>
    ),
  },
  {
    id: 'actions',
    header: '',
    cell: () => (
      <div className="flex gap-1 opacity-0 group-hover:opacity-100 transition-opacity">
        <button className="p-1 rounded hover:bg-[var(--canvas)] text-[var(--ink-faint)] hover:text-[var(--ink)]">
          <Pencil className="h-3.5 w-3.5" />
        </button>
        <button className="p-1 rounded hover:bg-[var(--status-bad-bg)] text-[var(--ink-faint)] hover:text-[var(--status-bad)]">
          <Trash2 className="h-3.5 w-3.5" />
        </button>
      </div>
    ),
  },
]

const EMPTY_FORM = {
  productName: '',
  businessTypeId: '',
  categoryId: '',
  categoryName: '',
  defaultUnit: '',
  skuTemplate: '',
  barcode: '',
  suggestedCostPrice: '',
  suggestedSellingPrice: '',
  searchableKeywords: '',
}

export default function CatalogPage() {
  const [selectedTypeId, setSelectedTypeId] = useState<string>('')
  const [showAddProduct, setShowAddProduct] = useState(false)
  const [saving, setSaving] = useState(false)
  const [form, setForm] = useState(EMPTY_FORM)

  const { data, loading, error, refetch } = useAdminFetch(
    useCallback(() => fetchCatalog(selectedTypeId || undefined), [selectedTypeId])
  )

  const businessTypeIds = data?.businessTypeIds ?? []
  const products = data?.products ?? []
  const categories = data?.categories ?? []

  async function handleAddProduct(e: React.FormEvent) {
    e.preventDefault()
    setSaving(true)
    try {
      await postCatalogProduct({
        ...form,
        suggestedCostPrice: Number(form.suggestedCostPrice) || 0,
        suggestedSellingPrice: Number(form.suggestedSellingPrice) || 0,
        searchableKeywords: form.searchableKeywords
          .split(',')
          .map((k) => k.trim())
          .filter(Boolean),
      })
      setShowAddProduct(false)
      setForm(EMPTY_FORM)
      refetch()
    } finally {
      setSaving(false)
    }
  }

  if (loading) {
    return (
      <div>
        <PageHeader title="Master Catalog" description="Loading…" />
        <div className="flex gap-4 mt-4">
          <Skeleton className="w-44 h-64 rounded-lg shrink-0" />
          <div className="flex-1 space-y-2">
            {Array.from({ length: 6 }).map((_, i) => <Skeleton key={i} className="h-10 w-full" />)}
          </div>
        </div>
      </div>
    )
  }

  if (error) {
    return (
      <div>
        <PageHeader title="Master Catalog" description="Failed to load" />
        <div className="mt-8 flex items-center gap-3 rounded-lg border border-[var(--status-bad)] bg-[var(--status-bad-bg)] p-4 text-[var(--status-bad)]">
          <AlertCircle className="h-4 w-4 shrink-0" />
          <span className="text-[13px]">{error}</span>
        </div>
      </div>
    )
  }

  return (
    <div>
      <PageHeader
        title="Master Catalog"
        description={`${data?.total ?? 0} products across ${businessTypeIds.length} business types`}
      >
        <button
          onClick={() => setShowAddProduct(true)}
          className="inline-flex items-center gap-1.5 rounded-md bg-[var(--navy)] px-3 py-1.5 text-[12px] font-medium text-white hover:bg-[var(--navy-soft)] transition-colors"
        >
          <Plus className="h-3.5 w-3.5" />
          Add product
        </button>
      </PageHeader>

      <div className="flex gap-4">
        {/* Business type sidebar */}
        <div className="w-48 shrink-0">
          <div className="text-[11px] uppercase tracking-wide text-[var(--ink-faint)] mb-2 px-1">Business Type</div>
          <div className="flex flex-col gap-0.5">
            <button
              onClick={() => setSelectedTypeId('')}
              className={`w-full text-left rounded-md px-3 py-2 text-[12.5px] transition-colors ${
                selectedTypeId === ''
                  ? 'bg-[var(--accent-soft)] text-[var(--accent)] font-medium'
                  : 'text-[var(--ink-muted)] hover:text-[var(--ink)] hover:bg-[var(--canvas)]'
              }`}
            >
              All types
              <span className="ml-1.5 text-[11px] text-[var(--ink-faint)]">({data?.total ?? 0})</span>
            </button>
            {businessTypeIds.map((typeId) => {
              const count = products.filter((p) => p.businessTypeId === typeId).length
              return (
                <button
                  key={typeId}
                  onClick={() => setSelectedTypeId(typeId)}
                  className={`w-full text-left rounded-md px-3 py-2 text-[12.5px] transition-colors ${
                    selectedTypeId === typeId
                      ? 'bg-[var(--accent-soft)] text-[var(--accent)] font-medium'
                      : 'text-[var(--ink-muted)] hover:text-[var(--ink)] hover:bg-[var(--canvas)]'
                  }`}
                >
                  {typeId.charAt(0).toUpperCase() + typeId.slice(1)}
                  <span className="ml-1.5 text-[11px] text-[var(--ink-faint)]">({count})</span>
                </button>
              )
            })}
          </div>

          {/* Category breakdown */}
          {categories.length > 0 && (
            <div className="mt-5">
              <div className="text-[11px] uppercase tracking-wide text-[var(--ink-faint)] mb-2 px-1">Categories</div>
              <div className="flex flex-col gap-0.5">
                {categories.map((cat) => (
                  <div
                    key={cat.id}
                    className="flex items-center justify-between rounded-md px-3 py-1.5 text-[11.5px] text-[var(--ink-muted)]"
                  >
                    <span className="truncate">{cat.categoryName}</span>
                    <span className="shrink-0 text-[var(--ink-faint)] font-mono ml-1">{cat.productCount}</span>
                  </div>
                ))}
              </div>
            </div>
          )}
        </div>

        {/* Products table */}
        <div className="flex-1 min-w-0">
          {products.length === 0 ? (
            <div className="text-center py-12 text-[var(--ink-faint)] text-[13px]">
              {businessTypeIds.length === 0
                ? 'No products in the catalog yet.'
                : `No products for "${selectedTypeId || 'this type'}".`}
              <button
                onClick={() => setShowAddProduct(true)}
                className="ml-1 text-[var(--accent)] hover:underline"
              >
                Add the first one →
              </button>
            </div>
          ) : (
            <DataTable
              data={products}
              columns={columns}
              searchPlaceholder="Search products…"
              exportFilename="catalog"
              emptyState={<p className="text-[var(--ink-faint)] text-[13px]">No products found</p>}
            />
          )}
        </div>
      </div>

      {/* Add product drawer */}
      <DetailDrawer
        open={showAddProduct}
        onClose={() => { setShowAddProduct(false); setForm(EMPTY_FORM) }}
        title="Add Product"
        description="Add a product to the master catalog"
        width="w-[520px]"
      >
        <form onSubmit={handleAddProduct} className="flex flex-col gap-4">
          {([
            { label: 'Product Name *',            key: 'productName',          required: true,  placeholder: 'e.g. Paracetamol 500mg' },
            { label: 'Business Type ID *',         key: 'businessTypeId',       required: true,  placeholder: 'e.g. pharmacy, supermarket' },
            { label: 'Category Name',              key: 'categoryName',         required: false, placeholder: 'e.g. Analgesics' },
            { label: 'Default Unit *',             key: 'defaultUnit',          required: true,  placeholder: 'e.g. tablet, pack, kg' },
            { label: 'SKU Template',               key: 'skuTemplate',          required: false, placeholder: 'e.g. PARA-500-{n}' },
            { label: 'Barcode',                    key: 'barcode',              required: false, placeholder: 'e.g. 5010119013458' },
            { label: 'Suggested Cost Price (TZS)', key: 'suggestedCostPrice',   required: false, placeholder: '0' },
            { label: 'Suggested Selling Price',    key: 'suggestedSellingPrice',required: false, placeholder: '0' },
            { label: 'Keywords (comma-separated)', key: 'searchableKeywords',   required: false, placeholder: 'e.g. panadol, pain relief' },
          ] as { label: string; key: keyof typeof form; required: boolean; placeholder: string }[])
            .map(({ label, key, required, placeholder }) => (
            <div key={key} className="flex flex-col gap-1.5">
              <label className="text-[12px] font-medium text-[var(--ink-muted)]">{label}</label>
              <input
                value={form[key]}
                onChange={(e) => setForm((f) => ({ ...f, [key]: e.target.value }))}
                required={required}
                placeholder={placeholder}
                className="w-full rounded-md border border-[var(--line)] bg-[var(--canvas)] px-3 py-2 text-[13px] focus:outline-none focus:ring-1 focus:ring-[var(--accent)]"
              />
            </div>
          ))}

          <div className="mt-2 flex gap-2 justify-end">
            <button
              type="button"
              onClick={() => { setShowAddProduct(false); setForm(EMPTY_FORM) }}
              className="rounded-md border border-[var(--line)] px-4 py-2 text-[12px] font-medium text-[var(--ink-muted)] hover:text-[var(--ink)]"
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={saving}
              className="rounded-md bg-[var(--navy)] px-4 py-2 text-[12px] font-medium text-white hover:bg-[var(--navy-soft)] transition-colors disabled:opacity-50"
            >
              {saving ? 'Saving…' : 'Add to catalog'}
            </button>
          </div>
        </form>
      </DetailDrawer>
    </div>
  )
}
