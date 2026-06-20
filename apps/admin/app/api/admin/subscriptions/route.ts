import { NextResponse } from 'next/server'
import { adminFirestore } from '@/lib/firebase-admin'
import { requireAdminSession } from '@/lib/api-guard'
import { normalisePlan, mrrForPlan } from '@/lib/firestore-mappers'
import type { Subscription } from '@/types'

function toIso(value: unknown): string {
  if (!value) return new Date().toISOString()
  if (typeof value === 'string') return value
  if (typeof value === 'object' && value !== null) {
    const s = (value as Record<string, number>)._seconds ?? (value as Record<string, number>).seconds
    if (typeof s === 'number') return new Date(s * 1000).toISOString()
  }
  return new Date().toISOString()
}

export async function GET() {
  const denied = await requireAdminSession()
  if (denied) return denied

  try {
    const snap = await adminFirestore
      .collectionGroup('businesses')
      .where('plan', 'in', ['growth', 'business', 'enterprise'])
      .limit(500)
      .get()

    const subscriptions: Subscription[] = snap.docs.map((doc) => {
      const d  = doc.data()
      const uid = doc.ref.parent.parent?.id ?? ''
      const plan = normalisePlan(d.plan as string)
      const rawStatus = (d.subscriptionStatus as string | undefined)?.toLowerCase()
      const subStatus: Subscription['status'] =
        rawStatus === 'past_due'  ? 'past_due' :
        rawStatus === 'cancelled' ? 'cancelled' :
        rawStatus === 'trialing'  ? 'trialing' :
        d.isActive === false      ? 'past_due' :
        'active'

      return {
        id:              doc.id,
        businessId:      doc.id,
        businessName:    (d.businessName as string) || 'Unnamed Business',
        plan,
        status:          subStatus,
        amount:          mrrForPlan(plan),
        nextBillingDate: toIso(d.nextBillingDate ?? d.renewalDate),
        paymentMethod:   (d.paymentMethod as string) || 'M-Pesa',
        startedAt:       toIso(d.planStartedAt ?? d.createdAt),
        ownerId:         uid,
      }
    })

    return NextResponse.json({ subscriptions, total: subscriptions.length })
  } catch (err) {
    console.error('[GET /api/admin/subscriptions]', err)
    return NextResponse.json({ error: 'Failed to fetch subscriptions' }, { status: 500 })
  }
}
