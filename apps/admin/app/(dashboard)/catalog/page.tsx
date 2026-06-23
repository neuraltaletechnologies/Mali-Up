'use client'

import { useState, useCallback } from 'react'
import { PageHeader } from '@/components/ui/page-header'
import { DataTable } from '@/components/ui/data-table'
import { DetailDrawer } from '@/components/ui/detail-drawer'
import { ConfirmDialog } from '@/components/ui/confirm-dialog'
import { Skeleton } from '@/components/ui/skeleton'
import {
  fetchCatalog,
  postCatalogProduct, patchCatalogProduct, deleteCatalogProduct,
  postCatalogCategory, patchCatalogCategory, deleteCatalogCategory,
} from '@/lib/admin-api'
import { useAdminFetch } from '@/hooks/use-admin-fetch'
import type { CatalogProduct, CatalogCategory } from '@/types'
import type { ColumnDef } from '@tanstack/react-table'
import { Plus, Pencil, Trash2, AlertCircle, Tag, Package } from 'lucide-react'
import { formatTZS } from '@/lib/format'

// ─── Constants ────────────────────────────────────────────────────────────────

const UNITS = ['pcs', 'kg', 'g', 'litre', 'ml', 'pack', 'box', 'tablet', 'bottle', 'dozen', 'pair', 'roll', 'bag', 'carton']

const EMPTY_PRODUCT = {
  productName: '',
  businessTypeId: '',
  categoryId: '',
  categoryName: '',
  defaultUnit: 'pcs',
  skuTemplate: '',
  barcode: '',
  suggestedCostPrice: '',
  suggestedSellingPrice: '',
  searchableKeywords: '',
}

const EMPTY_CATEGORY = {
  categoryName: '',
  businessTypeId: '',
  description: '',
  icon: '',
}

type ProductForm  = typeof EMPTY_PRODUCT
type CategoryForm = typeof EMPTY_CATEGORY

// ─── Helpers ─────────────────────────────────────────────────────────────────

function productToForm(p: CatalogProduct): ProductForm {
  return {
    productName:           p.productName,
    businessTypeId:        p.businessTypeId,
    categoryId:            p.categoryId,
    categoryName:          p.categoryName,
    defaultUnit:           p.defaultUnit || 'pcs',
    skuTemplate:           p.skuTemplate ?? '',
    barcode:               p.barcode ?? '',
    suggestedCostPrice:    String(p.suggestedCostPrice ?? ''),
    suggestedSellingPrice: String(p.suggestedSellingPrice ?? ''),
    searchableKeywords:    (p.searchableKeywords ?? []).join(', '),
  }
}

function productFormToPayload(form: ProductForm) {
  return {
    ...form,
    suggestedCostPrice:    Number(form.suggestedCostPrice)    || 0,
    suggestedSellingPrice: Number(form.suggestedSellingPrice) || 0,
    searchableKeywords:    form.searchableKeywords.split(',').map((k) => k.trim()).filter(Boolean),
  }
}

function categoryToForm(c: CatalogCategory): CategoryForm {
  return {
    categoryName:   c.categoryName,
    businessTypeId: c.businessTypeId,
    description:    c.description ?? '',
    icon:           c.icon ?? '',
  }
}

// ─── Shared field styles ──────────────────────────────────────────────────────

const inputCls = 'w-full rounded-md border border-[var(--line)] bg-[var(--canvas)] px-3 py-2 text-[13px] text-[var(--ink)] focus:outline-none focus:ring-1 focus:ring-[var(--accent)]'
const labelCls = 'text-[12px] font-medium text-[var(--ink-muted)]'
const selectCls = `${inputCls} appearance-none`

// ─── Page ─────────────────────────────────────────────────────────────────────

