'use strict';
/**
 * migrate-storage-to-r2.ts — copy existing photos from Firebase Storage to
 * Cloudflare R2 and repoint the saved URLs.
 * ─────────────────────────────────────────────────────────────────────────────
 * New uploads already go to R2 (apps/mobile-app/lib/core/services/
 * file_upload_service.dart → services/file-service). This script moves the
 * photos uploaded before that switch:
 *
 *   businesses.logoUrl          (business logos)
 *   expenses.receiptUrl         (expense receipts — any path, collection group)
 *   credit_notes.proofPhotoUrl  (sales-return proof photos)
 *   users.logoUrl               (legacy profile copies of the logo, if any)
 *
 * For every doc whose field still holds a Firebase Storage URL it:
 *   1. downloads the object with the Admin SDK,
 *   2. uploads it through the Worker's PUT /admin/objects/legacy/<key>,
 *   3. rewrites the field to the new R2 URL and bumps `updatedAt`, so the
 *      app's sync pull (watermarked on updatedAt) delivers the new URL to
 *      every device's local Drift copy.
 *
 * The new key is legacy/<sha256(bucket/path|downloadToken)>.<ext>: stable, so
 * re-runs are idempotent, and unguessable, because the old download token
 * (secret, part of the old URL) is hashed in. Old URLs keep working until you
 * lock or delete the Firebase bucket.
 *
 * ── Setup ───────────────────────────────────────────────────────────────────
 *   1. Service account: `scripts/serviceAccountKey.json` or
 *      `service-account.json` in the repo root (same as the other scripts).
 *   2. In services/file-service:  npx wrangler secret put MIGRATION_TOKEN
 *   3. export MIGRATION_TOKEN="<same value>"
 *
 * ── Usage ───────────────────────────────────────────────────────────────────
 *   npm run migrate:r2:dry     # list what would move, write NOTHING
 *   npm run migrate:r2         # copy + rewrite
 *   ts-node migrate-storage-to-r2.ts --files-url https://...  # non-default Worker
 *
 * When done: `npx wrangler secret delete MIGRATION_TOKEN`.
 */
import * as admin from 'firebase-admin';
import * as crypto from 'crypto';
import * as fs from 'fs';
import * as path from 'path';

// ─── Firebase init (mirrors seed-master-catalog.ts) ─────────────────────────
const SA_PATHS = [
  path.join(__dirname, 'serviceAccountKey.json'),
  path.join(__dirname, '../service-account.json'),
];
let sa: Record<string, unknown> | null = null;
for (const p of SA_PATHS) {
  if (fs.existsSync(p)) {
    sa = require(p);
    break;
  }
}
if (!sa) {
  console.error('❌ No service account found. Looked in:\n' + SA_PATHS.join('\n'));
  process.exit(1);
}
admin.initializeApp({ credential: admin.credential.cert(sa as admin.ServiceAccount) });
const db = admin.firestore();

// ─── CLI flags / config ────────────────────────────────────────────────────
function flagValue(name: string): string | undefined {
  const i = process.argv.indexOf(name);
  return i >= 0 ? process.argv[i + 1] : undefined;
}
const DRY_RUN = process.argv.includes('--dry-run');
const FILES_URL = (flagValue('--files-url') ?? 'https://maliup-files.neuraltale.com').replace(/\/+$/, '');
const MIGRATION_TOKEN = process.env.MIGRATION_TOKEN ?? '';
if (!DRY_RUN && !MIGRATION_TOKEN) {
  console.error('❌ Set MIGRATION_TOKEN (same value as the Worker secret), or pass --dry-run.');
  process.exit(1);
}

const TARGETS: { group: string; field: string }[] = [
  { group: 'businesses', field: 'logoUrl' },
  { group: 'users', field: 'logoUrl' },
  { group: 'expenses', field: 'receiptUrl' },
  { group: 'credit_notes', field: 'proofPhotoUrl' },
];

// ─── Firebase URL parsing ──────────────────────────────────────────────────
interface FirebaseObjectRef {
  bucket: string;
  objectPath: string;
  token: string;
}

