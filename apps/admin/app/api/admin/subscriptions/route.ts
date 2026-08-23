import { NextResponse } from 'next/server'
import { restFirestore as adminFirestore } from '@/lib/firestore-rest'
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
    // Fetch all businesses and filter in-memory to avoid needing a
    // COLLECTION_GROUP index on the 'plan' field.
    const snap = await adminFirestore
      .collectionGroup('businesses')
      .limit(1000)
      .get()

    const paidPlans = new Set(['growth', 'business', 'enterprise'])
    const subscriptions: Subscription[] = snap.docs
      .filter((doc) => paidPlans.has((doc.data().plan as string | undefined)?.toLowerCase() ?? ''))
      .map((doc) => {
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

      const planSource = d.planSource === 'admin_grant' || d.planSource === 'clickpesa' ? d.planSource : undefined

      return {
        id:              doc.id,
        businessId:      doc.id,
        businessName:    (d.businessName as string) || 'Unnamed Business',
        plan,
        status:          subStatus,
        amount:          mrrForPlan(plan),
        nextBillingDate: toIso(d.nextBillingDate ?? d.renewalDate),
        // Manually granted plans never touched ClickPesa — say so plainly
        // rather than showing a misleading default payment method.
        paymentMethod:   planSource === 'admin_grant' ? 'Manually granted' : (d.paymentMethod as string) || 'M-Pesa',
        startedAt:       toIso(d.planStartedAt ?? d.createdAt),
        ownerId:         uid,
        planSource,
      }
    })

    return NextResponse.json({ subscriptions, total: subscriptions.length })
  } catch (err) {
    console.error('[GET /api/admin/subscriptions]', err)
    return NextResponse.json({ error: 'Failed to fetch subscriptions' }, { status: 500 })
  }
}