export default function CatalogPage() {
  const [activeTab,       setActiveTab]       = useState<'categories' | 'products'>('categories')
  const [selectedTypeId,  setSelectedTypeId]  = useState('')

  // Product state
  const [showAddProduct,  setShowAddProduct]  = useState(false)
  const [editProduct,     setEditProduct]     = useState<CatalogProduct | null>(null)
  const [deleteProduct,   setDeleteProduct]   = useState<CatalogProduct | null>(null)
  const [productForm,     setProductForm]     = useState<ProductForm>(EMPTY_PRODUCT)

  // Category state
  const [showAddCategory, setShowAddCategory] = useState(false)
  const [editCategory,    setEditCategory]    = useState<CatalogCategory | null>(null)
  const [deleteCategory,  setDeleteCategory]  = useState<CatalogCategory | null>(null)
  const [categoryForm,    setCategoryForm]    = useState<CategoryForm>(EMPTY_CATEGORY)

  const [saving, setSaving] = useState(false)

  const { data, loading, error, refetch } = useAdminFetch(
    useCallback(() => fetchCatalog(selectedTypeId || undefined), [selectedTypeId])
  )

  const businessTypeIds = data?.businessTypeIds ?? []
  const products        = data?.products        ?? []
  const categories      = data?.categories      ?? []

  // Categories visible for selected type filter
  const visibleCategories = selectedTypeId
    ? categories.filter((c) => c.businessTypeId === selectedTypeId)
    : categories

  // Products visible for selected type filter
  const visibleProducts = selectedTypeId
    ? products.filter((p) => p.businessTypeId === selectedTypeId)
    : products

  // Categories for selected business type in product form
  const formCategories = categories.filter(
    (c) => c.businessTypeId === productForm.businessTypeId
  )

  // ── Handlers ────────────────────────────────────────────────────────────────

  async function handleAddProduct(e: React.FormEvent) {
    e.preventDefault()
    setSaving(true)
    try {
      await postCatalogProduct(productFormToPayload(productForm))
      setShowAddProduct(false)
      setProductForm(EMPTY_PRODUCT)
      refetch()
    } finally { setSaving(false) }
  }

  async function handleEditProduct(e: React.FormEvent) {
    e.preventDefault()
    if (!editProduct) return
    setSaving(true)
    try {
      await patchCatalogProduct(editProduct.id, productFormToPayload(productForm))
      setEditProduct(null)
      setProductForm(EMPTY_PRODUCT)
      refetch()
    } finally { setSaving(false) }
  }

  async function handleDeleteProduct() {
    if (!deleteProduct) return
    await deleteCatalogProduct(deleteProduct.id)
    setDeleteProduct(null)
    refetch()
  }

  async function handleAddCategory(e: React.FormEvent) {
    e.preventDefault()
    setSaving(true)
    try {
      await postCatalogCategory(categoryForm)
      setShowAddCategory(false)
      setCategoryForm(EMPTY_CATEGORY)
      refetch()
    } finally { setSaving(false) }
  }

  async function handleEditCategory(e: React.FormEvent) {
    e.preventDefault()
    if (!editCategory) return
    setSaving(true)
    try {
      await patchCatalogCategory(editCategory.id, categoryForm)
      setEditCategory(null)
      setCategoryForm(EMPTY_CATEGORY)
      refetch()
    } finally { setSaving(false) }
  }

  async function handleDeleteCategory() {
    if (!deleteCategory) return
    await deleteCatalogCategory(deleteCategory.id)
    setDeleteCategory(null)
    refetch()
  }

  // ── Column defs ──────────────────────────────────────────────────────────────

  const categoryColumns: ColumnDef<CatalogCategory, unknown>[] = [
    {
      accessorKey: 'icon',
      header: '',
      cell: ({ row }) => (
        <span className="text-[18px]">{row.original.icon || '📦'}</span>
      ),
    },
    {
      accessorKey: 'categoryName',
      header: 'Category',
      cell: ({ row }) => (
        <div>
          <div className="font-medium text-[var(--ink)]">{row.original.categoryName}</div>
          {row.original.description && (
            <div className="text-[11px] text-[var(--ink-faint)] mt-0.5">{row.original.description}</div>
          )}
        </div>
      ),
    },
    {
      accessorKey: 'businessTypeId',
      header: 'Business Type',
      cell: ({ row }) => (
        <span className="rounded-full bg-[var(--accent-soft)] px-2 py-0.5 text-[11px] font-medium text-[var(--accent)] capitalize">
          {row.original.businessTypeId}
        </span>
      ),
    },
    {
      accessorKey: 'productCount',
      header: 'Products',
      cell: ({ row }) => (
        <span className="font-mono text-[var(--ink-muted)]">{row.original.productCount}</span>
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
      cell: ({ row }) => (
        <div className="flex gap-1 opacity-0 group-hover:opacity-100 transition-opacity">
          <button
            onClick={(e) => {
              e.stopPropagation()
              setCategoryForm(categoryToForm(row.original))
              setEditCategory(row.original)
            }}
            className="p-1 rounded hover:bg-[var(--canvas)] text-[var(--ink-faint)] hover:text-[var(--ink)]"
          >
            <Pencil className="h-3.5 w-3.5" />
          </button>
          <button
            onClick={(e) => { e.stopPropagation(); setDeleteCategory(row.original) }}
            className="p-1 rounded hover:bg-[var(--status-bad-bg)] text-[var(--ink-faint)] hover:text-[var(--status-bad)]"
          >
            <Trash2 className="h-3.5 w-3.5" />
          </button>
        </div>
      ),
    },
  ]

  const productColumns: ColumnDef<CatalogProduct, unknown>[] = [
    {
      accessorKey: 'productName',
      header: 'Product',
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
      cell: ({ row }) => (
        <span className="text-[var(--ink-muted)]">{row.original.categoryName || '—'}</span>
      ),
    },
    {
      accessorKey: 'businessTypeId',
      header: 'Business Type',
      cell: ({ row }) => (
        <span className="rounded-full bg-[var(--accent-soft)] px-2 py-0.5 text-[11px] font-medium text-[var(--accent)] capitalize">
          {row.original.businessTypeId}
        </span>
      ),
    },
    {
      accessorKey: 'defaultUnit',
      header: 'Unit',
      cell: ({ row }) => (
        <span className="font-mono text-[var(--ink-muted)]">{row.original.defaultUnit}</span>
      ),
    },
    {
      accessorKey: 'suggestedSellingPrice',
      header: 'Selling Price',
      cell: ({ row }) => (
        <span className="font-mono tabular-nums text-[var(--ink)]">
          {row.original.suggestedSellingPrice > 0
            ? formatTZS(row.original.suggestedSellingPrice)
            : <span className="text-[var(--ink-faint)]">—</span>}
        </span>
      ),
    },
    {
      accessorKey: 'suggestedCostPrice',
      header: 'Cost Price',
      cell: ({ row }) => (
        <span className="font-mono tabular-nums text-[var(--ink-muted)]">
          {row.original.suggestedCostPrice > 0
            ? formatTZS(row.original.suggestedCostPrice)
            : <span className="text-[var(--ink-faint)]">—</span>}
        </span>
      ),
    },
    {
      accessorKey: 'barcode',
      header: 'Barcode',
      cell: ({ row }) => (
        <span className="font-mono text-[11px] text-[var(--ink-faint)]">{row.original.barcode || '—'}</span>
      ),
    },
    {
      id: 'actions',
      header: '',
      cell: ({ row }) => (
        <div className="flex gap-1 opacity-0 group-hover:opacity-100 transition-opacity">
          <button
            onClick={(e) => {
              e.stopPropagation()
              setProductForm(productToForm(row.original))
              setEditProduct(row.original)
            }}
            className="p-1 rounded hover:bg-[var(--canvas)] text-[var(--ink-faint)] hover:text-[var(--ink)]"
          >
            <Pencil className="h-3.5 w-3.5" />
          </button>
          <button
            onClick={(e) => { e.stopPropagation(); setDeleteProduct(row.original) }}
            className="p-1 rounded hover:bg-[var(--status-bad-bg)] text-[var(--ink-faint)] hover:text-[var(--status-bad)]"
          >
            <Trash2 className="h-3.5 w-3.5" />
          </button>
        </div>
      ),
    },
  ]

  // ── Loading / error states ───────────────────────────────────────────────────

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

  // ── Render ───────────────────────────────────────────────────────────────────

  return (
    <div>
      <PageHeader
        title="Master Catalog"
        description={`${categories.length} categories · ${data?.total ?? 0} products`}
      >
        {activeTab === 'categories' ? (
          <button
            onClick={() => { setCategoryForm(EMPTY_CATEGORY); setShowAddCategory(true) }}
            style={{ backgroundColor: '#0D1B3E' }}
            className="inline-flex items-center gap-1.5 rounded-md px-3 py-1.5 text-[12px] font-medium text-white transition-colors hover:opacity-90"
          >
            <Plus className="h-3.5 w-3.5" />
            Add category
          </button>
        ) : (
          <button
            onClick={() => { setProductForm(EMPTY_PRODUCT); setShowAddProduct(true) }}
            style={{ backgroundColor: '#0D1B3E' }}
            className="inline-flex items-center gap-1.5 rounded-md px-3 py-1.5 text-[12px] font-medium text-white transition-colors hover:opacity-90"
          >
            <Plus className="h-3.5 w-3.5" />
            Add product
          </button>
        )}
      </PageHeader>

      {/* Tabs */}
      <div className="flex gap-0.5 mb-5 border-b border-[var(--line)]">
        {([
          { id: 'categories', label: 'Categories', icon: Tag,     count: categories.length },
          { id: 'products',   label: 'Products',   icon: Package,  count: data?.total ?? 0  },
        ] as const).map(({ id, label, icon: Icon, count }) => (
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

      <div className="flex gap-5">
        {/* Business type sidebar */}
        <div className="w-44 shrink-0">
          <div className="text-[11px] uppercase tracking-wide font-medium text-[var(--ink-faint)] mb-2 px-1">
            Business Type
          </div>
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
            </button>
            {businessTypeIds.map((typeId) => (
              <button
                key={typeId}
                onClick={() => setSelectedTypeId(typeId)}
                className={`w-full text-left rounded-md px-3 py-2 text-[12.5px] transition-colors capitalize ${
                  selectedTypeId === typeId
                    ? 'bg-[var(--accent-soft)] text-[var(--accent)] font-medium'
                    : 'text-[var(--ink-muted)] hover:text-[var(--ink)] hover:bg-[var(--canvas)]'
                }`}
              >
                {typeId}
                <span className="ml-1.5 text-[11px] text-[var(--ink-faint)]">
                  ({activeTab === 'categories'
                    ? categories.filter((c) => c.businessTypeId === typeId).length
                    : products.filter((p) => p.businessTypeId === typeId).length
                  })
                </span>
              </button>
            ))}
          </div>
        </div>

        {/* Main content */}
        <div className="flex-1 min-w-0">
          {activeTab === 'categories' ? (
            visibleCategories.length === 0 ? (
              <div className="text-center py-16 text-[var(--ink-faint)] text-[13px]">
                No categories yet.{' '}
                <button
                  onClick={() => { setCategoryForm(EMPTY_CATEGORY); setShowAddCategory(true) }}
                  className="text-[var(--accent)] hover:underline"
                >
                  Add the first one →
                </button>
              </div>
            ) : (
              <DataTable
                data={visibleCategories}
                columns={categoryColumns}
                searchPlaceholder="Search categories…"
                exportFilename="categories"
                emptyState={<p className="text-[var(--ink-faint)] text-[13px]">No categories found</p>}
              />
            )
          ) : (
            visibleProducts.length === 0 ? (
              <div className="text-center py-16 text-[var(--ink-faint)] text-[13px]">
                No products yet.{' '}
                <button
                  onClick={() => { setProductForm(EMPTY_PRODUCT); setShowAddProduct(true) }}
                  className="text-[var(--accent)] hover:underline"
                >
                  Add the first one →
                </button>
              </div>
            ) : (
              <DataTable
                data={visibleProducts}
                columns={productColumns}
                searchPlaceholder="Search products…"
                exportFilename="products"
                emptyState={<p className="text-[var(--ink-faint)] text-[13px]">No products found</p>}
              />
            )
          )}
        </div>
      </div>

      {/* ── Add / Edit Category Drawer ─────────────────────────────────────── */}
      {[
        { open: showAddCategory, title: 'Add Category', desc: 'Create a new product category', onSubmit: handleAddCategory, onClose: () => { setShowAddCategory(false); setCategoryForm(EMPTY_CATEGORY) } },
        { open: !!editCategory,  title: 'Edit Category', desc: editCategory?.categoryName ?? '', onSubmit: handleEditCategory, onClose: () => { setEditCategory(null); setCategoryForm(EMPTY_CATEGORY) } },
      ].map(({ open, title, desc, onSubmit, onClose }) => (
        <DetailDrawer key={title} open={open} onClose={onClose} title={title} description={desc} width="w-[480px]">
          <form onSubmit={onSubmit} className="flex flex-col gap-5">
            {/* Category Name */}
            <div className="flex flex-col gap-1.5">
              <label className={labelCls}>Category Name <span className="text-[var(--status-bad)]">*</span></label>
              <input
                required
                value={categoryForm.categoryName}
                onChange={(e) => setCategoryForm((f) => ({ ...f, categoryName: e.target.value }))}
                placeholder="e.g. Analgesics, Beverages, Electronics"
                className={inputCls}
              />
            </div>

            {/* Business Type */}
            <div className="flex flex-col gap-1.5">
              <label className={labelCls}>Business Type <span className="text-[var(--status-bad)]">*</span></label>
              {businessTypeIds.length > 0 ? (
                <select
                  required
                  value={categoryForm.businessTypeId}
                  onChange={(e) => setCategoryForm((f) => ({ ...f, businessTypeId: e.target.value }))}
                  className={selectCls}
                >
                  <option value="">Select business type…</option>
                  {businessTypeIds.map((t) => (
                    <option key={t} value={t} className="capitalize">{t.charAt(0).toUpperCase() + t.slice(1)}</option>
                  ))}
                  <option value="__new__" disabled>─── or type below ───</option>
                </select>
              ) : (
                <input
                  required
                  value={categoryForm.businessTypeId}
                  onChange={(e) => setCategoryForm((f) => ({ ...f, businessTypeId: e.target.value.toLowerCase() }))}
                  placeholder="e.g. pharmacy, supermarket, restaurant"
                  className={inputCls}
                />
              )}
              {businessTypeIds.length > 0 && (
                <input
                  value={categoryForm.businessTypeId && !businessTypeIds.includes(categoryForm.businessTypeId) ? categoryForm.businessTypeId : ''}
                  onChange={(e) => { if (e.target.value) setCategoryForm((f) => ({ ...f, businessTypeId: e.target.value.toLowerCase() })) }}
                  placeholder="Or type a new business type…"
                  className={`${inputCls} mt-1`}
                />
              )}
            </div>

            {/* Description */}
            <div className="flex flex-col gap-1.5">
              <label className={labelCls}>Description</label>
              <textarea
                value={categoryForm.description}
                onChange={(e) => setCategoryForm((f) => ({ ...f, description: e.target.value }))}
                placeholder="Short description of this category"
                rows={2}
                className={`${inputCls} resize-none`}
              />
            </div>

            {/* Icon */}
            <div className="flex flex-col gap-1.5">
              <label className={labelCls}>Icon (emoji)</label>
              <input
                value={categoryForm.icon}
                onChange={(e) => setCategoryForm((f) => ({ ...f, icon: e.target.value }))}
                placeholder="e.g. 💊 🛒 🍽️"
                className={inputCls}
                maxLength={4}
              />
              <p className="text-[11px] text-[var(--ink-faint)]">Single emoji shown in the category list</p>
            </div>

            <div className="mt-2 flex gap-2 justify-end border-t border-[var(--line)] pt-4">
              <button type="button" onClick={onClose}
                className="rounded-md border border-[var(--line)] px-4 py-2 text-[12px] font-medium text-[var(--ink-muted)] hover:text-[var(--ink)]">
                Cancel
              </button>
              <button type="submit" disabled={saving}
                style={{ backgroundColor: '#0D1B3E' }}
                className="rounded-md px-4 py-2 text-[12px] font-medium text-white hover:opacity-90 transition-opacity disabled:opacity-50">
                {saving ? 'Saving…' : title}
              </button>
            </div>
          </form>
        </DetailDrawer>
      ))}

      {/* ── Add / Edit Product Drawer ──────────────────────────────────────── */}
      {[
        { open: showAddProduct, title: 'Add Product', desc: 'Add a product to the master catalog', onSubmit: handleAddProduct, onClose: () => { setShowAddProduct(false); setProductForm(EMPTY_PRODUCT) } },
        { open: !!editProduct,  title: 'Edit Product', desc: editProduct?.productName ?? '', onSubmit: handleEditProduct, onClose: () => { setEditProduct(null); setProductForm(EMPTY_PRODUCT) } },
      ].map(({ open, title, desc, onSubmit, onClose }) => (
        <DetailDrawer key={title} open={open} onClose={onClose} title={title} description={desc} width="w-[540px]">
          <form onSubmit={onSubmit} className="flex flex-col gap-5">

            {/* Section: Identity */}
            <div>
              <div className="text-[11px] uppercase tracking-wide font-semibold text-[var(--ink-faint)] mb-3">Product details</div>
              <div className="flex flex-col gap-4">
                <div className="flex flex-col gap-1.5">
                  <label className={labelCls}>Product Name <span className="text-[var(--status-bad)]">*</span></label>
                  <input
                    required
                    value={productForm.productName}
                    onChange={(e) => setProductForm((f) => ({ ...f, productName: e.target.value }))}
                    placeholder="e.g. Paracetamol 500mg, Coca-Cola 500ml"
                    className={inputCls}
                  />
                </div>

                <div className="grid grid-cols-2 gap-3">
                  {/* Business Type */}
                  <div className="flex flex-col gap-1.5">
                    <label className={labelCls}>Business Type <span className="text-[var(--status-bad)]">*</span></label>
                    {businessTypeIds.length > 0 ? (
                      <select
                        required
                        value={productForm.businessTypeId}
                        onChange={(e) => setProductForm((f) => ({ ...f, businessTypeId: e.target.value, categoryId: '', categoryName: '' }))}
                        className={selectCls}
                      >
                        <option value="">Select…</option>
                        {businessTypeIds.map((t) => (
                          <option key={t} value={t} className="capitalize">{t.charAt(0).toUpperCase() + t.slice(1)}</option>
                        ))}
                      </select>
                    ) : (
                      <input
                        required
                        value={productForm.businessTypeId}
                        onChange={(e) => setProductForm((f) => ({ ...f, businessTypeId: e.target.value.toLowerCase() }))}
                        placeholder="e.g. pharmacy"
                        className={inputCls}
                      />
                    )}
                  </div>

                  {/* Unit */}
                  <div className="flex flex-col gap-1.5">
                    <label className={labelCls}>Default Unit <span className="text-[var(--status-bad)]">*</span></label>
                    <select
                      required
                      value={productForm.defaultUnit}
                      onChange={(e) => setProductForm((f) => ({ ...f, defaultUnit: e.target.value }))}
                      className={selectCls}
                    >
                      {UNITS.map((u) => <option key={u} value={u}>{u}</option>)}
                    </select>
                  </div>
                </div>

                {/* Category */}
                <div className="flex flex-col gap-1.5">
                  <label className={labelCls}>Category</label>
                  {formCategories.length > 0 ? (
                    <select
                      value={productForm.categoryId}
                      onChange={(e) => {
                        const cat = formCategories.find((c) => c.id === e.target.value)
                        setProductForm((f) => ({
                          ...f,
                          categoryId:   cat?.id   ?? '',
                          categoryName: cat?.categoryName ?? '',
                        }))
                      }}
                      className={selectCls}
                    >
                      <option value="">No category</option>
                      {formCategories.map((c) => (
                        <option key={c.id} value={c.id}>{c.icon ? `${c.icon} ` : ''}{c.categoryName}</option>
                      ))}
                    </select>
                  ) : (
                    <input
                      value={productForm.categoryName}
                      onChange={(e) => setProductForm((f) => ({ ...f, categoryName: e.target.value }))}
                      placeholder={productForm.businessTypeId ? 'No categories yet — type name' : 'Select a business type first'}
                      disabled={!productForm.businessTypeId}
                      className={inputCls}
                    />
                  )}
                  {formCategories.length > 0 && (
                    <p className="text-[11px] text-[var(--ink-faint)]">
                      {formCategories.length} categories for {productForm.businessTypeId} ·
                      <button type="button" onClick={() => { setCategoryForm({ ...EMPTY_CATEGORY, businessTypeId: productForm.businessTypeId }); setShowAddCategory(true) }}
                        className="ml-1 text-[var(--accent)] hover:underline">
                        Add new
                      </button>
                    </p>
                  )}
                </div>
              </div>
            </div>

            {/* Section: Pricing */}
            <div>
              <div className="text-[11px] uppercase tracking-wide font-semibold text-[var(--ink-faint)] mb-3">Pricing (TZS)</div>
              <div className="grid grid-cols-2 gap-3">
                <div className="flex flex-col gap-1.5">
                  <label className={labelCls}>Cost Price</label>
                  <div className="relative">
                    <span className="absolute left-3 top-1/2 -translate-y-1/2 text-[12px] text-[var(--ink-faint)]">TZS</span>
                    <input
                      type="number"
                      min="0"
                      value={productForm.suggestedCostPrice}
                      onChange={(e) => setProductForm((f) => ({ ...f, suggestedCostPrice: e.target.value }))}
                      placeholder="0"
                      className={`${inputCls} pl-10`}
                    />
                  </div>
                </div>
                <div className="flex flex-col gap-1.5">
                  <label className={labelCls}>Selling Price</label>
                  <div className="relative">
                    <span className="absolute left-3 top-1/2 -translate-y-1/2 text-[12px] text-[var(--ink-faint)]">TZS</span>
                    <input
                      type="number"
                      min="0"
                      value={productForm.suggestedSellingPrice}
                      onChange={(e) => setProductForm((f) => ({ ...f, suggestedSellingPrice: e.target.value }))}
                      placeholder="0"
                      className={`${inputCls} pl-10`}
                    />
                  </div>
                </div>
              </div>
            </div>

            {/* Section: Identifiers */}
            <div>
              <div className="text-[11px] uppercase tracking-wide font-semibold text-[var(--ink-faint)] mb-3">Identifiers (optional)</div>
              <div className="flex flex-col gap-3">
                <div className="grid grid-cols-2 gap-3">
                  <div className="flex flex-col gap-1.5">
                    <label className={labelCls}>Barcode</label>
                    <input
                      value={productForm.barcode}
                      onChange={(e) => setProductForm((f) => ({ ...f, barcode: e.target.value }))}
                      placeholder="e.g. 5010119013458"
                      className={inputCls}
                    />
                  </div>
                  <div className="flex flex-col gap-1.5">
                    <label className={labelCls}>SKU Template</label>
                    <input
                      value={productForm.skuTemplate}
                      onChange={(e) => setProductForm((f) => ({ ...f, skuTemplate: e.target.value }))}
                      placeholder="e.g. PARA-500-{n}"
                      className={inputCls}
                    />
                  </div>
                </div>
                <div className="flex flex-col gap-1.5">
                  <label className={labelCls}>Search Keywords</label>
                  <input
                    value={productForm.searchableKeywords}
                    onChange={(e) => setProductForm((f) => ({ ...f, searchableKeywords: e.target.value }))}
                    placeholder="e.g. panadol, pain relief, fever — comma separated"
                    className={inputCls}
                  />
                  <p className="text-[11px] text-[var(--ink-faint)]">Helps mobile app users find this product by alternate names</p>
                </div>
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
                {saving ? 'Saving…' : title}
              </button>
            </div>
          </form>
        </DetailDrawer>
      ))}

      {/* Delete confirmations */}
      <ConfirmDialog
        open={!!deleteCategory}
        onClose={() => setDeleteCategory(null)}
        onConfirm={handleDeleteCategory}
        title="Delete category"
        description={`Remove "${deleteCategory?.categoryName}"? Products assigned to this category will keep their category name but lose the link.`}
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
