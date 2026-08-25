import { NextResponse } from 'next/server'
import { restFirestore as adminFirestore } from '@/lib/firestore-rest'
import { requireAdminSession } from '@/lib/api-guard'
import { writeAudit } from '@/lib/write-audit'
import { invalidateCache } from '@/lib/api-cache'
import { CACHE_KEYS } from '@/lib/cache-keys'

type Params = { id: string }

export async function PATCH(
  request: Request,
  { params }: { params: Promise<Params> },
) {
  const denied = await requireAdminSession()
  if (denied) return denied

  const { id } = await params

  try {
    const body = (await request.json()) as Record<string, unknown>
    const ref = adminFirestore.collection('master_products').doc(id)
    const doc = await ref.get()
    if (!doc.exists) return NextResponse.json({ error: 'Product not found' }, { status: 404 })

    const before = doc.data()!
    await ref.update({ ...body, updatedAt: new Date() })
    invalidateCache(CACHE_KEYS.catalog)

    await writeAudit({
      action: 'update_catalog_product',
      resourceType: 'catalog',
      resourceId: id,
      resourceName: (before.productName as string) || id,
      isDestructive: false,
      before: { productName: before.productName, categoryName: before.categoryName },
      after:  { productName: body.productName ?? before.productName,
                categoryName: body.categoryName ?? before.categoryName },
    })

    return NextResponse.json({ success: true })
  } catch (err) {
    console.error(`[PATCH /api/admin/catalog/${id}]`, err)
    return NextResponse.json({ error: 'Failed to update product' }, { status: 500 })
  }
}

export async function DELETE(
  _request: Request,
  { params }: { params: Promise<Params> },
) {
  const denied = await requireAdminSession()
  if (denied) return denied

  const { id } = await params

  try {
    const ref = adminFirestore.collection('master_products').doc(id)
    const doc = await ref.get()
    if (!doc.exists) return NextResponse.json({ error: 'Product not found' }, { status: 404 })

    const name = (doc.data()!.productName as string) || id
    await ref.delete()
    invalidateCache(CACHE_KEYS.catalog)

    await writeAudit({
      action: 'delete_product',
      resourceType: 'catalog',
      resourceId: id,
      resourceName: name,
      isDestructive: true,
    })

    return NextResponse.json({ success: true })
  } catch (err) {
    console.error(`[DELETE /api/admin/catalog/${id}]`, err)
    return NextResponse.json({ error: 'Failed to delete product' }, { status: 500 })
  }
}
