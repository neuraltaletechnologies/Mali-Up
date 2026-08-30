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
    const ref = adminFirestore.collection('master_categories').doc(id)
    const doc = await ref.get()
    if (!doc.exists) return NextResponse.json({ error: 'Category not found' }, { status: 404 })

    await ref.update({ ...body, updatedAt: new Date() })
    invalidateCache(CACHE_KEYS.catalog)

    await writeAudit({
      action: 'update_category',
      resourceType: 'catalog',
      resourceId: id,
      resourceName: (body.categoryName as string) || (doc.data()!.categoryName as string) || id,
      isDestructive: false,
    })

    return NextResponse.json({ success: true })
  } catch (err) {
    console.error(`[PATCH /api/admin/catalog/categories/${id}]`, err)
    return NextResponse.json({ error: 'Failed to update category' }, { status: 500 })
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
    const ref = adminFirestore.collection('master_categories').doc(id)
    const doc = await ref.get()
    if (!doc.exists) return NextResponse.json({ error: 'Category not found' }, { status: 404 })

    const name = (doc.data()!.categoryName as string) || id
    await ref.delete()
    invalidateCache(CACHE_KEYS.catalog)

    await writeAudit({
      action: 'delete_category',
      resourceType: 'catalog',
      resourceId: id,
      resourceName: name,
      isDestructive: true,
    })

    return NextResponse.json({ success: true })
  } catch (err) {
    console.error(`[DELETE /api/admin/catalog/categories/${id}]`, err)
    return NextResponse.json({ error: 'Failed to delete category' }, { status: 500 })
  }
}
