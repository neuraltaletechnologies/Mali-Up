import { NextResponse } from 'next/server'
import { FieldValue } from 'firebase-admin/firestore'
import { adminFirestore } from '@/lib/firebase-admin'
import { requireAdminSession } from '@/lib/api-guard'
import { writeAudit } from '@/lib/write-audit'

type Params = { id: string }

type PatchBody =
  | { action: 'approve' | 'reject'; adminNotes?: string }
  | {
      action: 'push'
      adminNotes?: string
      // Editable fields before pushing
      productName?: string
      categoryName?: string
      categorySlug?: string
      unit?: string
      description?: string
      businessType?: string
      businessTypeName?: string
    }

export async function PATCH(
  request: Request,
  { params }: { params: Promise<Params> },
) {
  const denied = await requireAdminSession()
  if (denied) return denied

  const { id } = await params

  try {
    const body = (await request.json()) as PatchBody
    if (!['approve', 'reject', 'push'].includes(body.action)) {
      return NextResponse.json({ error: 'action must be approve | reject | push' }, { status: 400 })
    }

    const ref = adminFirestore.collection('catalog_community_submissions').doc(id)
    const doc = await ref.get()
    if (!doc.exists) return NextResponse.json({ error: 'Submission not found' }, { status: 404 })

    const data = doc.data()!
    const submissionType: string = (data.type as string) || 'product'

    if (body.action === 'push') {
      // Build the master catalog document from submission + any edits supplied by admin
      const adminEdits = body as Extract<PatchBody, { action: 'push' }>
      const targetCollection = submissionType === 'category' ? 'master_categories' : 'master_products'

      const businessTypeName: string = adminEdits.businessTypeName || (data.businessTypeName as string) || (data.businessType as string) || 'Retail'

      let masterDoc: Record<string, unknown>
      let masterDocId: string

      if (submissionType === 'category') {
        const name = adminEdits.categoryName || (data.categoryName as string) || (data.productName as string) || ''
        const slug = adminEdits.categorySlug || (data.categorySlug as string) || slugify(name)
        masterDocId = `${slug}_${businessTypeName.toLowerCase().replace(/[^a-z0-9]+/g, '_')}_community`
        masterDoc = {
          businessTypes:   [businessTypeName],
          categoryName:    name,
          categoryNameSw:  '',
          categorySlug:    slug,
          icon:            '',
          displayOrder:    999,
          source:          'community',
          promotedFromId:  id,
          createdAt:       FieldValue.serverTimestamp(),
        }
      } else {
        const name = adminEdits.productName || (data.productName as string) || ''
        const slug = slugify(name)
        const categorySlug = adminEdits.categorySlug || (data.categorySlug as string) || ''
        masterDocId = `${slug}_${businessTypeName.toLowerCase().replace(/[^a-z0-9]+/g, '_')}_community`
        masterDoc = {
          businessTypes:  [businessTypeName],
          categorySlug:   categorySlug,
          productName:    name,
          productNameSw:  '',
          productSlug:    slug,
          genericName:    '',
          brandNames:     [],
          unit:           adminEdits.unit || (data.unit as string) || 'Piece',
          unitAlternatives: [],
          commonBarcodes: [],
          searchKeywords: [],
          tags:           [],
          prescriptionRequired: false,
          coldStorage:    false,
          source:         'community',
          promotedFromId: id,
          createdAt:      FieldValue.serverTimestamp(),
        }
      }

      // Write to master catalog collection
      await adminFirestore.collection(targetCollection).doc(masterDocId).set(masterDoc)

      // Update submission status
      await ref.update({
        status:     'pushed',
        masterDocId,
        pushedAt:   FieldValue.serverTimestamp(),
        adminNotes: adminEdits.adminNotes || (data.adminNotes as string) || '',
      })

      await writeAudit({
        action:       'push_to_master_catalog',
        resourceType: 'catalog_submission',
        resourceId:   id,
        resourceName: (data.productName as string) || id,
        isDestructive: false,
        before: { status: data.status },
        after:  { status: 'pushed', masterDocId, targetCollection },
      })

      return NextResponse.json({ success: true, masterDocId, collection: targetCollection })
    }

    // approve / reject
    const newStatus = body.action === 'approve' ? 'approved' : 'rejected'
    await ref.update({
      status:     newStatus,
      reviewedAt: FieldValue.serverTimestamp(),
      ...(body.adminNotes ? { adminNotes: body.adminNotes } : {}),
    })

    await writeAudit({
      action:       body.action === 'approve' ? 'approve_submission' : 'reject_submission',
      resourceType: 'catalog_submission',
      resourceId:   id,
      resourceName: (data.productName as string) || id,
      isDestructive: body.action === 'reject',
      before: { status: 'pending' },
      after:  { status: newStatus },
    })

    return NextResponse.json({ success: true })
  } catch (err) {
    console.error(`[PATCH /api/admin/catalog/submissions/${id}]`, err)
    return NextResponse.json({ error: 'Failed to update submission' }, { status: 500 })
  }
}

function slugify(s: string): string {
  return s.trim().toLowerCase()
    .replace(/[^a-z0-9]+/g, '_')
    .replace(/_+/g, '_')
    .replace(/^_|_$/g, '')
}
