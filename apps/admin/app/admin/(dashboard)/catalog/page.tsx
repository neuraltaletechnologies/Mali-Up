'use client'

import { useState, useCallback } from 'react'
import { PageHeader } from '@/components/ui/page-header'
import { DataTable } from '@/components/ui/data-table'
import { DetailDrawer } from '@/components/ui/detail-drawer'
import { ConfirmDialog } from '@/components/ui/confirm-dialog'
import { SkeletonTable, RevalidatingBar } from '@/components/ui/skeleton'
import {
  fetchCatalog,
  postCatalogProduct, patchCatalogProduct, deleteCatalogProduct,
  postCatalogCategory, patchCatalogCategory, deleteCatalogCategory,
  bulkReassignCatalog,
} from '@/lib/admin-api'
import { useAdminFetch } from '@/hooks/use-admin-fetch'
import type { CatalogProduct, CatalogCategory } from '@/types'
import type { ColumnDef } from '@tanstack/react-table'
import { Plus, Pencil, Trash2, AlertCircle, Tag, Package, Snowflake, Pill, ListChecks, TriangleAlert } from 'lucide-react'

// ─── Constants ────────────────────────────────────────────────────────────────

const BUSINESS_TYPES = [
  'Retail','Wholesale','Supermarket','Grocery & Convenience',
  'Electronics & Mobile Phones','Fashion & Boutique','Tailoring & Textiles',
  'Beauty & Cosmetics','Salon & Barber','Restaurant','Cafe & Bakery',
  'Street Food','Catering','Agriculture','Agribusiness','Livestock & Poultry',
  'Fishing','Manufacturing','Construction','Hardware & Building Materials',
  'Transportation & Logistics','Travel & Tours','Hotel & Accommodation',
  'Pharmacy & Healthcare','Clinic & Laboratory','Education & Training',
  'Real Estate','Financial Services','ICT & Software','Printing & Stationery',
  'Automotive & Spare Parts','Fuel & Lubricants','E-Commerce',
  'Entertainment & Events','Cleaning Services','Security Services',
  'NGO & Community Services','Export & Import','Agricultural Inputs',
  'Media & Communications','Jewelry & Crafts','Furniture & Carpentry',
  'Water & Beverages','Auto Repair','Other',
]

const UNITS = [
  'Piece','Kg','g','Litre','ml','Pack','Box','Tablet','Bottle','Dozen',
  'Pair','Roll','Bag','Carton','Case','Sachet','Tube','Can','Jar','Bucket',
  'Sheet','Metre','Set','Kit','Load','Ton','Ream','Book',
  'Plate','Gram','Vial','Inhaler','Cartridge',
]

const TAGS = ['common','fmcg','seasonal','imported','local','prescription']

const ICONS = [
  'inventory_2','store','storefront','shopping_bag','phone_android','checkroom',
  'content_cut','face','restaurant','bakery_dining','lunch_dining','agriculture',
  'pets','build','construction','handyman','local_shipping','travel_explore',
  'hotel','medical_services','school','real_estate_agent','account_balance',
  'computer','print','directions_car','local_gas_station','campaign',
  'cleaning_services','security','category','sell','home','local_drink',
  'science','box','medication','nutrition','format_paint','hardware',
  'forest','engineering','floor_lamp','roofing','foundation','wifi',
  'water_drop','diamond','brush','videocam','event','music_note','factory',
]

const EMPTY_PRODUCT = {
  businessTypes:       [] as string[],
  categorySlug:        '',
  productName:         '',
  productNameSw:       '',
  genericName:         '',
  brandNames:          '',
  unit:                'Piece',
  unitAlternatives:    '',
  commonBarcodes:      '',
  searchKeywords:      '',
  prescriptionRequired: false,
  coldStorage:         false,
  tags:                [] as string[],
}

const EMPTY_CATEGORY = {
  businessTypes:  [] as string[],
  categoryName:   '',
  categoryNameSw: '',
  icon:           'inventory_2',
  displayOrder:   0,
}

type ProductForm  = typeof EMPTY_PRODUCT
type CategoryForm = typeof EMPTY_CATEGORY

// ─── Helpers ─────────────────────────────────────────────────────────────────

function productToForm(p: CatalogProduct): ProductForm {
  return {
    businessTypes:       [...p.businessTypes],
    categorySlug:        p.categorySlug,
    productName:         p.productName,
    productNameSw:       p.productNameSw,
    genericName:         p.genericName,
    brandNames:          p.brandNames.join(', '),
    unit:                p.unit,
    unitAlternatives:    p.unitAlternatives.join(', '),
    commonBarcodes:      p.commonBarcodes.join(', '),
    searchKeywords:      p.searchKeywords.join(', '),
    prescriptionRequired: p.prescriptionRequired,
    coldStorage:         p.coldStorage,
    tags:                [...p.tags],
  }
}

function productFormToPayload(form: ProductForm) {
  return {
    businessTypes:        form.businessTypes,
    categorySlug:         form.categorySlug,
    productName:          form.productName,
    productNameSw:        form.productNameSw,
    genericName:          form.genericName,
    brandNames:           form.brandNames.split(',').map((s) => s.trim()).filter(Boolean),
    unit:                 form.unit,
    unitAlternatives:     form.unitAlternatives.split(',').map((s) => s.trim()).filter(Boolean),
    commonBarcodes:       form.commonBarcodes.split(',').map((s) => s.trim()).filter(Boolean),
    searchKeywords:       form.searchKeywords.split(',').map((s) => s.trim()).filter(Boolean),
    prescriptionRequired: form.prescriptionRequired,
    coldStorage:          form.coldStorage,
    tags:                 form.tags,
  }
}

