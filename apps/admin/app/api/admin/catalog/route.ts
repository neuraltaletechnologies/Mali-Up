import { NextResponse } from 'next/server'
import { restFirestore as adminFirestore } from '@/lib/firestore-rest'
import { requireAdminSession } from '@/lib/api-guard'
import { writeAudit } from '@/lib/write-audit'

function toStr(v: unknown, fallback = ''): string {
  return typeof v === 'string' ? v : fallback
}
function toBool(v: unknown): boolean {
  return v === true
}
function toStrArr(v: unknown): string[] {
  return Array.isArray(v) ? (v as unknown[]).filter((x) => typeof x === 'string') as string[] : []
}
function toNum(v: unknown, fallback = 0): number {
  return typeof v === 'number' ? v : fallback
}
// Reads the new `businessTypes` array, falling back to the legacy singular
// `businessType` string for docs that haven't been migrated yet.
function toBusinessTypes(d: Record<string, unknown>): string[] {
  const arr = toStrArr(d.businessTypes)
  if (arr.length > 0) return arr
  return typeof d.businessType === 'string' && d.businessType ? [d.businessType] : []
}

export async function GET(request: Request) {
  const denied = await requireAdminSession()
  if (denied) return denied

  const { searchParams } = new URL(request.url)
  const businessType = searchParams.get('businessType')

  try {
    const [catSnap, prodSnap] = await Promise.all([
      adminFirestore.collection('master_categories').get(),
      adminFirestore.collection('master_products').limit(2000).get(),
    ])

    // ── Map categories ──────────────────────────────────────────────────────
    let categories = catSnap.docs.map((doc) => {
      const d = doc.data()
      return {
        id:             doc.id,
        businessTypes:  toBusinessTypes(d),
        categoryName:   toStr(d.categoryName),
        categoryNameSw: toStr(d.categoryNameSw),
        categorySlug:   toStr(d.categorySlug ?? doc.id),
        icon:           toStr(d.icon),
        displayOrder:   toNum(d.displayOrder),
        productCount:   0,
      }
    })

    if (businessType) {
      categories = categories.filter((c) => c.businessTypes.includes(businessType))
    }
    categories.sort((a, b) => a.displayOrder - b.displayOrder || a.categoryName.localeCompare(b.categoryName))

    // ── Map products ────────────────────────────────────────────────────────
    let products = prodSnap.docs.map((doc) => {
      const d = doc.data()
      return {
        id:                   doc.id,
        businessTypes:        toBusinessTypes(d),
        categorySlug:         toStr(d.categorySlug ?? d.categoryId),
        productName:          toStr(d.productName),
        productNameSw:        toStr(d.productNameSw),
        productSlug:          toStr(d.productSlug ?? doc.id),
        genericName:          toStr(d.genericName),
        brandNames:           toStrArr(d.brandNames),
        unit:                 toStr(d.unit ?? d.defaultUnit, 'Piece'),
        unitAlternatives:     toStrArr(d.unitAlternatives),
        commonBarcodes:       toStrArr(d.commonBarcodes),
        searchKeywords:       toStrArr(d.searchKeywords ?? d.searchableKeywords),
        prescriptionRequired: toBool(d.prescriptionRequired),
        coldStorage:          toBool(d.coldStorage),
        tags:                 toStrArr(d.tags),
        categoryName:         toStr(d.categoryName),
      }
    })

    if (businessType) {
      products = products.filter((p) => p.businessTypes.includes(businessType))
    }
    products.sort((a, b) => a.productName.localeCompare(b.productName))

    // ── Fill productCount per category slug ─────────────────────────────────
    const countBySlug: Record<string, number> = {}
    for (const p of products) {
      countBySlug[p.categorySlug] = (countBySlug[p.categorySlug] ?? 0) + 1
    }
    for (const cat of categories) {
      cat.productCount = countBySlug[cat.categorySlug] ?? 0
    }

    const allBusinessTypes = [...new Set([
      ...categories.flatMap((c) => c.businessTypes),
      ...products.flatMap((p) => p.businessTypes),
    ])].filter(Boolean).sort()

    return NextResponse.json({
      categories,
      products,
      businessTypes: allBusinessTypes,
      total: products.length,
    })
  } catch (err) {
    console.error('[GET /api/admin/catalog]', err)
    return NextResponse.json({ error: 'Failed to fetch catalog' }, { status: 500 })
  }
}

export async function POST(request: Request) {
  const denied = await requireAdminSession()
  if (denied) return denied

  try {
    const body = (await request.json()) as Record<string, unknown>

    const businessTypes = toStrArr(body.businessTypes)
    if (!body.productName || businessTypes.length === 0 || !body.unit) {
      return NextResponse.json(
        { error: 'productName, businessTypes (at least one), unit are required' },
        { status: 400 },
      )
    }

    const productSlug = toStr(body.productSlug) ||
      (body.productName as string).toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/(^-|-$)/g, '')

    const ref = await adminFirestore.collection('master_products').add({
      businessTypes,
      categorySlug:         toStr(body.categorySlug),
      productName:          toStr(body.productName),
      productNameSw:        toStr(body.productNameSw),
      productSlug,
      genericName:          toStr(body.genericName),
      brandNames:           toStrArr(body.brandNames),
      unit:                 toStr(body.unit, 'Piece'),
      unitAlternatives:     toStrArr(body.unitAlternatives),
      commonBarcodes:       toStrArr(body.commonBarcodes),
      searchKeywords:       toStrArr(body.searchKeywords),
      prescriptionRequired: toBool(body.prescriptionRequired),
      coldStorage:          toBool(body.coldStorage),
      tags:                 toStrArr(body.tags),
      createdAt:            new Date(),
      updatedAt:            new Date(),
    })

    await writeAudit({
      action: 'create_catalog_product',
      resourceType: 'catalog',
      resourceId: ref.id,
      resourceName: body.productName as string,
      isDestructive: false,
    })

    return NextResponse.json({ id: ref.id })
  } catch (err) {
    console.error('[POST /api/admin/catalog]', err)
    return NextResponse.json({ error: 'Failed to add product' }, { status: 500 })
  }
}
