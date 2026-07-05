/**
 * One-time backfill — run once before deploying the mobile app update that
 * switches the Master Catalog query from a single `businessType` string field
 * to a `businessTypes` array field.
 *
 * Usage:
 *   pnpm run migrate:catalog-business-types           # dry run (default)
 *   pnpm run migrate:catalog-business-types -- --apply # actually write changes
 *
 * Prerequisites:
 *   - .env.local must contain FIREBASE_PROJECT_ID, FIREBASE_CLIENT_EMAIL,
 *     and FIREBASE_PRIVATE_KEY (or GOOGLE_APPLICATION_CREDENTIALS must be set)
 *
 * What this does:
 *   Scans every doc in `master_categories` and `master_products`. For any doc
 *   that has a legacy `businessType` string but no `businessTypes` array yet,
 *   writes `businessTypes: [businessType]` (the legacy field is left in place —
 *   harmless, and safer than a destructive rewrite).
 *
 * IMPORTANT ROLLOUT ORDER: run this against production BEFORE the mobile app
 * release that queries `businessTypes` ships — otherwise un-migrated docs
 * become invisible to every user until this backfill runs.
 */

import 'dotenv/config'
import admin from 'firebase-admin'

const projectId     = process.env.FIREBASE_PROJECT_ID ?? 'neuraltale-mali-up'
const clientEmail    = process.env.FIREBASE_CLIENT_EMAIL
const rawPrivateKey  = process.env.FIREBASE_PRIVATE_KEY

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

async function migrateCollection(collectionName: string): Promise<{ scanned: number; migrated: number }> {
  const snap = await db.collection(collectionName).get()
  let migrated = 0

  const pending = snap.docs.filter((doc) => {
    const d = doc.data()
    const hasArray = Array.isArray(d.businessTypes) && d.businessTypes.length > 0
    const hasLegacy = typeof d.businessType === 'string' && d.businessType.length > 0
    return !hasArray && hasLegacy
  })

  for (let i = 0; i < pending.length; i += BATCH_SIZE) {
    const group = pending.slice(i, i + BATCH_SIZE)
    if (apply) {
      const batch = db.batch()
      for (const doc of group) {
        batch.update(doc.ref, { businessTypes: [doc.data().businessType as string] })
      }
      await batch.commit()
    }
    migrated += group.length
  }

  return { scanned: snap.size, migrated }
}

async function main() {
  console.log(apply ? '\nRunning migration (--apply set — writes WILL be committed)\n' : '\nDry run (pass --apply to actually write changes)\n')

  for (const collectionName of ['master_categories', 'master_products']) {
    const { scanned, migrated } = await migrateCollection(collectionName)
    console.log(`${collectionName}: ${scanned} docs scanned, ${migrated} ${apply ? 'migrated' : 'would be migrated'}`)
  }

  console.log(apply ? '\nDone.\n' : '\nRe-run with --apply to commit these changes.\n')
}

main().catch((err) => {
  console.error('\nFailed:', err.message ?? err)
  process.exit(1)
})