function categoryToForm(c: CatalogCategory): CategoryForm {
  return {
    businessTypes:  [...c.businessTypes],
    categoryName:   c.categoryName,
    categoryNameSw: c.categoryNameSw,
    icon:           c.icon || 'inventory_2',
    displayOrder:   c.displayOrder,
  }
}

// ─── Shared styles ────────────────────────────────────────────────────────────

const inputCls = 'w-full rounded-md border border-[var(--line)] bg-[var(--canvas)] px-3 py-2 text-[13px] text-[var(--ink)] focus:outline-none focus:ring-1 focus:ring-[var(--accent)]'
const labelCls = 'text-[12px] font-medium text-[var(--ink-muted)]'
const selectCls = `${inputCls} appearance-none`
const sectionHeading = 'text-[11px] uppercase tracking-wide font-semibold text-[var(--ink-faint)] mb-3'
const checkboxRowCls = 'flex items-center gap-2.5 rounded-md border border-[var(--line)] px-3 py-2.5 hover:bg-[var(--canvas)] cursor-pointer'

// ─── Business type multi-select (toggle pills) ────────────────────────────────

function BusinessTypeToggles({
  selected, options, onToggle,
}: {
  selected: string[]
  options: string[]
  onToggle: (type: string) => void
}) {
  return (
    <div className="flex flex-wrap gap-2 max-h-40 overflow-y-auto rounded-md border border-[var(--line)] p-2.5">
      {options.map((t) => (
        <button key={t} type="button" onClick={() => onToggle(t)}
          className={`rounded-full px-3 py-1 text-[12px] font-medium transition-colors border ${
            selected.includes(t)
              ? 'bg-[var(--accent)] border-[var(--accent)] text-white'
              : 'border-[var(--line)] text-[var(--ink-muted)] hover:text-[var(--ink)]'
          }`}>
          {t}
        </button>
      ))}
    </div>
  )
}

// ─── Page ─────────────────────────────────────────────────────────────────────

