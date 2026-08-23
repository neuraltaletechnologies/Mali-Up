import { NextResponse } from 'next/server'
import { restFirestore as adminFirestore } from '@/lib/firestore-rest'
import { requireAdminSession } from '@/lib/api-guard'
import { writeAudit } from '@/lib/write-audit'
import type { PlanTier, PlanDefinition } from '@/types'

const CONFIG_DOC = 'platform_config'
const PLANS_DOC  = 'plans'

const VALID_TIERS = new Set<string>(['starter', 'growth', 'business', 'enterprise', 'lifetime'])

export async function PATCH(
  req: Request,
  { params }: { params: Promise<{ tier: string }> },
) {
  const denied = await requireAdminSession()
  if (denied) return denied

  const { tier } = await params
  if (!VALID_TIERS.has(tier)) {
    return NextResponse.json({ error: 'Invalid tier' }, { status: 400 })
  }

  try {
    const body = await req.json() as Partial<PlanDefinition>

    // Sanitise — only allow known fields
    const patch: Partial<PlanDefinition> = {}
    const numFields = ['pricePerCycle', 'cycleMonths', 'maxUsers', 'monthlyInvoices', 'maxBusinesses', 'maxCustomers'] as const
    const boolFields = [
      'cashFlow', 'expenseTracking', 'manualDebt',
      'fullReports', 'mpesaImport', 'smsReminders', 'allExports',
      'multiLocation', 'apiAccess', 'prioritySupport',
      'customIntegrations', 'whiteLabel', 'dedicatedOnboarding',
    ] as const

    for (const f of numFields) {
      if (f in body && typeof body[f] === 'number') patch[f] = body[f]
    }
    for (const f of boolFields) {
      if (f in body && typeof body[f] === 'boolean') patch[f] = body[f]
    }

    const ref = adminFirestore.collection(CONFIG_DOC).doc(PLANS_DOC)

    // Read current for audit trail
    const before = (await ref.get()).data()?.[tier] ?? {}

    await ref.set({ [tier as PlanTier]: patch }, { merge: true })

    await writeAudit({
      action: 'plan.update',
      resourceType: 'plan',
      resourceId: tier,
      resourceName: `${tier} plan`,
      before,
      after: patch,
      isDestructive: false,
    })

    return NextResponse.json({ ok: true })
  } catch (err) {
    console.error('[PATCH /api/admin/plans/[tier]]', err)
    return NextResponse.json({ error: 'Failed to update plan' }, { status: 500 })
  }
}