function parseFirebaseUrl(raw: string): FirebaseObjectRef | null {
  let u: URL;
  try {
    u = new URL(raw);
  } catch {
    return null;
  }
  // https://firebasestorage.googleapis.com/v0/b/<bucket>/o/<encoded path>?alt=media&token=<t>
  if (u.hostname === 'firebasestorage.googleapis.com') {
    const m = u.pathname.match(/^\/v0\/b\/([^/]+)\/o\/(.+)$/);
    if (!m) return null;
    return { bucket: m[1], objectPath: decodeURIComponent(m[2]), token: u.searchParams.get('token') ?? '' };
  }
  // https://storage.googleapis.com/<bucket>/<path>
  if (u.hostname === 'storage.googleapis.com') {
    const m = u.pathname.match(/^\/([^/]+)\/(.+)$/);
    if (!m) return null;
    return { bucket: m[1], objectPath: decodeURIComponent(m[2]), token: '' };
  }
  return null;
}

function extFor(objectPath: string, contentType: string): string {
  if (contentType === 'image/png') return '.png';
  if (contentType === 'image/webp') return '.webp';
  if (contentType === 'image/jpeg') return '.jpg';
  const ext = path.extname(objectPath).toLowerCase();
  return /^\.[a-z0-9]{1,5}$/.test(ext) ? ext : '.jpg';
}

// ─── Copy one object (memoised per old URL) ────────────────────────────────
const copied = new Map<string, Promise<string | null>>();

function copyObject(oldUrl: string, ref: FirebaseObjectRef): Promise<string | null> {
  let p = copied.get(oldUrl);
  if (!p) {
    p = doCopy(ref);
    copied.set(oldUrl, p);
  }
  return p;
}

async function doCopy(ref: FirebaseObjectRef): Promise<string | null> {
  const file = admin.storage().bucket(ref.bucket).file(ref.objectPath);
  const [exists] = await file.exists();
  if (!exists) {
    console.warn(`   ⚠️  missing in Firebase Storage: ${ref.bucket}/${ref.objectPath}`);
    return null;
  }
  const [meta] = await file.getMetadata();
  const contentType = String(meta.contentType ?? 'image/jpeg');
  const hash = crypto
    .createHash('sha256')
    .update(`${ref.bucket}/${ref.objectPath}|${ref.token}`)
    .digest('hex')
    .slice(0, 32);
  const key = `legacy/${hash}${extFor(ref.objectPath, contentType)}`;
  const newUrl = `${FILES_URL}/f/${key}`;
  if (DRY_RUN) return newUrl;

  const [bytes] = await file.download();
  const res = await fetch(`${FILES_URL}/admin/objects/${key}`, {
    method: 'PUT',
    headers: { Authorization: `Bearer ${MIGRATION_TOKEN}`, 'Content-Type': contentType },
    body: new Uint8Array(bytes),
  });
  if (!res.ok) {
    throw new Error(`Worker PUT ${key} failed: ${res.status} ${await res.text()}`);
  }
  return newUrl;
}

// ─── Main ──────────────────────────────────────────────────────────────────
async function main(): Promise<void> {
  console.log(`${DRY_RUN ? '🔎 DRY RUN — ' : ''}Migrating Firebase Storage photos → ${FILES_URL}\n`);
  let rewritten = 0;
  let skipped = 0;
  let failed = 0;

  for (const { group, field } of TARGETS) {
    const snap = await db.collectionGroup(group).get();
    const candidates = snap.docs.filter((d) => {
      const v = d.get(field);
      return typeof v === 'string' && parseFirebaseUrl(v) !== null;
    });
    console.log(`📂 ${group}.${field}: ${candidates.length} of ${snap.size} docs point at Firebase Storage`);

    for (const doc of candidates) {
      const oldUrl = doc.get(field) as string;
      const ref = parseFirebaseUrl(oldUrl)!;
      try {
        const newUrl = await copyObject(oldUrl, ref);
        if (!newUrl) {
          skipped++;
          continue;
        }
        console.log(`   ${doc.ref.path}\n     ${ref.objectPath} → ${newUrl}`);
        if (!DRY_RUN) {
          await doc.ref.update({
            [field]: newUrl,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
        }
        rewritten++;
      } catch (err) {
        failed++;
        console.error(`   ❌ ${doc.ref.path}: ${(err as Error).message}`);
      }
    }
  }

  console.log(
    `\n${DRY_RUN ? 'Would rewrite' : 'Rewrote'} ${rewritten} doc(s); ${skipped} skipped (object missing); ${failed} failed.`,
  );
  if (failed > 0) process.exitCode = 1;
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