export default function CatalogPage() {
  const [activeTab,      setActiveTab]      = useState<'categories' | 'products'>('categories')
  const [selectedType,   setSelectedType]   = useState('')

  // Product state
  const [showAddProduct, setShowAddProduct] = useState(false)
  const [editProduct,    setEditProduct]    = useState<CatalogProduct | null>(null)
  const [deleteProduct,  setDeleteProduct]  = useState<CatalogProduct | null>(null)
  const [productForm,    setProductForm]    = useState<ProductForm>(EMPTY_PRODUCT)

  // Category state
  const [showAddCat,     setShowAddCat]     = useState(false)
  const [editCat,        setEditCat]        = useState<CatalogCategory | null>(null)
  const [deleteCat,      setDeleteCat]      = useState<CatalogCategory | null>(null)
  const [catForm,        setCatForm]        = useState<CategoryForm>(EMPTY_CATEGORY)

  const [saving, setSaving] = useState(false)
  const [formError, setFormError] = useState('')

  // Bulk reassign state
  const [selectedCatIds,  setSelectedCatIds]  = useState<Set<string>>(new Set())
  const [selectedProdIds, setSelectedProdIds] = useState<Set<string>>(new Set())
  const [bulkEntity,   setBulkEntity]   = useState<'category' | 'product' | null>(null)
  const [bulkMode,     setBulkMode]     = useState<'add' | 'remove' | 'replace'>('add')
  const [bulkTypes,    setBulkTypes]    = useState<string[]>([])
  const [bulkSaving,   setBulkSaving]   = useState(false)
  const [bulkError,    setBulkError]    = useState('')

  // Review: surface products whose business types don't overlap their own category's
  const [showMismatchesOnly, setShowMismatchesOnly] = useState(false)

  const { data, loading, revalidating, error, refetch } = useAdminFetch(
    useCallback(() => fetchCatalog(selectedType || undefined), [selectedType]),
    { key: `catalog-${selectedType || 'all'}` },
  )

  const categories     = data?.categories ?? []
  const products       = data?.products   ?? []
  const dbTypes        = data?.businessTypes ?? []

  const allTypes = [...new Set([...BUSINESS_TYPES, ...dbTypes])].sort()

  const visibleCats  = selectedType ? categories.filter((c) => c.businessTypes.includes(selectedType)) : categories
  let visibleProds   = selectedType ? products.filter((p) => p.businessTypes.includes(selectedType))   : products

  const formCats = categories.filter((c) => c.businessTypes.some((t) => productForm.businessTypes.includes(t)))

  function isMismatched(p: CatalogProduct): boolean {
    const cat = categories.find((c) => c.categorySlug === p.categorySlug)
    if (!cat) return true
    return !cat.businessTypes.some((t) => p.businessTypes.includes(t))
  }

  const mismatchedCount = products.filter(isMismatched).length
  if (showMismatchesOnly) visibleProds = visibleProds.filter(isMismatched)

  // ── Handlers ─────────────────────────────────────────────────────────────────

  async function handleAddProduct(e: React.FormEvent) {
    e.preventDefault()
    if (productForm.businessTypes.length === 0) {
      setFormError('Select at least one business type.'); return
    }
    setFormError('')
    setSaving(true)
    try {
      await postCatalogProduct(productFormToPayload(productForm))
      setShowAddProduct(false)
      setProductForm(EMPTY_PRODUCT)
      refetch()
    } catch (err) {
      setFormError((err as Error).message ?? 'Save failed')
    } finally { setSaving(false) }
  }

  async function handleEditProduct(e: React.FormEvent) {
    e.preventDefault()
    if (!editProduct) return
    if (productForm.businessTypes.length === 0) {
      setFormError('Select at least one business type.'); return
    }
    setFormError('')
    setSaving(true)
    try {
      await patchCatalogProduct(editProduct.id, productFormToPayload(productForm))
      setEditProduct(null)
      setProductForm(EMPTY_PRODUCT)
      refetch()
    } catch (err) {
      setFormError((err as Error).message ?? 'Save failed')
    } finally { setSaving(false) }
  }

  async function handleDeleteProduct() {
    if (!deleteProduct) return
    await deleteCatalogProduct(deleteProduct.id)
    setDeleteProduct(null)
    refetch()
  }

  async function handleAddCat(e: React.FormEvent) {
    e.preventDefault()
    if (catForm.businessTypes.length === 0) {
      setFormError('Select at least one business type.'); return
    }
    setFormError('')
    setSaving(true)
    try {
      await postCatalogCategory(catForm)
      setShowAddCat(false)
      setCatForm(EMPTY_CATEGORY)
      refetch()
    } catch (err) {
      setFormError((err as Error).message ?? 'Save failed')
    } finally { setSaving(false) }
  }

  async function handleEditCat(e: React.FormEvent) {
    e.preventDefault()
    if (!editCat) return
    if (catForm.businessTypes.length === 0) {
      setFormError('Select at least one business type.'); return
    }
    setFormError('')
    setSaving(true)
    try {
      await patchCatalogCategory(editCat.id, catForm)
      setEditCat(null)
      setCatForm(EMPTY_CATEGORY)
      refetch()
    } catch (err) {
      setFormError((err as Error).message ?? 'Save failed')
    } finally { setSaving(false) }
  }

  async function handleDeleteCat() {
    if (!deleteCat) return
    await deleteCatalogCategory(deleteCat.id)
    setDeleteCat(null)
    refetch()
  }

  // ── Bulk selection + reassign ──────────────────────────────────────────────

  function toggleCatSelected(id: string) {
    setSelectedCatIds((s) => {
      const next = new Set(s)
      if (next.has(id)) next.delete(id); else next.add(id)
      return next
    })
  }

  function toggleProdSelected(id: string) {
    setSelectedProdIds((s) => {
      const next = new Set(s)
      if (next.has(id)) next.delete(id); else next.add(id)
      return next
    })
  }

  function toggleBulkType(type: string) {
    setBulkTypes((ts) => ts.includes(type) ? ts.filter((t) => t !== type) : [...ts, type])
  }

  function openBulkDrawer(entity: 'category' | 'product') {
    setBulkEntity(entity)
    setBulkMode('add')
    setBulkTypes([])
    setBulkError('')
  }

  async function handleBulkApply() {
    if (!bulkEntity || bulkTypes.length === 0) return
    const ids = [...(bulkEntity === 'category' ? selectedCatIds : selectedProdIds)]
    if (ids.length === 0) return
    setBulkSaving(true); setBulkError('')
    try {
      await bulkReassignCatalog(bulkEntity, ids, bulkMode, bulkTypes)
      setBulkEntity(null)
      if (bulkEntity === 'category') setSelectedCatIds(new Set()); else setSelectedProdIds(new Set())
      refetch()
    } catch (err) {
      setBulkError((err as Error).message ?? 'Bulk update failed')
    } finally {
      setBulkSaving(false)
    }
  }

  function toggleTag(tag: string) {
    setProductForm((f) => ({
      ...f,
      tags: f.tags.includes(tag) ? f.tags.filter((t) => t !== tag) : [...f.tags, tag],
    }))
  }

  // ── Column defs ───────────────────────────────────────────────────────────────

  const categoryColumns: ColumnDef<CatalogCategory, unknown>[] = [
    {
      id: 'select',
      header: () => (
        <input
          type="checkbox"
          checked={visibleCats.length > 0 && visibleCats.every((c) => selectedCatIds.has(c.id))}
          onChange={() => setSelectedCatIds((s) =>
            visibleCats.every((c) => s.has(c.id)) ? new Set() : new Set(visibleCats.map((c) => c.id)))}
          className="rounded border-[var(--line)]"
        />
      ),
      size: 36,
      cell: ({ row }) => (
        <input
          type="checkbox"
          checked={selectedCatIds.has(row.original.id)}
          onClick={(e) => e.stopPropagation()}
          onChange={() => toggleCatSelected(row.original.id)}
          className="rounded border-[var(--line)]"
        />
      ),
    },
    {
      accessorKey: 'icon',
      header: '',
      size: 48,
      cell: ({ row }) => (
        <span className="text-[15px] font-mono text-[var(--ink-muted)]">{row.original.icon || '—'}</span>
      ),
    },
    {
      accessorKey: 'categoryName',
      header: 'Category',
      cell: ({ row }) => (
        <div>
          <div className="font-medium text-[var(--ink)]">{row.original.categoryName}</div>
          {row.original.categoryNameSw && (
            <div className="text-[11px] text-[var(--ink-faint)] mt-0.5">{row.original.categoryNameSw}</div>
          )}
        </div>
      ),
    },
    {
      accessorKey: 'businessTypes',
      header: 'Business Types',
      cell: ({ row }) => (
        <div className="flex flex-wrap gap-1">
          {row.original.businessTypes.map((t) => (
            <span key={t} className="rounded-full bg-[var(--accent-soft)] px-2 py-0.5 text-[11px] font-medium text-[var(--accent)]">
              {t}
            </span>
          ))}
        </div>
      ),
    },
    {
      accessorKey: 'categorySlug',
      header: 'Slug',
      cell: ({ row }) => (
        <span className="font-mono text-[11px] text-[var(--ink-faint)]">{row.original.categorySlug}</span>
      ),
    },
    {
      accessorKey: 'displayOrder',
      header: 'Order',
      size: 64,
      cell: ({ row }) => (
        <span className="font-mono text-[var(--ink-muted)]">{row.original.displayOrder}</span>
      ),
    },
    {
      accessorKey: 'productCount',
      header: 'Products',
      size: 80,
      cell: ({ row }) => (
        <span className="font-mono text-[var(--ink-muted)]">{row.original.productCount}</span>
      ),
    },
    {
      id: 'actions',
      header: '',
      size: 72,
      cell: ({ row }) => (
        <div className="flex gap-1 opacity-0 group-hover:opacity-100 transition-opacity">
          <button
            onClick={(e) => { e.stopPropagation(); setCatForm(categoryToForm(row.original)); setEditCat(row.original) }}
            className="p-1 rounded hover:bg-[var(--canvas)] text-[var(--ink-faint)] hover:text-[var(--ink)]"
          ><Pencil className="h-3.5 w-3.5" /></button>
          <button
            onClick={(e) => { e.stopPropagation(); setDeleteCat(row.original) }}
            className="p-1 rounded hover:bg-[var(--status-bad-bg)] text-[var(--ink-faint)] hover:text-[var(--status-bad)]"
          ><Trash2 className="h-3.5 w-3.5" /></button>
        </div>
      ),
    },
  ]

  const productColumns: ColumnDef<CatalogProduct, unknown>[] = [
    {
      id: 'select',
      header: () => (
        <input
          type="checkbox"
          checked={visibleProds.length > 0 && visibleProds.every((p) => selectedProdIds.has(p.id))}
          onChange={() => setSelectedProdIds((s) =>
            visibleProds.every((p) => s.has(p.id)) ? new Set() : new Set(visibleProds.map((p) => p.id)))}
          className="rounded border-[var(--line)]"
        />
      ),
      size: 36,
      cell: ({ row }) => (
        <input
          type="checkbox"
          checked={selectedProdIds.has(row.original.id)}
          onClick={(e) => e.stopPropagation()}
          onChange={() => toggleProdSelected(row.original.id)}
          className="rounded border-[var(--line)]"
        />
      ),
    },
    {
      accessorKey: 'productName',
      header: 'Product',
      cell: ({ row }) => (
        <div className="flex items-center gap-1.5">
          {isMismatched(row.original) && (
            <span title="Business type doesn't match this product's category">
              <TriangleAlert className="h-3.5 w-3.5 text-[var(--status-warn)] shrink-0" />
            </span>
          )}
          <div>
            <div className="font-medium text-[var(--ink)]">{row.original.productName}</div>
            {row.original.productNameSw && (
              <div className="text-[11px] text-[var(--ink-faint)] mt-0.5">{row.original.productNameSw}</div>
            )}
          </div>
        </div>
      ),
    },
    {
      accessorKey: 'categorySlug',
      header: 'Category',
      cell: ({ row }) => (
        <span className="font-mono text-[11px] text-[var(--ink-muted)]">
          {row.original.categoryName || row.original.categorySlug || '—'}
        </span>
      ),
    },
    {
      accessorKey: 'businessTypes',
      header: 'Business Types',
      cell: ({ row }) => (
        <div className="flex flex-wrap gap-1">
          {row.original.businessTypes.map((t) => (
            <span key={t} className="rounded-full bg-[var(--accent-soft)] px-2 py-0.5 text-[11px] font-medium text-[var(--accent)]">
              {t}
            </span>
          ))}
        </div>
      ),
    },
    {
      accessorKey: 'unit',
      header: 'Unit',
      size: 80,
      cell: ({ row }) => (
        <span className="text-[var(--ink-muted)]">{row.original.unit}</span>
      ),
    },
    {
      id: 'flags',
      header: 'Flags',
      size: 80,
      cell: ({ row }) => (
        <div className="flex gap-1">
          {row.original.prescriptionRequired && (
            <span title="Prescription required"><Pill className="h-3.5 w-3.5 text-[var(--status-warn)]" /></span>
          )}
          {row.original.coldStorage && (
            <span title="Cold storage"><Snowflake className="h-3.5 w-3.5 text-blue-400" /></span>
          )}
        </div>
      ),
    },
    {
      accessorKey: 'tags',
      header: 'Tags',
      cell: ({ row }) => (
        <div className="flex flex-wrap gap-1">
          {row.original.tags.map((t) => (
            <span key={t} className="rounded bg-[var(--line)] px-1.5 py-0.5 text-[10px] text-[var(--ink-muted)]">{t}</span>
          ))}
        </div>
      ),
    },
    {
      id: 'actions',
      header: '',
      size: 72,
      cell: ({ row }) => (
        <div className="flex gap-1 opacity-0 group-hover:opacity-100 transition-opacity">
          <button
            onClick={(e) => { e.stopPropagation(); setProductForm(productToForm(row.original)); setEditProduct(row.original) }}
            className="p-1 rounded hover:bg-[var(--canvas)] text-[var(--ink-faint)] hover:text-[var(--ink)]"
          ><Pencil className="h-3.5 w-3.5" /></button>
          <button
            onClick={(e) => { e.stopPropagation(); setDeleteProduct(row.original) }}
            className="p-1 rounded hover:bg-[var(--status-bad-bg)] text-[var(--ink-faint)] hover:text-[var(--status-bad)]"
          ><Trash2 className="h-3.5 w-3.5" /></button>
        </div>
      ),
    },
  ]

  // ── Render ────────────────────────────────────────────────────────────────────

  return (
    <div>
      <PageHeader title="Master Catalog" description="Global product & category catalog seeded into the mobile app">
        {activeTab === 'categories' ? (
          <button
            onClick={() => { setCatForm(EMPTY_CATEGORY); setFormError(''); setShowAddCat(true) }}
            style={{ backgroundColor: '#FFC107', color: '#0D1B3E' }}
            className="inline-flex items-center gap-1.5 rounded-md px-3 py-1.5 text-[12px] font-medium hover:opacity-90 transition-opacity"
          >
            <Plus className="h-3.5 w-3.5" /> Add Category
          </button>
        ) : (
          <button
            onClick={() => { setProductForm(EMPTY_PRODUCT); setFormError(''); setShowAddProduct(true) }}
            style={{ backgroundColor: '#FFC107', color: '#0D1B3E' }}
            className="inline-flex items-center gap-1.5 rounded-md px-3 py-1.5 text-[12px] font-medium hover:opacity-90 transition-opacity"
          >
            <Plus className="h-3.5 w-3.5" /> Add Product
          </button>
        )}
      </PageHeader>

      {revalidating && <RevalidatingBar />}

      {/* Filter bar */}
      <div className="mb-5 flex items-center gap-3 flex-wrap">
        <div className="flex gap-0.5 border-b border-[var(--line)] flex-1">
          {([
            ['categories', Tag, visibleCats.length] as const,
            ['products', Package, visibleProds.length] as const,
          ]).map(([id, Icon, count]) => (
            <button
              key={id}
              onClick={() => setActiveTab(id)}
              className={`flex items-center gap-1.5 px-4 py-2.5 text-[13px] font-medium border-b-2 transition-colors -mb-px capitalize ${
                activeTab === id
                  ? 'border-[var(--accent)] text-[var(--accent)]'
                  : 'border-transparent text-[var(--ink-muted)] hover:text-[var(--ink)]'
              }`}
            >
              <Icon className="h-3.5 w-3.5" />
              {id}
              <span className="ml-1 rounded-full bg-[var(--line)] px-1.5 py-0.5 text-[10px] font-medium text-[var(--ink-faint)]">
                {count}
              </span>
            </button>
          ))}
        </div>

        {activeTab === 'products' && (
          <button
            onClick={() => setShowMismatchesOnly((v) => !v)}
            className={`inline-flex items-center gap-1.5 rounded-md border px-3 py-1.5 text-[12px] font-medium transition-colors shrink-0 ${
              showMismatchesOnly
                ? 'border-[var(--status-warn)] bg-[var(--status-warn-bg)] text-[var(--status-warn)]'
                : 'border-[var(--line)] bg-[var(--surface)] text-[var(--ink-muted)] hover:text-[var(--ink)]'
            }`}
          >
            <TriangleAlert className="h-3.5 w-3.5" />
            Mismatches only
            <span className="rounded-full bg-[var(--line)] px-1.5 py-0.5 text-[10px] font-medium text-[var(--ink-faint)]">
              {mismatchedCount}
            </span>
          </button>
        )}

        <div className="shrink-0">
          <select
            value={selectedType}
            onChange={(e) => setSelectedType(e.target.value)}
            className="rounded-md border border-[var(--line)] bg-[var(--surface)] px-3 py-1.5 text-[12px] text-[var(--ink)] focus:outline-none focus:ring-1 focus:ring-[var(--accent)] appearance-none"
          >
            <option value="">All business types</option>
            {allTypes.map((t) => <option key={t} value={t}>{t}</option>)}
          </select>
        </div>
      </div>

      {loading && <SkeletonTable rows={8} cols={5} />}

      {error && (
        <div className="mt-4 flex items-center gap-3 rounded-lg border border-[var(--status-bad)] bg-[var(--status-bad-bg)] p-4 text-[var(--status-bad)]">
          <AlertCircle className="h-4 w-4 shrink-0" />
          <span className="text-[13px]">{error}</span>
        </div>
      )}

      {!loading && (
        <>
          {activeTab === 'categories' && (
            <DataTable
              data={visibleCats}
              columns={categoryColumns}
              searchPlaceholder="Search categories…"
              searchColumn="categoryName"
              pageSize={25}
              exportFilename="master-categories"
              toolbar={selectedCatIds.size > 0 && (
                <button
                  onClick={() => openBulkDrawer('category')}
                  className="inline-flex items-center gap-1.5 rounded-md border border-[var(--accent)] bg-[var(--accent-soft)] px-3 py-1.5 text-[12px] font-medium text-[var(--accent)] hover:opacity-90 transition-opacity"
                >
                  <ListChecks className="h-3.5 w-3.5" />
                  Bulk edit business types ({selectedCatIds.size})
                </button>
              )}
            />
          )}
          {activeTab === 'products' && (
            <DataTable
              data={visibleProds}
              columns={productColumns}
              searchPlaceholder="Search products…"
              searchColumn="productName"
              pageSize={25}
              exportFilename="master-products"
              toolbar={selectedProdIds.size > 0 && (
                <button
                  onClick={() => openBulkDrawer('product')}
                  className="inline-flex items-center gap-1.5 rounded-md border border-[var(--accent)] bg-[var(--accent-soft)] px-3 py-1.5 text-[12px] font-medium text-[var(--accent)] hover:opacity-90 transition-opacity"
                >
                  <ListChecks className="h-3.5 w-3.5" />
                  Bulk edit business types ({selectedProdIds.size})
                </button>
              )}
            />
          )}
        </>
      )}

      {/* ── Add Category Drawer ────────────────────────────────────────────── */}
      <DetailDrawer
        open={showAddCat}
        onClose={() => { setShowAddCat(false); setCatForm(EMPTY_CATEGORY) }}
        title="Add Category"
        description="Add a category to the master catalog"
      >
        <CategoryForm
          form={catForm}
          setForm={setCatForm}
          allTypes={allTypes}
          saving={saving}
          formError={formError}
          onSubmit={handleAddCat}
          onCancel={() => { setShowAddCat(false); setCatForm(EMPTY_CATEGORY) }}
          submitLabel="Add Category"
        />
      </DetailDrawer>

      {/* ── Edit Category Drawer ───────────────────────────────────────────── */}
      <DetailDrawer
        open={!!editCat}
        onClose={() => { setEditCat(null); setCatForm(EMPTY_CATEGORY) }}
        title="Edit Category"
        description={editCat?.categoryName ?? ''}
      >
        <CategoryForm
          form={catForm}
          setForm={setCatForm}
          allTypes={allTypes}
          saving={saving}
          formError={formError}
          onSubmit={handleEditCat}
          onCancel={() => { setEditCat(null); setCatForm(EMPTY_CATEGORY) }}
          submitLabel="Save Changes"
        />
      </DetailDrawer>

      {/* ── Add Product Drawer ─────────────────────────────────────────────── */}
      <DetailDrawer
        open={showAddProduct}
        onClose={() => { setShowAddProduct(false); setProductForm(EMPTY_PRODUCT) }}
        title="Add Product"
        description="Add a product to the master catalog"
        width="w-[560px]"
      >
        <ProductForm
          form={productForm}
          setForm={setProductForm}
          allTypes={allTypes}
          formCats={formCats}
          saving={saving}
          formError={formError}
          onSubmit={handleAddProduct}
          onCancel={() => { setShowAddProduct(false); setProductForm(EMPTY_PRODUCT) }}
          submitLabel="Add Product"
          toggleTag={toggleTag}
        />
      </DetailDrawer>

      {/* ── Edit Product Drawer ────────────────────────────────────────────── */}
      <DetailDrawer
        open={!!editProduct}
        onClose={() => { setEditProduct(null); setProductForm(EMPTY_PRODUCT) }}
        title="Edit Product"
        description={editProduct?.productName ?? ''}
        width="w-[560px]"
      >
        <ProductForm
          form={productForm}
          setForm={setProductForm}
          allTypes={allTypes}
          formCats={formCats}
          saving={saving}
          formError={formError}
          onSubmit={handleEditProduct}
          onCancel={() => { setEditProduct(null); setProductForm(EMPTY_PRODUCT) }}
          submitLabel="Save Changes"
          toggleTag={toggleTag}
        />
      </DetailDrawer>

      {/* ── Bulk Reassign Drawer ───────────────────────────────────────────── */}
      <DetailDrawer
        open={!!bulkEntity}
        onClose={() => setBulkEntity(null)}
        title="Bulk Edit Business Types"
        description={`${(bulkEntity === 'category' ? selectedCatIds : selectedProdIds).size} ${bulkEntity ?? ''}${(bulkEntity === 'category' ? selectedCatIds : selectedProdIds).size === 1 ? '' : 's'} selected`}
      >
        <div className="flex flex-col gap-5">
          {bulkError && (
            <div className="flex items-center gap-2 rounded-md border border-[var(--status-bad)] bg-[var(--status-bad-bg)] p-3 text-[12px] text-[var(--status-bad)]">
              <AlertCircle className="h-3.5 w-3.5 shrink-0" /> {bulkError}
            </div>
          )}

          <div>
            <div className={sectionHeading}>Action</div>
            <div className="flex gap-2">
              {([
                ['add', 'Add'],
                ['remove', 'Remove'],
                ['replace', 'Replace all with'],
              ] as const).map(([m, label]) => (
                <button
                  key={m}
                  type="button"
                  onClick={() => setBulkMode(m)}
                  className={`flex-1 rounded-md border px-3 py-2 text-[12px] font-medium transition-colors ${
                    bulkMode === m
                      ? 'border-[var(--accent)] bg-[var(--accent-soft)] text-[var(--accent)]'
                      : 'border-[var(--line)] text-[var(--ink-muted)] hover:text-[var(--ink)]'
                  }`}
                >
                  {label}
                </button>
              ))}
            </div>
          </div>

          <div>
            <div className={sectionHeading}>Business Types</div>
            <BusinessTypeToggles selected={bulkTypes} options={allTypes} onToggle={toggleBulkType} />
          </div>

          <div className="flex gap-2 justify-end border-t border-[var(--line)] pt-4">
            <button type="button" onClick={() => setBulkEntity(null)}
              className="rounded-md border border-[var(--line)] px-4 py-2 text-[12px] font-medium text-[var(--ink-muted)] hover:text-[var(--ink)]">
              Cancel
            </button>
            <button
              type="button"
              onClick={handleBulkApply}
              disabled={bulkSaving || bulkTypes.length === 0}
              style={{ backgroundColor: '#0D1B3E' }}
              className="rounded-md px-4 py-2 text-[12px] font-medium text-white hover:opacity-90 transition-opacity disabled:opacity-50"
            >
              {bulkSaving ? 'Applying…' : 'Apply'}
            </button>
          </div>
        </div>
      </DetailDrawer>

      {/* Delete confirmations */}
      <ConfirmDialog
        open={!!deleteCat}
        onClose={() => setDeleteCat(null)}
        onConfirm={handleDeleteCat}
        title="Delete category"
        description={`Remove "${deleteCat?.categoryName}" from the master catalog? Products using this category slug will keep their slug value but lose the category link.`}
        confirmLabel="Delete"
        destructive
      />
      <ConfirmDialog
        open={!!deleteProduct}
        onClose={() => setDeleteProduct(null)}
        onConfirm={handleDeleteProduct}
        title="Delete product"
        description={`Remove "${deleteProduct?.productName}" from the master catalog? This cannot be undone.`}
        confirmLabel="Delete"
        destructive
      />
    </div>
  )
}

