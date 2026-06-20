import { NextResponse } from 'next/server'
import { adminFirestore } from '@/lib/firebase-admin'
import { requireAdminSession } from '@/lib/api-guard'

export async function GET(request: Request) {
  const denied = await requireAdminSession()
  if (denied) return denied

  const { searchParams } = new URL(request.url)
  const businessTypeId = searchParams.get('businessTypeId') // null = all types

  try {
    // ── Categories ──────────────────────────────────────────────────────────
    let catQuery = adminFirestore
      .collection('master_categories')
      .where('isActive', '==', true)
      .orderBy('categoryName')

    if (businessTypeId) {
      catQuery = adminFirestore
        .collection('master_categories')
        .where('isActive', '==', true)
        .where('businessTypeId', '==', businessTypeId)
        .orderBy('categoryName')
    }

    // ── Products ────────────────────────────────────────────────────────────
    let prodQuery = adminFirestore
      .collection('master_products')
      .where('isActive', '==', true)
      .orderBy('productName')
      .limit(500)

    if (businessTypeId) {
      prodQuery = adminFirestore
        .collection('master_products')
        .where('isActive', '==', true)
        .where('businessTypeId', '==', businessTypeId)
        .orderBy('productName')
        .limit(500)
    }

    const [catSnap, prodSnap] = await Promise.all([catQuery.get(), prodQuery.get()])

    // ── Map categories ──────────────────────────────────────────────────────
    const categories = catSnap.docs.map((doc) => {
      const d = doc.data()
      return {
        id: doc.id,
        businessTypeId: (d.businessTypeId as string) ?? '',
        categoryName: (d.categoryName as string) ?? '',
        description: (d.description as string) ?? '',
        icon: (d.icon as string) ?? '',
        source: (d.source as string) ?? 'admin',
        productCount: 0, // filled below
      }
    })

    // ── Map products ────────────────────────────────────────────────────────
    const products = prodSnap.docs.map((doc) => {
      const d = doc.data()
      const kw = Array.isArray(d.searchableKeywords) ? d.searchableKeywords as string[] : []
      return {
        id: doc.id,
        businessTypeId: (d.businessTypeId as string) ?? '',
        categoryId: (d.categoryId as string) ?? '',
        categoryName: (d.categoryName as string) ?? '',
        productName: (d.productName as string) ?? '',
        skuTemplate: (d.skuTemplate as string) ?? '',
        barcode: (d.barcode as string) ?? '',
        defaultUnit: (d.defaultUnit as string) ?? 'pcs',
        suggestedCostPrice: (d.suggestedCostPrice as number) ?? 0,
        suggestedSellingPrice: (d.suggestedSellingPrice as number) ?? 0,
        searchableKeywords: kw,
        source: (d.source as string) ?? 'admin',
      }
    })

    // ── Fill productCount per category ──────────────────────────────────────
    const countByCategoryId: Record<string, number> = {}
    for (const p of products) {
      countByCategoryId[p.categoryId] = (countByCategoryId[p.categoryId] ?? 0) + 1
    }
    for (const cat of categories) {
      cat.productCount = countByCategoryId[cat.id] ?? 0
    }

    // ── Unique business type IDs (for the sidebar filter) ──────────────────
    const allTypeIds = [...new Set([
      ...categories.map((c) => c.businessTypeId),
      ...products.map((p) => p.businessTypeId),
    ])].filter(Boolean).sort()

    return NextResponse.json({
      categories,
      products,
      businessTypeIds: allTypeIds,
      total: products.length,
    })
  } catch (err) {
    console.error('[GET /api/admin/catalog]', err)
    return NextResponse.json({ error: 'Failed to fetch catalog' }, { status: 500 })
  }
}

// ── POST — add product to master catalog ─────────────────────────────────────
export async function POST(request: Request) {
  const denied = await requireAdminSession()
  if (denied) return denied

  try {
    const body = (await request.json()) as Record<string, unknown>
    if (!body.productName || !body.businessTypeId || !body.defaultUnit) {
      return NextResponse.json(
        { error: 'productName, businessTypeId, defaultUnit are required' },
        { status: 400 },
      )
    }

    const ref = await adminFirestore.collection('master_products').add({
      ...body,
      isActive: true,
      source: 'admin',
      searchableKeywords: Array.isArray(body.searchableKeywords) ? body.searchableKeywords : [],
      createdAt: new Date(),
      updatedAt: new Date(),
    })

    return NextResponse.json({ id: ref.id })
  } catch (err) {
    console.error('[POST /api/admin/catalog]', err)
    return NextResponse.json({ error: 'Failed to add product' }, { status: 500 })
  }
}
