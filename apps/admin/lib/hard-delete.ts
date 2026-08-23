import { FieldValue } from '@/lib/firestore-rest'
import { adminAuth, adminStorage } from './firebase-admin'
import { restFirestore as adminFirestore } from './firestore-rest'

// Hard-delete cascades wipe a business's/user's *owned* Firestore data
// (recursively, via recursiveDelete — covers every subcollection without a
// hand-maintained list), plus the Firebase Auth account and Storage receipts
// for a user delete. They deliberately do NOT touch collections that merely
// *reference* the uid/businessId by a string field (plan_requests,
// platform_refunds, platform_tickets, catalog_community_submissions,
// admin_audit_log) — those are historical/compliance records, not owned
// data, and an orphaned string reference doesn't break anything.

export async function deleteBusinessCascade(
  businessId: string,
  ownerUid?: string,
): Promise<void> {
  const bizRef = adminFirestore.collection('businesses').doc(businessId)
  await adminFirestore.recursiveDelete(bizRef)

  if (ownerUid) {
    await adminFirestore
      .collection('users')
      .doc(ownerUid)
      .update({ businesses: FieldValue.arrayRemove(businessId) })
      .catch(() => {})
  }
}

export async function deleteUserCascade(
  uid: string,
): Promise<{ deletedBusinessIds: string[] }> {
  const bizSnap = await adminFirestore
    .collection('businesses')
    .where('ownerUid', '==', uid)
    .get()

  const deletedBusinessIds = bizSnap.docs.map((doc) => doc.id)
  for (const businessId of deletedBusinessIds) {
    // Owner's user doc is about to be deleted too — skip the arrayRemove step.
    await deleteBusinessCascade(businessId)
  }

  await adminFirestore.recursiveDelete(adminFirestore.collection('users').doc(uid))
  await adminAuth.deleteUser(uid).catch(() => {})
  await adminStorage.deleteFiles({ prefix: `receipts/${uid}/` }).catch(() => {})

  return { deletedBusinessIds }
}