// ─── Category form component ─────────────────────────────────────────────────

function CategoryForm({
  form, setForm, allTypes, saving, formError, onSubmit, onCancel, submitLabel,
}: {
  form: CategoryForm
  setForm: React.Dispatch<React.SetStateAction<CategoryForm>>
  allTypes: string[]
  saving: boolean
  formError: string
  onSubmit: (e: React.FormEvent) => void
  onCancel: () => void
  submitLabel: string
}) {
  return (
    <form onSubmit={onSubmit} className="flex flex-col gap-5">
      {formError && (
        <div className="flex items-center gap-2 rounded-md border border-[var(--status-bad)] bg-[var(--status-bad-bg)] p-3 text-[12px] text-[var(--status-bad)]">
          <AlertCircle className="h-3.5 w-3.5 shrink-0" /> {formError}
        </div>
      )}

      <div>
        <div className={sectionHeading}>Names</div>
        <div className="flex flex-col gap-3">
          <div className="flex flex-col gap-1.5">
            <label className={labelCls}>Category Name (English) <span className="text-[var(--status-bad)]">*</span></label>
            <input required value={form.categoryName}
              onChange={(e) => setForm((f) => ({ ...f, categoryName: e.target.value }))}
              placeholder="e.g. Painkillers & Antipyretics" className={inputCls} />
          </div>
          <div className="flex flex-col gap-1.5">
            <label className={labelCls}>Category Name (Kiswahili)</label>
            <input value={form.categoryNameSw}
              onChange={(e) => setForm((f) => ({ ...f, categoryNameSw: e.target.value }))}
              placeholder="e.g. Dawa za Maumivu na Homa" className={inputCls} />
          </div>
        </div>
      </div>

      <div>
        <div className={sectionHeading}>Classification</div>
        <div className="flex flex-col gap-3">
          <div className="flex flex-col gap-1.5">
            <label className={labelCls}>Business Types <span className="text-[var(--status-bad)]">*</span></label>
            <BusinessTypeToggles
              selected={form.businessTypes}
              options={allTypes}
              onToggle={(t) => setForm((f) => ({
                ...f,
                businessTypes: f.businessTypes.includes(t)
                  ? f.businessTypes.filter((x) => x !== t)
                  : [...f.businessTypes, t],
              }))}
            />
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div className="flex flex-col gap-1.5">
              <label className={labelCls}>Icon (Material symbol)</label>
              <select value={form.icon}
                onChange={(e) => setForm((f) => ({ ...f, icon: e.target.value }))}
                className={selectCls}>
                {ICONS.map((ic) => <option key={ic} value={ic}>{ic}</option>)}
              </select>
              <p className="text-[11px] text-[var(--ink-faint)] font-mono">{form.icon}</p>
            </div>
            <div className="flex flex-col gap-1.5">
              <label className={labelCls}>Display Order</label>
              <input type="number" min="0" value={form.displayOrder}
                onChange={(e) => setForm((f) => ({ ...f, displayOrder: Number(e.target.value) }))}
                className={inputCls} />
              <p className="text-[11px] text-[var(--ink-faint)]">Lower = shown first</p>
            </div>
          </div>
        </div>
      </div>

      <div className="flex gap-2 justify-end border-t border-[var(--line)] pt-4">
        <button type="button" onClick={onCancel}
          className="rounded-md border border-[var(--line)] px-4 py-2 text-[12px] font-medium text-[var(--ink-muted)] hover:text-[var(--ink)]">
          Cancel
        </button>
        <button type="submit" disabled={saving}
          style={{ backgroundColor: '#0D1B3E' }}
          className="rounded-md px-4 py-2 text-[12px] font-medium text-white hover:opacity-90 transition-opacity disabled:opacity-50">
          {saving ? 'Saving…' : submitLabel}
        </button>
      </div>
    </form>
  )
}

