import { NextResponse } from 'next/server'
import { restFirestore as adminFirestore, FieldValue } from '@/lib/firestore-rest'
import { requireAdminSession } from '@/lib/api-guard'
import { writeAudit } from '@/lib/write-audit'
import { invalidateCache } from '@/lib/api-cache'
import { CACHE_KEYS } from '@/lib/cache-keys'

type Entity = 'category' | 'product'
type Mode = 'add' | 'remove' | 'replace'

const MAX_BATCH = 500

function chunk<T>(items: T[], size: number): T[][] {
  const out: T[][] = []
  for (let i = 0; i < items.length; i += size) out.push(items.slice(i, i + size))
  return out
}

// Bulk-updates the `businessTypes` array on many master_categories/master_products
// docs in one action — used by the admin Catalog page's multi-select "reassign"
// flow so miscategorised or missing entries can be fixed without editing one at
// a time. add/remove use Firestore's atomic array operators (no read needed);
// replace overwrites the field outright.
export async function POST(request: Request) {
  const denied = await requireAdminSession()
  if (denied) return denied

  try {
    const body = (await request.json()) as {
      entity?: Entity
      ids?: string[]
      mode?: Mode
      businessTypes?: string[]
    }

    const entity = body.entity
    const ids = body.ids ?? []
    const mode = body.mode
    const businessTypes = (body.businessTypes ?? []).filter((t) => typeof t === 'string' && t.trim())

    if (entity !== 'category' && entity !== 'product') {
      return NextResponse.json({ error: "entity must be 'category' or 'product'" }, { status: 400 })
    }
    if (ids.length === 0) {
      return NextResponse.json({ error: 'ids must be a non-empty array' }, { status: 400 })
    }
    if (mode !== 'add' && mode !== 'remove' && mode !== 'replace') {
      return NextResponse.json({ error: "mode must be 'add' | 'remove' | 'replace'" }, { status: 400 })
    }
    if (businessTypes.length === 0) {
      return NextResponse.json({ error: 'businessTypes must be a non-empty array' }, { status: 400 })
    }

    const collection = entity === 'category' ? 'master_categories' : 'master_products'
    const col = adminFirestore.collection(collection)

    for (const group of chunk(ids, MAX_BATCH)) {
      const batch = adminFirestore.batch()
      for (const id of group) {
        const ref = col.doc(id)
        if (mode === 'replace') {
          batch.update(ref, { businessTypes, updatedAt: new Date() })
        } else {
          const op = mode === 'add'
            ? FieldValue.arrayUnion(...businessTypes)
            : FieldValue.arrayRemove(...businessTypes)
          batch.update(ref, { businessTypes: op, updatedAt: new Date() })
        }
      }
      await batch.commit()
    }
    invalidateCache(CACHE_KEYS.catalog)

    await writeAudit({
      action: 'bulk_reassign_catalog_business_types',
      resourceType: 'catalog',
      resourceId: `${entity}:${ids.length}-items`,
      resourceName: `${ids.length} ${entity}${ids.length === 1 ? '' : 's'}`,
      isDestructive: mode === 'remove' || mode === 'replace',
      after: { entity, mode, businessTypes, count: ids.length },
    })

    return NextResponse.json({ success: true, updated: ids.length })
  } catch (err) {
    console.error('[POST /api/admin/catalog/bulk-reassign]', err)
    return NextResponse.json({ error: 'Failed to bulk-reassign business types' }, { status: 500 })
  }
}
