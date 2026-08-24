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

    // Plans are independent per business — an owner with several businesses
    // no longer shares one plan across all of them, so this only ever
    // touches the targeted business. (It used to also mirror onto every
    // sibling business the same uid owned, and dual-write users/{uid}.plan
    // for the mobile app; the mobile app now reads businesses/{businessId}
    // directly, so neither is needed.)
    await bizRef.set(update, { merge: true })

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
      },
      isDestructive: false,
    })

    return NextResponse.json({ ok: true, tier, expiresAt: expiresAt?.toISOString() ?? null })
  } catch (err) {
    console.error('[POST /api/admin/plans/assign]', err)
    return NextResponse.json({ error: 'Failed to assign plan' }, { status: 500 })
  }
}
