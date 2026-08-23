import { NextResponse } from 'next/server'
import { restFirestore as adminFirestore, FieldValue, QueryDocumentSnapshot } from '@/lib/firestore-rest'
import { requireAdminSession } from '@/lib/api-guard'
import { writeAudit } from '@/lib/write-audit'

type Params = { uid: string; businessId: string }

// Chunk size for Firestore 'in' queries (documented max is 30, we stay well under it).
const IN_CHUNK = 10

function chunk<T>(items: T[], size: number): T[][] {
  const out: T[][] = []
  for (let i = 0; i < items.length; i += size) out.push(items.slice(i, i + size))
  return out
}

// Attaches master-catalog products (filtered by category) into a specific
// business's live inventory. Writes directly to `businesses/{businessId}/inventory_items`
// — the same collection the mobile app's RemoteInventoryRepository reads/writes —
// so the item flows down to the device via the normal SyncService pull cycle,
// exactly as if the business owner had imported it themselves via
// ImportProductScreen. New items are seeded with zero stock and no price; the
// business owner fills those in on-device.
export async function POST(
  request: Request,
  { params }: { params: Promise<Params> },
) {
  const denied = await requireAdminSession()
  if (denied) return denied

  const { uid, businessId } = await params

  try {
    const body = (await request.json()) as {
      categorySlug?: string
      categoryName?: string
      productIds?: string[]
    }

    if (!body.categorySlug?.trim() && !(body.productIds && body.productIds.length)) {
      return NextResponse.json(
        { error: 'categorySlug or productIds is required' },
        { status: 400 },
      )
    }

    const bizRef = adminFirestore.collection('businesses').doc(businessId)
    const bizDoc = await bizRef.get()
    if (!bizDoc.exists) {
      return NextResponse.json({ error: 'Business not found' }, { status: 404 })
    }
    const bizName = (bizDoc.data()?.businessName as string) || businessId

    // ── Resolve the master products to import ─────────────────────────────
    let productDocs: QueryDocumentSnapshot[] = []

    if (body.productIds?.length) {
      const snaps = await Promise.all(
        body.productIds.map((id) => adminFirestore.collection('master_products').doc(id).get()),
      )
      productDocs = snaps.filter((s) => s.exists) as QueryDocumentSnapshot[]
    } else {
      const snap = await adminFirestore
        .collection('master_products')
        .where('categorySlug', '==', body.categorySlug)
        .get()
      productDocs = snap.docs
    }

    if (productDocs.length === 0) {
      return NextResponse.json({ imported: 0, skipped: 0, skippedNames: [] })
    }

    // ── Skip products already attached to this business ────────────────────
    const invItemsRef = bizRef.collection('inventory_items')
    const productIds = productDocs.map((d) => d.id)
    const alreadyAttached = new Set<string>()
    for (const group of chunk(productIds, IN_CHUNK)) {
      const existing = await invItemsRef.where('sourceProductId', 'in', group).get()
      existing.docs.forEach((d) => alreadyAttached.add(d.data().sourceProductId as string))
    }

    const toImport = productDocs.filter((d) => !alreadyAttached.has(d.id))
    const skippedNames = productDocs
      .filter((d) => alreadyAttached.has(d.id))
      .map((d) => (d.data().productName as string) || d.id)

    // ── Write new inventory items ────────────────────────────────────────────
    const batch = adminFirestore.batch()
    const nowIso = new Date().toISOString()
    for (const doc of toImport) {
      const p = doc.data()
      const categoryName = body.categoryName?.trim() || (p.categoryName as string) || (p.categorySlug as string) || ''
      const ref = invItemsRef.doc()
      batch.set(ref, {
        name: (p.productName as string) || '',
        description: '',
        category: categoryName,
        categoryId: (p.categorySlug as string) || '',
        categoryName,
        sku: '',
        currentStock: 0,
        stock: 0,
        reorderPoint: 5,
        unitPrice: 0,
        sellingPrice: 0,
        costPrice: 0,
        buyingPrice: 0,
        productType: 'stock',
        unit: (p.unit as string) || 'Piece',
        supplier: '',
        lastRestocked: '',
        createdAt: nowIso,
        updatedAt: FieldValue.serverTimestamp(),
        isActive: true,
        expiryDate: '',
        batchNumber: '',
        warrantyPeriod: '',
        brand: Array.isArray(p.brandNames) && p.brandNames.length ? p.brandNames[0] : '',
        sellingUnits: [],
        returnReason: '',
        bomIngredients: [],
        bomOverheads: [],
        bomBatchYield: 1,
        // Admin-tracking fields only — ignored by the mobile app's InventoryMapper.
        sourceProductId: doc.id,
        sourceCategorySlug: (p.categorySlug as string) || '',
        attachedByAdmin: true,
      })
    }
    if (toImport.length > 0) await batch.commit()

    await writeAudit({
      action: 'attach_catalog_products',
      resourceType: 'business',
      resourceId: businessId,
      resourceName: bizName,
      isDestructive: false,
      after: {
        categorySlug: body.categorySlug ?? null,
        imported: toImport.length,
        skipped: skippedNames.length,
      },
    })

    return NextResponse.json({
      imported: toImport.length,
      skipped: skippedNames.length,
      skippedNames,
    })
  } catch (err) {
    console.error(`[POST /api/admin/businesses/${uid}/${businessId}/catalog-import]`, err)
    return NextResponse.json({ error: 'Failed to attach products' }, { status: 500 })
  }
}
