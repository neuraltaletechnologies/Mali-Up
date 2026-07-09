/**
 * One-time backfill — run once after deploying the mobile app update that
 * denormalizes `staffCount` onto each business doc (addTeamMember /
 * deleteTeamMember now maintain it going forward via FieldValue.increment).
 * Existing businesses created before that change have no `staffCount` field,
 * so the admin portal would show 0 staff for them until this runs.
 *
 * Usage:
 *   pnpm run backfill:staff-counts           # dry run (default)
 *   pnpm run backfill:staff-counts -- --apply # actually write changes
 *
 * Prerequisites:
 *   - .env.local must contain FIREBASE_PROJECT_ID, FIREBASE_CLIENT_EMAIL,
 *     and FIREBASE_PRIVATE_KEY (or GOOGLE_APPLICATION_CREDENTIALS must be set)
 *
 * What this does:
 *   For each business, counts staff sub-collection docs while excluding the
 *   UID-keyed "pointer" doc that accepted invites get mirrored to (it carries
 *   a `memberId` field pointing back at the real, auto-generated doc — the
 *   pointer exists only so Firestore security rules can look up a worker's
 *   permissions by auth UID, it is not a second team member). Writes the
 *   result to `staffCount` on the business doc.
 */

import 'dotenv/config'
import admin from 'firebase-admin'

const projectId    = process.env.FIREBASE_PROJECT_ID ?? 'neuraltale-mali-up'
const clientEmail   = process.env.FIREBASE_CLIENT_EMAIL
const rawPrivateKey = process.env.FIREBASE_PRIVATE_KEY

if (!clientEmail || !rawPrivateKey) {
  console.error(
    '\nMissing FIREBASE_CLIENT_EMAIL or FIREBASE_PRIVATE_KEY in .env.local\n' +
    'Download a service account key from:\n' +
    '  Firebase Console → Project settings → Service accounts → Generate new private key\n'
  )
  process.exit(1)
}

if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert({
      projectId,
      clientEmail,
      privateKey: rawPrivateKey.replace(/\\n/g, '\n'),
    }),
    projectId,
  })
}

const db = admin.firestore()
const BATCH_SIZE = 500
const apply = process.argv.includes('--apply')

function isCanonicalStaffDoc(data: FirebaseFirestore.DocumentData): boolean {
  // Pointer docs are stamped with `memberId` pointing back at the canonical
  // doc; the canonical doc itself never has that field.
  return !('memberId' in data)
}

async function main() {
  console.log(apply ? '\nRunning backfill (--apply set — writes WILL be committed)\n' : '\nDry run (pass --apply to actually write changes)\n')

  const bizSnap = await db.collection('businesses').get()
  let scanned = 0
  let updated = 0
  let unchanged = 0

  const pending: { ref: FirebaseFirestore.DocumentReference; count: number }[] = []

  for (const bizDoc of bizSnap.docs) {
    scanned++
    const staffSnap = await bizDoc.ref.collection('staff').get()
    const count = staffSnap.docs.filter((d) => isCanonicalStaffDoc(d.data())).length
    const current = bizDoc.data().staffCount
    if (current === count) {
      unchanged++
      continue
    }
    pending.push({ ref: bizDoc.ref, count })
  }

  for (let i = 0; i < pending.length; i += BATCH_SIZE) {
    const group = pending.slice(i, i + BATCH_SIZE)
    if (apply) {
      const batch = db.batch()
      for (const { ref, count } of group) {
        batch.update(ref, { staffCount: count })
      }
      await batch.commit()
    }
    updated += group.length
  }

  console.log(`businesses: ${scanned} scanned, ${unchanged} already correct, ${updated} ${apply ? 'updated' : 'would be updated'}`)
  console.log(apply ? '\nDone.\n' : '\nRe-run with --apply to commit these changes.\n')
}

main().catch((err) => {
  console.error('\nFailed:', err.message ?? err)
  process.exit(1)
})
