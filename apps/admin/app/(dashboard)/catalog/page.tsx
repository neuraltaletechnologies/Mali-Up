'use client'

import { useState } from 'react'
import { PageHeader } from '@/components/ui/page-header'
import { DataTable } from '@/components/ui/data-table'
import { DetailDrawer } from '@/components/ui/detail-drawer'
import { ConfirmDialog } from '@/components/ui/confirm-dialog'
import { mockProducts } from '@/lib/mock-data'
import type { MasterProduct } from '@/types'
import type { ColumnDef } from '@tanstack/react-table'
import { Plus, Upload, Pencil, Trash2, Pill, FlaskConical, ShoppingCart, Hammer } from 'lucide-react'
import { formatDate } from '@/lib/format'

const BUSINESS_TYPES = ['All', 'Pharmacy', 'Supermarket', 'Hardware', 'Electronics', 'Restaurant', 'Boutique']

const columns: ColumnDef<MasterProduct, unknown>[] = [
  {
    accessorKey: 'productName',
    header: 'Product Name',
    cell: ({ row }) => (
      <div>
        <div className="font-medium text-[var(--ink)]">{row.original.productName}</div>
        {row.original.genericName && (
          <div className="text-[11px] text-[var(--ink-faint)]">{row.original.genericName}</div>
        )}
      </div>
    ),
  },
  {
    accessorKey: 'category',
    header: 'Category',
    cell: ({ row }) => <span className="text-[var(--ink-muted)]">{row.original.category}</span>,
  },
  {
    accessorKey: 'unit',
    header: 'Unit',
    cell: ({ row }) => <span className="font-mono text-[var(--ink-muted)]">{row.original.unit}</span>,
  },
  {
    accessorKey: 'commonBarcodes',
    header: 'Barcodes',
    cell: ({ row }) => (
      <span className="font-mono text-[var(--ink-faint)]">{row.original.commonBarcodes.length}</span>
    ),
  },
  {
    accessorKey: 'tags',
    header: 'Tags',
    cell: ({ row }) => (
      <div className="flex gap-1 flex-wrap">
        {row.original.tags.slice(0, 3).map((t) => (
          <span key={t} className="rounded px-1.5 py-0.5 text-[10px] bg-[var(--line)] text-[var(--ink-muted)]">{t}</span>
        ))}
      </div>
    ),
  },
  {
    id: 'flags',
    header: 'Flags',
    cell: ({ row }) => (
      <div className="flex gap-1">
        {row.original.prescriptionRequired && (
          <span className="rounded px-1.5 py-0.5 text-[10px] bg-[var(--status-warn-bg)] text-[var(--status-warn)] font-medium">Rx</span>
        )}
        {row.original.coldStorage && (
          <span className="rounded px-1.5 py-0.5 text-[10px] bg-[#EEF6FF] text-[#2563EB] font-medium">Cold</span>
        )}
      </div>
    ),
  },
  {
    id: 'actions',
    header: '',
    cell: ({ row }) => (
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

export default function CatalogPage() {
  const [businessType, setBusinessType] = useState('All')
  const [showAddProduct, setShowAddProduct] = useState(false)
  const [showImport, setShowImport] = useState(false)

  const filtered = businessType === 'All'
    ? mockProducts
    : mockProducts.filter((p) => p.businessType === businessType)

  const categories = [...new Set(filtered.map((p) => p.category))]

  return (
    <div>
      <PageHeader
        title="Master Catalog"
        description="Global read-only product catalog for all businesses"
      >
        <button
          onClick={() => setShowImport(true)}
          className="inline-flex items-center gap-1.5 rounded-md border border-[var(--line)] bg-[var(--surface)] px-3 py-1.5 text-[12px] font-medium text-[var(--ink-muted)] hover:text-[var(--ink)] transition-colors"
        >
          <Upload className="h-3.5 w-3.5" />
          Import CSV
        </button>
        <button
          onClick={() => setShowAddProduct(true)}
          className="inline-flex items-center gap-1.5 rounded-md bg-[var(--navy)] px-3 py-1.5 text-[12px] font-medium text-white hover:bg-[var(--navy-soft)] transition-colors"
        >
          <Plus className="h-3.5 w-3.5" />
          Add product
        </button>
      </PageHeader>

      {/* Business type sidebar */}
      <div className="flex gap-4">
        <div className="w-44 shrink-0">
          <div className="text-[11px] uppercase tracking-wide text-[var(--ink-faint)] mb-2 px-1">Business Type</div>
          <div className="flex flex-col gap-0.5">
            {BUSINESS_TYPES.map((bt) => (
              <button
                key={bt}
                onClick={() => setBusinessType(bt)}
                className={`w-full text-left rounded-md px-3 py-2 text-[12.5px] transition-colors ${
                  businessType === bt
                    ? 'bg-[var(--accent-soft)] text-[var(--accent)] font-medium'
                    : 'text-[var(--ink-muted)] hover:text-[var(--ink)] hover:bg-[var(--canvas)]'
                }`}
              >
                {bt}
              </button>
            ))}
            <button className="w-full text-left rounded-md px-3 py-2 text-[12px] text-[var(--accent)] hover:underline flex items-center gap-1">
              <Plus className="h-3 w-3" />
              Add type
            </button>
          </div>
        </div>

        <div className="flex-1 min-w-0">
          {categories.length === 0 ? (
            <div className="text-center py-12 text-[var(--ink-faint)] text-[13px]">
              No products for this business type yet.
              <button onClick={() => setShowAddProduct(true)} className="ml-1 text-[var(--accent)] hover:underline">Add the first one →</button>
            </div>
          ) : (
            <DataTable
              data={filtered}
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
        onClose={() => setShowAddProduct(false)}
        title="Add Product"
        description="Add a product to the master catalog"
        width="w-[520px]"
      >
        <form className="flex flex-col gap-4">
          {[
            { label: 'Product Name', name: 'productName', required: true, placeholder: 'e.g. Paracetamol 500mg' },
            { label: 'Generic Name', name: 'genericName', placeholder: 'e.g. Paracetamol' },
            { label: 'Unit', name: 'unit', required: true, placeholder: 'e.g. tablet, pack, kg' },
            { label: 'Category', name: 'category', required: true, placeholder: 'e.g. Analgesics' },
            { label: 'Search Keywords (comma-separated)', name: 'searchKeywords', placeholder: 'e.g. panadol, pain relief' },
            { label: 'Brand Names (comma-separated)', name: 'brandNames', placeholder: 'e.g. Panadol, Hedex' },
            { label: 'Common Barcodes (comma-separated)', name: 'commonBarcodes', placeholder: 'e.g. 5010119013458' },
            { label: 'Tags (comma-separated)', name: 'tags', placeholder: 'e.g. otc, analgesic' },
          ].map(({ label, name, required, placeholder }) => (
            <div key={name} className="flex flex-col gap-1.5">
              <label className="text-[12px] font-medium text-[var(--ink-muted)]">
                {label}{required && <span className="text-[var(--status-bad)]"> *</span>}
              </label>
              <input
                name={name}
                placeholder={placeholder}
                className="w-full rounded-md border border-[var(--line)] bg-[var(--canvas)] px-3 py-2 text-[13px] focus:outline-none focus:ring-1 focus:ring-[var(--accent)]"
              />
            </div>
          ))}

          <div className="flex gap-4">
            <label className="flex items-center gap-2 text-[12px] text-[var(--ink-muted)]">
              <input type="checkbox" className="rounded" />
              Prescription Required
            </label>
            <label className="flex items-center gap-2 text-[12px] text-[var(--ink-muted)]">
              <input type="checkbox" className="rounded" />
              Cold Storage
            </label>
          </div>

          <div className="mt-2 flex gap-2 justify-end">
            <button
              type="button"
              onClick={() => setShowAddProduct(false)}
              className="rounded-md border border-[var(--line)] px-4 py-2 text-[12px] font-medium text-[var(--ink-muted)] hover:text-[var(--ink)]"
            >
              Cancel
            </button>
            <button
              type="submit"
              className="rounded-md bg-[var(--navy)] px-4 py-2 text-[12px] font-medium text-white hover:bg-[var(--navy-soft)] transition-colors"
            >
              Add to catalog
            </button>
          </div>
        </form>
      </DetailDrawer>
    </div>
  )
}
