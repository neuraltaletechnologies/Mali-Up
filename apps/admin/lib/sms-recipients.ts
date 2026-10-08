import { restFirestore as adminFirestore } from '@/lib/firestore-rest'
import { normalizePhone, SmsRecipient } from '@/lib/beem'
import type { SmsCampaignAudience } from '@/types'

/**
 * Resolves audience filter into a deduplicated list of recipients with phone, name, and businessName.
 */
export async function resolveSmsRecipients(audience: SmsCampaignAudience): Promise<SmsRecipient[]> {
  const recipientsMap = new Map<string, SmsRecipient>()

  if (audience.kind === 'custom_numbers') {
    const list = audience.customNumbers || []
    list.forEach((raw, idx) => {
      const phone = normalizePhone(raw)
      if (phone.length >= 9 && phone.length <= 15) {
        recipientsMap.set(phone, {
          recipientId: idx + 1,
          phone,
          name: 'Mteja',
        })
      }
    })
    return Array.from(recipientsMap.values())
  }

  if (audience.kind === 'selected_businesses') {
    const businessIds = audience.businessIds || []
    if (businessIds.length === 0) return []

    // Fetch businesses in chunks of 30 or get individually
    const snaps = await Promise.all(
      businessIds.map((id) => adminFirestore.collection('businesses').doc(id).get())
    )

    for (const snap of snaps) {
      if (!snap.exists) continue
      const data = snap.data()!
      const rawPhone = (data.ownerPhone as string) || (data.phone as string) || ''
      const phone = normalizePhone(rawPhone)
      if (phone.length >= 9 && phone.length <= 15) {
        recipientsMap.set(phone, {
          recipientId: snap.id,
          phone,
          name: (data.ownerName as string) || (data.name as string) || 'Mteja',
          businessName: (data.name as string) || '',
        })
      }
    }
    return Array.from(recipientsMap.values())
  }

  if (audience.kind === 'business_category') {
    const targetCategory = (audience.category || '').toLowerCase().trim()
    const snap = await adminFirestore.collection('businesses').limit(500).get()

    for (const doc of snap.docs) {
      const data = doc.data()
      const cat = (
        (data.category as string) ||
        (data.businessCategory as string) ||
        (data.industry as string) ||
        ''
      ).toLowerCase().trim()

      if (cat === targetCategory || cat.includes(targetCategory)) {
        const rawPhone = (data.ownerPhone as string) || (data.phone as string) || ''
        const phone = normalizePhone(rawPhone)
        if (phone.length >= 9 && phone.length <= 15) {
          recipientsMap.set(phone, {
            recipientId: doc.id,
            phone,
            name: (data.ownerName as string) || (data.name as string) || 'Mteja',
            businessName: (data.name as string) || '',
          })
        }
      }
    }
    return Array.from(recipientsMap.values())
  }

  if (audience.kind === 'plan_tier') {
    const targetTier = (audience.planTier || '').toLowerCase().trim()
    const snap = await adminFirestore.collection('businesses').limit(500).get()

    for (const doc of snap.docs) {
      const data = doc.data()
      const tier = ((data.plan as string) || 'starter').toLowerCase().trim()

      if (tier === targetTier) {
        const rawPhone = (data.ownerPhone as string) || (data.phone as string) || ''
        const phone = normalizePhone(rawPhone)
        if (phone.length >= 9 && phone.length <= 15) {
          recipientsMap.set(phone, {
            recipientId: doc.id,
            phone,
            name: (data.ownerName as string) || (data.name as string) || 'Mteja',
            businessName: (data.name as string) || '',
          })
        }
      }
    }
    return Array.from(recipientsMap.values())
  }

  // audience.kind === 'all'
  // Query all users from users collection
  const usersSnap = await adminFirestore.collection('users').limit(1000).get()

  for (const doc of usersSnap.docs) {
    const data = doc.data()
    const rawPhone = (data.phone as string) || (data.phoneNumber as string) || ''
    const phone = normalizePhone(rawPhone)
    if (phone.length >= 9 && phone.length <= 15) {
      const name =
        (data.firstName as string)?.trim() ||
        (data.name as string)?.trim() ||
        'Mteja'
      const businessName = (data.businessName as string) || ''

      recipientsMap.set(phone, {
        recipientId: doc.id,
        phone,
        name,
        businessName,
      })
    }
  }

  return Array.from(recipientsMap.values())
}
