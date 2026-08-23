import { NextResponse } from 'next/server'
import { restFirestore as adminFirestore } from '@/lib/firestore-rest'
import { requireAdminSession } from '@/lib/api-guard'
import { writeAudit } from '@/lib/write-audit'

// GET /api/admin/lookups — returns all three lookup documents
export async function GET() {
  const denied = await requireAdminSession()
  if (denied) return denied

  try {
    const [btSnap, citiesSnap, districtsSnap] = await Promise.all([
      adminFirestore.collection('lookups').doc('business_types').get(),
      adminFirestore.collection('lookups').doc('cities').get(),
      adminFirestore.collection('lookups').doc('districts').get(),
    ])

    const businessTypes: { value: string; en: string; sw: string; icon: string }[] =
      btSnap.exists ? (btSnap.data()?.items ?? []) : []

    const cities: { en: string; sw: string }[] =
      citiesSnap.exists ? (citiesSnap.data()?.items ?? []) : []

    const districts: Record<string, string[]> =
      districtsSnap.exists ? (districtsSnap.data()?.items ?? {}) : {}

    return NextResponse.json({ businessTypes, cities, districts })
  } catch (err) {
    console.error('[GET /api/admin/lookups]', err)
    return NextResponse.json({ error: 'Failed to fetch lookups' }, { status: 500 })
  }
}

// PATCH /api/admin/lookups?type=business_types|cities|districts
export async function PATCH(request: Request) {
  const denied = await requireAdminSession()
  if (denied) return denied

  const { searchParams } = new URL(request.url)
  const type = searchParams.get('type')

  if (!['business_types', 'cities', 'districts'].includes(type ?? '')) {
    return NextResponse.json({ error: 'type must be business_types, cities, or districts' }, { status: 400 })
  }

  try {
    const body = await request.json() as { items: unknown }
    await adminFirestore.collection('lookups').doc(type!).set(
      { items: body.items, updatedAt: new Date() },
      { merge: true },
    )

    await writeAudit({
      action: `update_lookup_${type}`,
      resourceType: 'lookup',
      resourceId: type!,
      resourceName: type!.replace('_', ' '),
      isDestructive: false,
    })

    return NextResponse.json({ success: true })
  } catch (err) {
    console.error(`[PATCH /api/admin/lookups?type=${type}]`, err)
    return NextResponse.json({ error: 'Failed to save lookup' }, { status: 500 })
  }
}
