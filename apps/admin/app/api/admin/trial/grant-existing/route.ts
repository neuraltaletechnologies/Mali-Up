import { NextResponse } from 'next/server'
import { restFirestore as adminFirestore, FieldValue } from '@/lib/firestore-rest'
import { requireAdminSession } from '@/lib/api-guard'
import { writeAudit } from '@/lib/write-audit'
import { isFreePlanValue, mergeTrialConfig } from '@/lib/trial-config'

// One-off backfill: gift the free trial to businesses that signed up before
// it existed. New businesses get it automatically (onBusinessCreatedTrial in
// functions/src/trial.ts). Writes exactly the fields that function writes,
// so the reminder push, end-date SMS and in-app popup all work the same.
//
// GET  → how many businesses would receive it (dry run)
// POST → grant it

const DAY_MS = 24 * 3600_000

interface Candidate {
  id: string
  ownerUid: string
}

function toMillis(v: unknown): number | null {
  if (v instanceof Date) return v.getTime()
  if (v && typeof v === 'object' && 'toDate' in v && typeof (v as { toDate: unknown }).toDate === 'function') {
    return ((v as { toDate: () => Date }).toDate()).getTime()
  }
  if (typeof v === 'string') {
    const t = Date.parse(v)
    return Number.isNaN(t) ? null : t
  }
  return null
}

async function findCandidates(): Promise<Candidate[]> {
  const snap = await adminFirestore.collection('businesses').get()
  const now = Date.now()
  const seenOwners = new Set<string>()
  const out: Candidate[] = []
  for (const doc of snap.docs) {
    const d = doc.data() as Record<string, unknown>
    if (d.trialStartedAt) continue // already had one
    if (d.isActive === false) continue
    const expires = toMillis(d.planExpiresAt)
    const onFree = isFreePlanValue(d.plan) || (expires !== null && expires < now)
    if (!onFree) continue
    // Lifetime / enterprise without expiry are never "free".
    if (!isFreePlanValue(d.plan) && expires === null) continue
    const ownerUid = String(d.ownerUid ?? '')
    // One trial per owner, even if they own several businesses.
    if (ownerUid && seenOwners.has(ownerUid)) continue
    if (ownerUid) seenOwners.add(ownerUid)
    out.push({ id: doc.id, ownerUid })
  }
  return out
}

export async function GET() {
  const denied = await requireAdminSession()
  if (denied) return denied
  try {
    const candidates = await findCandidates()
    return NextResponse.json({ eligible: candidates.length })
  } catch (err) {
    console.error('[GET /api/admin/trial/grant-existing]', err)
    return NextResponse.json({ error: 'Failed to count eligible businesses' }, { status: 500 })
  }
}

export async function POST() {
  const denied = await requireAdminSession()
  if (denied) return denied
  try {
    const configDoc = await adminFirestore.collection('platform_config').doc('trial').get()
    const config = mergeTrialConfig(configDoc.data())
    const candidates = await findCandidates()

    const now = new Date()
    const endsAt = new Date(now.getTime() + config.days * DAY_MS)

    // Two writes per business (business + owner) — stay well under 500/commit.
    for (let i = 0; i < candidates.length; i += 200) {
      const batch = adminFirestore.batch()
      for (const c of candidates.slice(i, i + 200)) {
        batch.set(
          adminFirestore.collection('businesses').doc(c.id),
          {
            plan: config.tier,
            planSource: 'trial',
            subscriptionStatus: 'trialing',
            planStartedAt: FieldValue.serverTimestamp(),
            planExpiresAt: endsAt,
            trialStartedAt: now,
            trialEndsAt: endsAt,
            trialDays: config.days,
            updatedAt: FieldValue.serverTimestamp(),
          },
          { merge: true },
        )
        if (c.ownerUid) {
          batch.set(
            adminFirestore.collection('users').doc(c.ownerUid),
            { trialUsedAt: FieldValue.serverTimestamp() },
            { merge: true },
          )
        }
      }
      await batch.commit()
    }

    await writeAudit({
      action: 'trial.grant_existing',
      resourceType: 'business',
      resourceId: 'bulk',
      resourceName: `${candidates.length} businesses`,
      isDestructive: false,
      after: { count: candidates.length, days: config.days, tier: config.tier, endsAt: endsAt.toISOString() },
    })

    return NextResponse.json({ granted: candidates.length, endsAt: endsAt.toISOString() })
  } catch (err) {
    console.error('[POST /api/admin/trial/grant-existing]', err)
    return NextResponse.json({ error: 'Failed to grant trials' }, { status: 500 })
  }
}
