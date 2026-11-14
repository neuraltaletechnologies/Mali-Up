import { restFirestore as adminFirestore, type DocumentData } from '@/lib/firestore-rest'
import { normalizePhone, SmsRecipient } from '@/lib/beem'
import type { SmsCampaignAudience } from '@/types'
import { withCache } from '@/lib/api-cache'

/**
 * Field names follow what the mobile app writes
 * (apps/mobile-app/lib/features/onboarding/data/repositories/onboarding_repository.dart):
 *   users/{uid}:          phone (canonical 255…), name, firstName,
 *                         selectedBusinessId (owners) / businessId (staff)
 *   businesses/{id}:      ownerUid, ownerName, businessName, businessCategory, plan
 * Businesses carry no phone of their own — the owner's phone lives on users/{ownerUid}.
 */

// Preview cap only — the Cloud Function (functions/src/sms_campaigns.ts)
// re-resolves the audience at send time with paged reads and no cap. This
// REST client has no query cursors, so the estimate reads in one go.
const MAX_DOCS = 20000

type Directory = {
  usersById: Map<string, DocumentData>
  usersByPhone: Map<string, { id: string; data: DocumentData }>
  businessesById: Map<string, DocumentData>
}

// Every estimate and campaign create needs the whole users + businesses
// directory. Share one load per minute so composing a campaign (estimate on
// each audience change, then the create) doesn't re-read both collections.
const DIRECTORY_TTL_MS = 60_000

function loadDirectory(): Promise<Directory> {
  return withCache('sms-recipient-directory', DIRECTORY_TTL_MS, fetchDirectory)
}

async function fetchDirectory(): Promise<Directory> {
  const [usersSnap, bizSnap] = await Promise.all([
    adminFirestore.collection('users').limit(MAX_DOCS).get(),
    adminFirestore.collection('businesses').limit(MAX_DOCS).get(),
  ])

  const usersById = new Map<string, DocumentData>()
  const usersByPhone = new Map<string, { id: string; data: DocumentData }>()
  for (const doc of usersSnap.docs) {
    const data = doc.data()
    usersById.set(doc.id, data)
    const phone = normalizePhone((data.phone as string) || (data.phoneNumber as string) || '')
    // Prefer the owner account when an owner and a staff record share a phone.
    if (phone && (!usersByPhone.has(phone) || data.isTeamMember !== true)) {
      usersByPhone.set(phone, { id: doc.id, data })
    }
  }

  const businessesById = new Map<string, DocumentData>()
  for (const doc of bizSnap.docs) businessesById.set(doc.id, doc.data())

  return { usersById, usersByPhone, businessesById }
}

function firstNameOf(...candidates: unknown[]): string {
  for (const c of candidates) {
    const s = typeof c === 'string' ? c.trim() : ''
    if (s) return s.split(/\s+/)[0]
  }
  return 'Mteja'
}

function businessNameOf(biz: DocumentData | undefined): string {
  return ((biz?.businessName as string) || (biz?.name as string) || '').trim()
}

function isValidPhone(phone: string): boolean {
  return phone.length >= 9 && phone.length <= 15
}

/** Builds a recipient for a user doc, pulling the business name from their business. */
function recipientFromUser(dir: Directory, id: string, user: DocumentData, phone: string): SmsRecipient {
  const bizId = (user.selectedBusinessId as string) || (user.businessId as string) || ''
  return {
    recipientId: id,
    phone,
    name: firstNameOf(user.firstName, user.name),
    businessName: businessNameOf(dir.businessesById.get(bizId)),
  }
}

/** Builds a recipient for a business doc, using the owner's user doc for the phone. */
function recipientFromBusiness(dir: Directory, id: string, biz: DocumentData): SmsRecipient | null {
  const owner = dir.usersById.get((biz.ownerUid as string) || '')
  const phone = normalizePhone(
    (biz.ownerPhone as string) || (biz.phone as string) || (owner?.phone as string) || ''
  )
  if (!isValidPhone(phone)) return null
  return {
    recipientId: id,
    phone,
    name: firstNameOf(owner?.firstName, biz.ownerName, owner?.name),
    businessName: businessNameOf(biz),
  }
}

