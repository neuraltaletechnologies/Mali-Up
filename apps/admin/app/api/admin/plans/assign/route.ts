import { NextResponse } from 'next/server'
import { adminFirestore, adminAuth } from '@/lib/firebase-admin'
import { requireAdminSession } from '@/lib/api-guard'
import { writeAudit } from '@/lib/write-audit'
import { FieldValue } from 'firebase-admin/firestore'
import type { PlanTier } from '@/types'

const VALID_TIERS = new Set<string>(['starter', 'growth', 'business', 'enterprise', 'lifetime'])

export async function POST(req: Request) {
  const denied = await requireAdminSession()
  if (denied) return denied

  try {
    const { uid, businessId, tier, cycleMonths } = await req.json() as {
      uid: string
      businessId: string
      tier: string
      cycleMonths: number
    }

    if (!uid || !businessId || !VALID_TIERS.has(tier)) {
      return NextResponse.json({ error: 'uid, businessId, and valid tier are required' }, { status: 400 })
    }

    const months = Number(cycleMonths) || 6
    const now = new Date()
    const expiresAt = tier === 'starter'
      ? null
      : new Date(now.getTime() + months * 30 * 24 * 60 * 60 * 1000)

    const bizRef = adminFirestore
      .collection('users')
      .doc(uid)
      .collection('businesses')
      .doc(businessId)

    const before = (await bizRef.get()).data() ?? {}

    const update: Record<string, unknown> = {
      plan: tier,
      subscriptionStatus: tier === 'starter' ? 'inactive' : 'active',
      planStartedAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    }
    if (expiresAt) update.planExpiresAt = expiresAt
    if (tier === 'starter') update.planExpiresAt = FieldValue.delete()

    await bizRef.set(update, { merge: true })

    // Also update the user's top-level plan field (used by mobile app)
    await adminFirestore.collection('users').doc(uid).set(
      {
        plan: tier,
        ...(expiresAt ? { planExpiresAt: expiresAt } : { planExpiresAt: FieldValue.delete() }),
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    )

    // Revoke refresh tokens so the change takes effect on next app open
    await adminAuth.revokeRefreshTokens(uid).catch(() => {})

    await writeAudit({
      action: 'plan.assign',
      resourceType: 'business',
      resourceId: businessId,
      resourceName: businessId,
      before: { plan: before.plan, subscriptionStatus: before.subscriptionStatus },
      after: { plan: tier, cycleMonths: months, expiresAt: expiresAt?.toISOString() },
      isDestructive: false,
    })

    return NextResponse.json({ ok: true, tier, expiresAt: expiresAt?.toISOString() ?? null })
  } catch (err) {
    console.error('[POST /api/admin/plans/assign]', err)
    return NextResponse.json({ error: 'Failed to assign plan' }, { status: 500 })
  }
}
