import { NextResponse } from 'next/server'
import { adminFirestore } from '@/lib/firebase-admin'
import { requireAdminSession } from '@/lib/api-guard'
import { writeAudit } from '@/lib/write-audit'

export async function POST(request: Request) {
  const denied = await requireAdminSession()
  if (denied) return denied

  try {
    const body = (await request.json()) as Record<string, unknown>
    if (!body.categoryName || !body.businessTypeId) {
      return NextResponse.json(
        { error: 'categoryName and businessTypeId are required' },
        { status: 400 },
      )
    }

    const ref = await adminFirestore.collection('master_categories').add({
      categoryName:   body.categoryName,
      businessTypeId: body.businessTypeId,
      description:    body.description ?? '',
      icon:           body.icon ?? '',
      isActive:       true,
      source:         'admin',
      createdAt:      new Date(),
      updatedAt:      new Date(),
    })

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
