import { NextResponse } from 'next/server'
import { adminFirestore } from '@/lib/firebase-admin'
import { requireAdminSession } from '@/lib/api-guard'
import { mapBusiness } from '@/lib/firestore-mappers'
import { writeAudit } from '@/lib/write-audit'
import type { AdminNote } from '@/types'

type Params = { uid: string; businessId: string }

// Mobile app stores businesses in the top-level `businesses/{businessId}` collection.
// The `uid` URL segment is the ownerUid for navigation context only.

export async function GET(
  _request: Request,
  { params }: { params: Promise<Params> },
) {
  const denied = await requireAdminSession()
  if (denied) return denied

  const { uid, businessId } = await params

  try {
    const bizRef = adminFirestore.collection('businesses').doc(businessId)

    const [bizDoc, staffSnap, notesSnap, invoiceSnap, customerSnap] = await Promise.all([
      bizRef.get(),
      bizRef.collection('staff').get(),
      bizRef.collection('admin_notes').orderBy('createdAt', 'desc').get(),
      bizRef.collection('invoices').count().get(),
      bizRef.collection('customers').count().get(),
    ])

    if (!bizDoc.exists) {
      return NextResponse.json({ error: 'Business not found' }, { status: 404 })
    }

    const raw = bizDoc.data() as Record<string, unknown>
    const staffMembers = staffSnap.docs.map((doc) => ({
      id:          doc.id,
      name:        (doc.data().name as string) || (doc.data().displayName as string) || 'Unknown',
      phone:       (doc.data().phone as string) || '',
      role:        (doc.data().role as string) || (doc.data().permissions as string) || 'staff',
      status:      (doc.data().status as string) || 'active',
      invitedAt:   toIso(doc.data().invitedAt),
    }))

    const staffCount = staffMembers.length
    const business = mapBusiness(uid || (raw.ownerUid as string) || '', businessId, raw, staffCount)

    const notes: AdminNote[] = notesSnap.docs.map((doc) => ({
      id:        doc.id,
      author:    (doc.data().author as string) || 'Admin',
      content:   (doc.data().content as string) || '',
      createdAt: toIso(doc.data().createdAt),
    }))

    business.invoiceCount = invoiceSnap.data().count ?? 0
    business.customerCount = customerSnap.data().count ?? 0
    business.notes = notes
    business.staffMembers = staffMembers

    if (typeof raw.totalRevenue      === 'number') business.totalRevenue = raw.totalRevenue
    if (typeof raw.outstandingBalance === 'number') business.receivables = raw.outstandingBalance
    else if (typeof raw.receivables  === 'number') business.receivables = raw.receivables
    if (typeof raw.totalExpenses     === 'number') business.expenseTotal = raw.totalExpenses

    return NextResponse.json({ business })
  } catch (err) {
    console.error(`[GET /api/admin/businesses/${uid}/${businessId}]`, err)
    return NextResponse.json({ error: 'Failed to fetch business' }, { status: 500 })
  }
}

// ── PUT — edit business fields ────────────────────────────────────────────────
export async function PUT(
  request: Request,
  { params }: { params: Promise<Params> },
) {
  const denied = await requireAdminSession()
  if (denied) return denied

  const { uid, businessId } = await params

  try {
    const body = (await request.json()) as {
      businessName?: string
      businessCategory?: string
      placeOfBusiness?: string
    }

    const updates: Record<string, unknown> = { updatedAt: new Date() }

    if (body.businessName?.trim())     updates.businessName     = body.businessName.trim()
    if (body.businessCategory?.trim()) {
      updates.businessCategory = body.businessCategory.trim()
      updates.businessType     = body.businessCategory.trim()
    }
    if (body.placeOfBusiness?.trim()) {
      updates.placeOfBusiness = body.placeOfBusiness.trim()
      updates.city            = body.placeOfBusiness.trim()
    }
    // Plan changes go through POST /api/admin/plans/assign — it dual-writes
    // businesses/{id}.plan and users/{ownerUid}.plan (the field the mobile
    // app's PlanService actually gates on) and revokes refresh tokens so the
    // change takes effect immediately.

    const bizRef = adminFirestore.collection('businesses').doc(businessId)
    const snap   = await bizRef.get()
    if (!snap.exists) {
      return NextResponse.json({ error: 'Business not found' }, { status: 404 })
    }

    await bizRef.update(updates)

    const raw = snap.data() as Record<string, unknown>
    await writeAudit({
      action: 'edit_business',
      resourceType: 'business',
      resourceId: businessId,
      resourceName: (updates.businessName as string) || (raw.businessName as string) || businessId,
      isDestructive: false,
      before: { businessName: raw.businessName, businessCategory: raw.businessCategory, placeOfBusiness: raw.placeOfBusiness },
      after:  { ...updates, updatedAt: undefined },
    })

    return NextResponse.json({ success: true })
  } catch (err) {
    console.error(`[PUT /api/admin/businesses/${uid}/${businessId}]`, err)
    return NextResponse.json({ error: 'Failed to update business' }, { status: 500 })
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

    const bizRef = adminFirestore.collection('businesses').doc(businessId)
    const bizDoc = await bizRef.get()
    const bizName = (bizDoc.data()?.businessName as string) || businessId

    await bizRef.update({ isActive: body.isActive, updatedAt: new Date() })

    await writeAudit({
      action: body.isActive ? 'unsuspend_business' : 'suspend_business',
      resourceType: 'business',
      resourceId: businessId,
      resourceName: bizName,
      isDestructive: !body.isActive,
      before: { isActive: !body.isActive },
      after:  { isActive:  body.isActive },
    })

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