/** Looks up a single phone number in users so tags resolve for custom/test sends. */
export async function resolveRecipientByPhone(raw: string, recipientId: number | string = 1): Promise<SmsRecipient> {
  const phone = normalizePhone(raw)
  const snap = await adminFirestore.collection('users').where('phone', '==', phone).limit(5).get()
  const doc = snap.docs.find((d) => d.data().isTeamMember !== true) ?? snap.docs[0]
  if (!doc) return { recipientId, phone, name: 'Mteja' }

  const user = doc.data()
  const bizId = (user.selectedBusinessId as string) || (user.businessId as string) || ''
  const biz = bizId ? await adminFirestore.collection('businesses').doc(bizId).get() : null
  return {
    recipientId,
    phone,
    name: firstNameOf(user.firstName, user.name),
    businessName: businessNameOf(biz?.exists ? biz.data() : undefined),
  }
}

/**
 * Resolves audience filter into a deduplicated list of recipients with phone, name, and businessName.
 */
export async function resolveSmsRecipients(audience: SmsCampaignAudience): Promise<SmsRecipient[]> {
  const recipientsMap = new Map<string, SmsRecipient>()
  const dir = await loadDirectory()

  // One SMS per phone; when an owner matches several businesses, use the one
  // they have open in the app (mirrors addBusiness in sms_campaigns.ts).
  const openMatch = new Set<string>()
  const addBusiness = (id: string, biz: DocumentData) => {
    const r = recipientFromBusiness(dir, id, biz)
    if (!r) return
    const owner = dir.usersById.get((biz.ownerUid as string) || '')
    const isOpen = ((owner?.selectedBusinessId as string) || (owner?.businessId as string) || '') === id
    if (!recipientsMap.has(r.phone) || (isOpen && !openMatch.has(r.phone))) {
      recipientsMap.set(r.phone, r)
      if (isOpen) openMatch.add(r.phone)
    }
  }

  if (audience.kind === 'custom_numbers') {
    ;(audience.customNumbers || []).forEach((raw, idx) => {
      const phone = normalizePhone(raw)
      if (!isValidPhone(phone) || recipientsMap.has(phone)) return
      const match = dir.usersByPhone.get(phone)
      recipientsMap.set(
        phone,
        match
          ? { ...recipientFromUser(dir, match.id, match.data, phone), recipientId: idx + 1 }
          : { recipientId: idx + 1, phone, name: 'Mteja' }
      )
    })
    return Array.from(recipientsMap.values())
  }

  if (audience.kind === 'selected_businesses') {
    for (const id of audience.businessIds || []) {
      const biz = dir.businessesById.get(id)
      if (biz) addBusiness(id, biz)
    }
    return Array.from(recipientsMap.values())
  }

  if (audience.kind === 'business_category') {
    const targetCategory = (audience.category || '').toLowerCase().trim()
    for (const [id, biz] of dir.businessesById) {
      const cat = (
        (biz.businessCategory as string) ||
        (biz.category as string) ||
        (biz.industry as string) ||
        ''
      ).toLowerCase().trim()
      if (cat === targetCategory || cat.includes(targetCategory)) addBusiness(id, biz)
    }
    return Array.from(recipientsMap.values())
  }

  if (audience.kind === 'plan_tier') {
    const targetTier = (audience.planTier || '').toLowerCase().trim()
    for (const [id, biz] of dir.businessesById) {
      const tier = ((biz.plan as string) || 'starter').toLowerCase().trim()
      if (tier === targetTier) addBusiness(id, biz)
    }
    return Array.from(recipientsMap.values())
  }

  // audience.kind === 'all' — every user with a phone
  for (const [id, user] of dir.usersById) {
    const phone = normalizePhone((user.phone as string) || (user.phoneNumber as string) || '')
    if (!isValidPhone(phone) || recipientsMap.has(phone)) continue
    recipientsMap.set(phone, recipientFromUser(dir, id, user, phone))
  }

  return Array.from(recipientsMap.values())
}