// ─── Product form component ──────────────────────────────────────────────────

function ProductForm({
  form, setForm, allTypes, formCats, saving, formError,
  onSubmit, onCancel, submitLabel, toggleTag,
}: {
  form: ProductForm
  setForm: React.Dispatch<React.SetStateAction<ProductForm>>
  allTypes: string[]
  formCats: CatalogCategory[]
  saving: boolean
  formError: string
  onSubmit: (e: React.FormEvent) => void
  onCancel: () => void
  submitLabel: string
  toggleTag: (tag: string) => void
}) {
  return (
    <form onSubmit={onSubmit} className="flex flex-col gap-5">
      {formError && (
        <div className="flex items-center gap-2 rounded-md border border-[var(--status-bad)] bg-[var(--status-bad-bg)] p-3 text-[12px] text-[var(--status-bad)]">
          <AlertCircle className="h-3.5 w-3.5 shrink-0" /> {formError}
        </div>
      )}

      {/* Names */}
      <div>
        <div className={sectionHeading}>Names</div>
        <div className="flex flex-col gap-3">
          <div className="flex flex-col gap-1.5">
            <label className={labelCls}>Product Name (English) <span className="text-[var(--status-bad)]">*</span></label>
            <input required value={form.productName}
              onChange={(e) => setForm((f) => ({ ...f, productName: e.target.value }))}
              placeholder="e.g. Paracetamol 500mg, Coca-Cola 500ml" className={inputCls} />
          </div>
          <div className="flex flex-col gap-1.5">
            <label className={labelCls}>Product Name (Kiswahili)</label>
            <input value={form.productNameSw}
              onChange={(e) => setForm((f) => ({ ...f, productNameSw: e.target.value }))}
              placeholder="e.g. Paracetamol 500mg, Koka-Kola 500ml" className={inputCls} />
          </div>
          <div className="flex flex-col gap-1.5">
            <label className={labelCls}>Generic / Scientific Name</label>
            <input value={form.genericName}
              onChange={(e) => setForm((f) => ({ ...f, genericName: e.target.value }))}
              placeholder="e.g. Acetaminophen, Sodium Chloride" className={inputCls} />
          </div>
        </div>
      </div>

      {/* Classification */}
      <div>
        <div className={sectionHeading}>Classification</div>
        <div className="flex flex-col gap-3">
          <div className="flex flex-col gap-1.5">
            <label className={labelCls}>Business Types <span className="text-[var(--status-bad)]">*</span></label>
            <BusinessTypeToggles
              selected={form.businessTypes}
              options={allTypes}
              onToggle={(t) => setForm((f) => ({
                ...f,
                businessTypes: f.businessTypes.includes(t)
                  ? f.businessTypes.filter((x) => x !== t)
                  : [...f.businessTypes, t],
              }))}
            />
          </div>
          <div className="flex flex-col gap-1.5">
            <label className={labelCls}>Category</label>
            {formCats.length > 0 ? (
              <select value={form.categorySlug}
                onChange={(e) => setForm((f) => ({ ...f, categorySlug: e.target.value }))}
                className={selectCls}>
                <option value="">No category</option>
                {formCats.map((c) => (
                  <option key={c.categorySlug} value={c.categorySlug}>
                    {c.categoryName}
                  </option>
                ))}
              </select>
            ) : (
              <input value={form.categorySlug}
                onChange={(e) => setForm((f) => ({ ...f, categorySlug: e.target.value }))}
                placeholder={form.businessTypes.length > 0 ? 'Category slug' : 'Select type(s) first'}
                disabled={form.businessTypes.length === 0} className={inputCls} />
            )}
          </div>
        </div>
      </div>

      {/* Units */}
      <div>
        <div className={sectionHeading}>Units</div>
        <div className="grid grid-cols-2 gap-3">
          <div className="flex flex-col gap-1.5">
            <label className={labelCls}>Primary Unit <span className="text-[var(--status-bad)]">*</span></label>
            <select required value={form.unit}
              onChange={(e) => setForm((f) => ({ ...f, unit: e.target.value }))}
              className={selectCls}>
              {UNITS.map((u) => <option key={u} value={u}>{u}</option>)}
            </select>
          </div>
          <div className="flex flex-col gap-1.5">
            <label className={labelCls}>Alternative Units</label>
            <input value={form.unitAlternatives}
              onChange={(e) => setForm((f) => ({ ...f, unitAlternatives: e.target.value }))}
              placeholder="Box, Carton — comma separated" className={inputCls} />
          </div>
        </div>
      </div>

      {/* Identifiers */}
      <div>
        <div className={sectionHeading}>Identifiers</div>
        <div className="flex flex-col gap-3">
          <div className="flex flex-col gap-1.5">
            <label className={labelCls}>Brand Names</label>
            <input value={form.brandNames}
              onChange={(e) => setForm((f) => ({ ...f, brandNames: e.target.value }))}
              placeholder="e.g. Panadol, Calpol — comma separated" className={inputCls} />
          </div>
          <div className="flex flex-col gap-1.5">
            <label className={labelCls}>Common Barcodes</label>
            <input value={form.commonBarcodes}
              onChange={(e) => setForm((f) => ({ ...f, commonBarcodes: e.target.value }))}
              placeholder="e.g. 5010119013458 — comma separated" className={inputCls} />
          </div>
          <div className="flex flex-col gap-1.5">
            <label className={labelCls}>Search Keywords</label>
            <input value={form.searchKeywords}
              onChange={(e) => setForm((f) => ({ ...f, searchKeywords: e.target.value }))}
              placeholder="Mix English and Swahili, comma separated" className={inputCls} />
            <p className="text-[11px] text-[var(--ink-faint)]">Min 5 recommended for good search coverage.</p>
          </div>
        </div>
      </div>

      {/* Flags */}
      <div>
        <div className={sectionHeading}>Special Flags</div>
        <div className="flex flex-col gap-2">
          <label className={checkboxRowCls}>
            <input type="checkbox" checked={form.prescriptionRequired}
              onChange={(e) => setForm((f) => ({ ...f, prescriptionRequired: e.target.checked }))}
              className="rounded border-[var(--line)]" />
            <Pill className="h-3.5 w-3.5 text-[var(--status-warn)] shrink-0" />
            <div>
              <div className="text-[13px] font-medium text-[var(--ink)]">Prescription Required</div>
              <div className="text-[11px] text-[var(--ink-faint)]">Antibiotics, controlled drugs, Schedule III/IV</div>
            </div>
          </label>
          <label className={checkboxRowCls}>
            <input type="checkbox" checked={form.coldStorage}
              onChange={(e) => setForm((f) => ({ ...f, coldStorage: e.target.checked }))}
              className="rounded border-[var(--line)]" />
            <Snowflake className="h-3.5 w-3.5 text-blue-400 shrink-0" />
            <div>
              <div className="text-[13px] font-medium text-[var(--ink)]">Cold Storage Required</div>
              <div className="text-[11px] text-[var(--ink-faint)]">Insulin, vaccines, fresh dairy/meat/fish</div>
            </div>
          </label>
        </div>
      </div>

      {/* Tags */}
      <div>
        <div className={sectionHeading}>Tags</div>
        <div className="flex flex-wrap gap-2">
          {TAGS.map((tag) => (
            <button key={tag} type="button" onClick={() => toggleTag(tag)}
              className={`rounded-full px-3 py-1 text-[12px] font-medium transition-colors border ${
                form.tags.includes(tag)
                  ? 'bg-[var(--accent)] border-[var(--accent)] text-white'
                  : 'border-[var(--line)] text-[var(--ink-muted)] hover:text-[var(--ink)]'
              }`}>
              {tag}
            </button>
          ))}
        </div>
        <p className="mt-1.5 text-[11px] text-[var(--ink-faint)]">
          <strong>common</strong> = top 20% sellers · <strong>fmcg</strong> = fast-moving consumer goods
        </p>
      </div>

      <div className="flex gap-2 justify-end border-t border-[var(--line)] pt-4">
        <button type="button" onClick={onCancel}
          className="rounded-md border border-[var(--line)] px-4 py-2 text-[12px] font-medium text-[var(--ink-muted)] hover:text-[var(--ink)]">
          Cancel
        </button>
        <button type="submit" disabled={saving}
          style={{ backgroundColor: '#0D1B3E' }}
          className="rounded-md px-4 py-2 text-[12px] font-medium text-white hover:opacity-90 transition-opacity disabled:opacity-50">
          {saving ? 'Saving…' : submitLabel}
        </button>
      </div>
    </form>
  )
}
