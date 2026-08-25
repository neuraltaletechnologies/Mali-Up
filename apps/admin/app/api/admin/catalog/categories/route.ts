import { NextResponse } from 'next/server'
import { restFirestore as adminFirestore } from '@/lib/firestore-rest'
import { requireAdminSession } from '@/lib/api-guard'
import { writeAudit } from '@/lib/write-audit'
import { invalidateCache } from '@/lib/api-cache'
import { CACHE_KEYS } from '@/lib/cache-keys'

function toStr(v: unknown, fallback = ''): string {
  return typeof v === 'string' ? v : fallback
}
function toNum(v: unknown, fallback = 0): number {
  return typeof v === 'number' ? v : (typeof v === 'string' ? Number(v) || fallback : fallback)
}
function toStrArr(v: unknown): string[] {
  return Array.isArray(v) ? (v as unknown[]).filter((x) => typeof x === 'string') as string[] : []
}

export async function POST(request: Request) {
  const denied = await requireAdminSession()
  if (denied) return denied

  try {
    const body = (await request.json()) as Record<string, unknown>

    const businessTypes = toStrArr(body.businessTypes)
    if (!body.categoryName || businessTypes.length === 0) {
      return NextResponse.json(
        { error: 'categoryName and businessTypes (at least one) are required' },
        { status: 400 },
      )
    }

    const categorySlug = toStr(body.categorySlug) ||
      (body.categoryName as string).toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/(^-|-$)/g, '')

    const ref = await adminFirestore.collection('master_categories').add({
      businessTypes,
      categoryName:   toStr(body.categoryName),
      categoryNameSw: toStr(body.categoryNameSw),
      categorySlug,
      icon:           toStr(body.icon),
      displayOrder:   toNum(body.displayOrder),
      createdAt:      new Date(),
      updatedAt:      new Date(),
    })
    invalidateCache(CACHE_KEYS.catalog)

    await writeAudit({
      action: 'create_category',
      resourceType: 'catalog',
      resourceId: ref.id,
      resourceName: body.categoryName as string,
      isDestructive: false,
    })

    return NextResponse.json({ id: ref.id })
  } catch (err) {
    console.error('[POST /api/admin/catalog/categories]', err)
    return NextResponse.json({ error: 'Failed to create category' }, { status: 500 })
  }
}
