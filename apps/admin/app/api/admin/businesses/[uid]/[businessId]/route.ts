import { NextResponse } from 'next/server'
import { adminFirestore } from '@/lib/firebase-admin'
import { requireAdminSession } from '@/lib/api-guard'
import { mapBusiness } from '@/lib/firestore-mappers'
import type { AdminNote } from '@/types'

type Params = { uid: string; businessId: string }

export async function GET(
  _request: Request,
  { params }: { params: Promise<Params> },
) {
  const denied = await requireAdminSession()
  if (denied) return denied

  const { uid, businessId } = await params

  try {
    const bizRef = adminFirestore
      .collection('tenants')
      .doc(uid)
      .collection('businesses')
      .doc(businessId)

    const [bizDoc, staffSnap, notesSnap] = await Promise.all([
      bizRef.get(),
      bizRef.collection('team_members').count().get(),
      bizRef.collection('admin_notes').orderBy('createdAt', 'desc').get(),
    ])

    if (!bizDoc.exists) {
      return NextResponse.json({ error: 'Business not found' }, { status: 404 })
    }

    const staffCount = staffSnap.data().count ?? 0
    const business = mapBusiness(
      uid,
      businessId,
      bizDoc.data() as Record<string, unknown>,
      staffCount,
    )

    const notes: AdminNote[] = notesSnap.docs.map((doc) => ({
      id:        doc.id,
      author:    (doc.data().author as string) || 'Admin',
      content:   (doc.data().content as string) || '',
      createdAt: toIso(doc.data().createdAt),
    }))

    // Financial aggregates from invoices and expenses sub-collections
    const [invoiceSnap, expenseSnap] = await Promise.all([
      bizRef.collection('invoices').count().get(),
      bizRef.collection('expenses').count().get(),
    ])

    business.invoiceCount = invoiceSnap.data().count ?? 0
    business.notes = notes

    return NextResponse.json({ business })
  } catch (err) {
    console.error(`[GET /api/admin/businesses/${uid}/${businessId}]`, err)
    return NextResponse.json({ error: 'Failed to fetch business' }, { status: 500 })
  }
}

// ── PATCH — suspend / unsuspend ───────────────────────────────────────────────
export async function PATCH(
  request: Request,
  { params }: { params: Promise<Params> },
) {
  const denied = await requireAdminSession()
  if (denied) return denied

  const { uid, businessId } = await params

  try {
    const body = (await request.json()) as { isActive: boolean }
    if (typeof body.isActive !== 'boolean') {
      return NextResponse.json({ error: 'isActive (boolean) required' }, { status: 400 })
    }

    await adminFirestore
      .collection('tenants')
      .doc(uid)
      .collection('businesses')
      .doc(businessId)
      .update({ isActive: body.isActive, updatedAt: new Date() })

    return NextResponse.json({ success: true })
  } catch (err) {
    console.error(`[PATCH /api/admin/businesses/${uid}/${businessId}]`, err)
    return NextResponse.json({ error: 'Failed to update business' }, { status: 500 })
  }
}

// ── POST — add admin note ─────────────────────────────────────────────────────
export async function POST(
  request: Request,
  { params }: { params: Promise<Params> },
) {
  const denied = await requireAdminSession()
  if (denied) return denied

  const { uid, businessId } = await params

  try {
    const body = (await request.json()) as { content: string; author: string }
    if (!body.content?.trim()) {
      return NextResponse.json({ error: 'content is required' }, { status: 400 })
    }

    const ref = await adminFirestore
      .collection('tenants')
      .doc(uid)
      .collection('businesses')
      .doc(businessId)
      .collection('admin_notes')
      .add({
        content:   body.content.trim(),
        author:    body.author || 'Admin',
        createdAt: new Date(),
      })

    return NextResponse.json({ id: ref.id })
  } catch (err) {
    console.error(`[POST /api/admin/businesses/${uid}/${businessId}]`, err)
    return NextResponse.json({ error: 'Failed to add note' }, { status: 500 })
  }
}

function toIso(value: unknown): string {
  if (!value) return new Date().toISOString()
  if (typeof value === 'string') return value
  if (typeof value === 'object' && value !== null) {
    const s = (value as Record<string, number>)._seconds
      ?? (value as Record<string, number>).seconds
    if (typeof s === 'number') return new Date(s * 1000).toISOString()
  }
  return new Date().toISOString()
}
