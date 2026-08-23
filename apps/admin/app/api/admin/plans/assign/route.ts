import { NextResponse } from 'next/server'
import { adminAuth } from '@/lib/firebase-admin'
import { restFirestore as adminFirestore } from '@/lib/firestore-rest'
import { requireAdminSession } from '@/lib/api-guard'
import { writeAudit } from '@/lib/write-audit'
import { addDuration, isValidDurationUnit, formatDuration, type DurationUnit } from '@/lib/duration'
import { FieldValue } from '@/lib/firestore-rest'
import type { PlanTier } from '@/types'

const VALID_TIERS = new Set<string>(['starter', 'growth', 'business', 'enterprise', 'lifetime'])

export async function POST(req: Request) {
  const denied = await requireAdminSession()
  if (denied) return denied

  try {
    const body = await req.json() as {
      uid: string
      businessId: string
      tier: string
      durationValue?: number
      durationUnit?: string
      // Back-compat: older callers may still send a plain months count.
      cycleMonths?: number
    }
    const { uid, businessId, tier } = body

    if (!uid || !businessId || !VALID_TIERS.has(tier)) {
      return NextResponse.json({ error: 'uid, businessId, and valid tier are required' }, { status: 400 })
    }

    let durationValue = Number(body.durationValue)
    let durationUnit: DurationUnit = isValidDurationUnit(body.durationUnit) ? body.durationUnit : 'months'
    if (!Number.isFinite(durationValue) || durationValue <= 0) {
      // Fall back to the legacy months field, then a 6-month default.
      durationValue = Number(body.cycleMonths) || 6
      durationUnit = 'months'
    }
    durationValue = Math.min(Math.max(Math.round(durationValue), 1), 3650)

    // This is an admin assigning a plan by hand — it does NOT mean the
    // business actually paid. Real activations happen exclusively via
    // ClickPesa (functions/src/clickpesa.ts's verifyClickPesaPayment),
    // which stamps planSource: 'clickpesa'. Anything set here is stamped
    // 'admin_grant' so admin UI can show it was manually granted, not paid.
    const now = new Date()
    const expiresAt = tier === 'starter' ? null : addDuration(now, durationValue, durationUnit)

    // Businesses live in the top-level `businesses` collection, not under users/{uid}
    const bizRef = adminFirestore.collection('businesses').doc(businessId)

    const before = (await bizRef.get()).data() ?? {}

    const update: Record<string, unknown> = {
      plan: tier,
      subscriptionStatus: tier === 'starter' ? 'inactive' : 'active',
      planStartedAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    }
    if (expiresAt) {
      update.planExpiresAt = expiresAt
      update.planSource = 'admin_grant'
    } else {
      update.planExpiresAt = FieldValue.delete()
      update.planSource = FieldValue.delete()
    }

    // A subscription belongs to the owner, not a single business — an owner
    // with several businesses shares one plan across all of them. Mirror the
    // same fields onto every business owned by this uid so admin views (which
    // read business.plan for display) don't show a stale tier on the ones
    // that weren't the "active" business when the request was submitted.
    const siblingBizSnap = await adminFirestore
      .collection('businesses')
      .where('ownerUid', '==', uid)
      .get()

    const batch = adminFirestore.batch()
    batch.set(bizRef, update, { merge: true })
    for (const doc of siblingBizSnap.docs) {
      if (doc.id === businessId) continue
      batch.set(doc.ref, update, { merge: true })
    }
    await batch.commit()

    // Also update the user's top-level plan field (used by mobile app)
    await adminFirestore.collection('users').doc(uid).set(
      {
        plan: tier,
        ...(expiresAt
          ? { planExpiresAt: expiresAt, planSource: 'admin_grant' }
          : { planExpiresAt: FieldValue.delete(), planSource: FieldValue.delete() }),
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
      resourceName: (before.businessName as string) || businessId,
      before: { plan: before.plan, subscriptionStatus: before.subscriptionStatus },
      after: {
        plan: tier,
        duration: tier === 'starter' ? null : formatDuration(durationValue, durationUnit),
        expiresAt: expiresAt?.toISOString(),
        planSource: expiresAt ? 'admin_grant' : null,
        businessesUpdated: siblingBizSnap.docs.filter((d) => d.id !== businessId).length + 1,
      },
      isDestructive: false,
    })

    return NextResponse.json({ ok: true, tier, expiresAt: expiresAt?.toISOString() ?? null })
  } catch (err) {
    console.error('[POST /api/admin/plans/assign]', err)
    return NextResponse.json({ error: 'Failed to assign plan' }, { status: 500 })
  }
}
