'use strict';
/**
 * backfill-catalog-images.ts — give every master-catalog product a picture
 * ─────────────────────────────────────────────────────────────────────────────
 * Walks `master_products`, finds or makes a picture for every doc that has no
 * `imageUrl`, stores it in R2 (through services/file-service), and writes the
 * URL back to the doc. The mobile app caches `imageUrl` with the rest of the
 * catalog and copies it into inventory when a product is imported, so no
 * picture ever has to be set by hand.
 *
 * Where each picture comes from (--source, default `auto`):
 *   1. Open Food Facts — if the product has a barcode (`commonBarcodes`) and
 *      OFF knows it, its real front-of-pack photo (free, no key, CC BY-SA).
 *   2. Cloudflare Workers AI (FLUX.1 schnell) — everything else: a generated,
 *      consistent white-background product shot (or a plated dish / simple
 *      illustration for restaurants and services). Works for 100% of the
 *      catalog: generic drugs, loose produce, dishes, services.
 *
 * Every picture is resized to 512×512 WebP (~20–40 KB) before upload, so POS
 * grids stay light on mobile data. The R2 key carries a content hash —
 * catalog/<docId>-<hash>.webp — so a replaced picture gets a new URL and the
 * year-long immutable cache never serves a stale one.
 *
 * Docs with `imageSource: 'manual'` (a picture an admin chose) are never
 * touched, even with --force.
 *
 * --inventory  also back-fills existing businesses: inventory items with no
 *   picture whose name exactly matches a catalog product (case-insensitive)
 *   get that product's imageUrl, with `updatedAt` bumped so every device's
 *   sync pull delivers it.
 *
 * ── Setup ───────────────────────────────────────────────────────────────────
 *   1. Service account: scripts/serviceAccountKey.json or
 *      service-account.json in the repo root (same as the other scripts).
 *   2. Deploy services/file-service (it must accept the catalog/ prefix), then
 *        cd services/file-service && npx wrangler secret put MIGRATION_TOKEN
 *      and export MIGRATION_TOKEN="<same value>".
 *   3. Cloudflare API token with the "Workers AI: Read" permission:
 *        export CF_ACCOUNT_ID="<account id>"
 *        export CF_API_TOKEN="<token>"
 *
 * ── Usage ───────────────────────────────────────────────────────────────────
 *   npm run images:count                 # how many products lack a picture
 *   npm run images:dry -- --limit 10     # build 10 pictures into
 *                                        # scripts/catalog-image-preview/,
 *                                        # upload/write NOTHING — eyeball them
 *   npm run images                       # do the whole catalog
 *   npm run images -- --inventory        # …and back-fill existing inventory
 *
 *   --limit N        only the first N candidates
 *   --only <docId>   just this product (combine with --force to redo it)
 *   --force          redo products that already have a (non-manual) picture
 *   --source auto|ai|off   picture source (default auto = OFF, then AI)
 *   --concurrency N  parallel products (default 3)
 *   --files-url URL  non-default file-service Worker
 *
 * When done: `npx wrangler secret delete MIGRATION_TOKEN`.
 */
import * as admin from 'firebase-admin';
import * as crypto from 'crypto';
import * as fs from 'fs';
import * as path from 'path';
import sharp from 'sharp';

// ─── Firebase init (mirrors the other scripts) ──────────────────────────────
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
const COUNT_ONLY = process.argv.includes('--count-only');
const FORCE = process.argv.includes('--force');
const DO_INVENTORY = process.argv.includes('--inventory');
const LIMIT = Number(flagValue('--limit') ?? '0'); // 0 = no limit
const ONLY = flagValue('--only');
const SOURCE = (flagValue('--source') ?? 'auto') as 'auto' | 'ai' | 'off';
const CONCURRENCY = Math.max(1, Number(flagValue('--concurrency') ?? '3'));
const FILES_URL = (flagValue('--files-url') ?? 'https://maliup-files.neuraltale.com').replace(/\/+$/, '');

const MIGRATION_TOKEN = process.env.MIGRATION_TOKEN ?? '';
const CF_ACCOUNT_ID = process.env.CF_ACCOUNT_ID ?? '';
const CF_API_TOKEN = process.env.CF_API_TOKEN ?? '';
const AI_MODEL = '@cf/black-forest-labs/flux-1-schnell';
const PREVIEW_DIR = path.join(__dirname, 'catalog-image-preview');
const SIZE = 512;

if (!['auto', 'ai', 'off'].includes(SOURCE)) {
  console.error('❌ --source must be auto, ai or off.');
  process.exit(1);
}
if (!COUNT_ONLY) {
  if (SOURCE !== 'off' && (!CF_ACCOUNT_ID || !CF_API_TOKEN)) {
    console.error('❌ Set CF_ACCOUNT_ID and CF_API_TOKEN (Workers AI), or pass --source off.');
    process.exit(1);
  }
  if (!DRY_RUN && !MIGRATION_TOKEN) {
    console.error('❌ Set MIGRATION_TOKEN (same value as the file-service secret), or pass --dry-run.');
    process.exit(1);
  }
}

// ─── Prompt styles ──────────────────────────────────────────────────────────
// Catalog businessTypes values (see _catalogTypeNames in the app's
// master_catalog_repository.dart) whose items are dishes or services rather
// than shelf products.
const FOOD_TYPES = new Set(['Restaurant', 'Cafe & Bakery', 'Street Food', 'Catering']);
const SERVICE_TYPES = new Set([
  'Education & Training', 'Real Estate', 'Financial Services', 'ICT & Software',
  'Entertainment & Events', 'Cleaning Services', 'Security Services',
  'NGO & Community Services', 'Media & Communications', 'Travel & Tours',
  'Hotel & Accommodation', 'Salon & Barber', 'Auto Repair',
  'Transportation & Logistics', 'Clinic & Laboratory',
]);

type Product = {
  id: string;
  name: string;
  generic: string;
  brand: string;
  barcodes: string[];
  businessTypes: string[];
};

function promptFor(p: Product): string {
  const what = [p.brand && !p.name.toLowerCase().includes(p.brand.toLowerCase()) ? p.brand : '', p.name]
    .filter(Boolean)
    .join(' ');
  const generic = p.generic && p.generic.toLowerCase() !== p.name.toLowerCase() ? ` (${p.generic})` : '';
  const types = p.businessTypes;
  const noText = 'no text, no words, no letters, no watermark, no logo';

  if (types.length > 0 && types.every((t) => FOOD_TYPES.has(t))) {
    return `Appetizing food photograph of ${what}${generic}, East African / Tanzanian style, served on a plain plate, ` +
      `top-down three-quarter view, centered, plain light background, soft natural light, ${noText}`;
  }
  if (types.length > 0 && types.every((t) => SERVICE_TYPES.has(t))) {
    return `Simple clean flat illustration representing "${what}"${generic}, single centered subject, ` +
      `navy and teal colour palette, plain white background, modern app icon style, ${noText}`;
  }
  return `Professional e-commerce product photo of ${what}${generic}, a single item as sold in a Tanzanian shop, ` +
    `centered, fills the frame, plain pure white background, soft studio lighting, sharp focus, ${noText}`;
}

// ─── Sources ────────────────────────────────────────────────────────────────
async function fromOpenFoodFacts(p: Product): Promise<Buffer | null> {
  for (const code of p.barcodes) {
    if (!/^\d{8,14}$/.test(code)) continue;
    try {
      const res = await fetch(
        `https://world.openfoodfacts.org/api/v2/product/${code}.json?fields=image_front_url,image_url`,
        { headers: { 'User-Agent': 'MaliUpCatalogBackfill/1.0' } },
      );
      if (!res.ok) continue;
      const data = (await res.json()) as { status?: number; product?: { image_front_url?: string; image_url?: string } };
      const url = data.product?.image_front_url || data.product?.image_url;
      if (data.status !== 1 || !url) continue;
      const img = await fetch(url);
      if (img.ok) return Buffer.from(await img.arrayBuffer());
    } catch {
      // try the next barcode / fall back to AI
    }
  }
  return null;
}

async function fromWorkersAi(p: Product): Promise<Buffer> {
  const res = await fetch(
    `https://api.cloudflare.com/client/v4/accounts/${CF_ACCOUNT_ID}/ai/run/${AI_MODEL}`,
    {
      method: 'POST',
      headers: { Authorization: `Bearer ${CF_API_TOKEN}`, 'Content-Type': 'application/json' },
      // Deterministic seed per product: a re-run regenerates the same picture.
      body: JSON.stringify({ prompt: promptFor(p), steps: 6, seed: seedFor(p.id) }),
    },
  );
  const body = (await res.json().catch(() => ({}))) as { result?: { image?: string }; errors?: unknown };
  if (!res.ok || !body.result?.image) {
    throw new Error(`Workers AI ${res.status}: ${JSON.stringify(body.errors ?? body).slice(0, 300)}`);
  }
  return Buffer.from(body.result.image, 'base64');
}

function seedFor(id: string): number {
  return crypto.createHash('sha256').update(id).digest().readUInt32BE(0) % 2147483647;
}

// ─── Upload ─────────────────────────────────────────────────────────────────
async function toWebp(raw: Buffer): Promise<Buffer> {
  return sharp(raw)
    .resize(SIZE, SIZE, { fit: 'contain', background: '#ffffff' })
    .flatten({ background: '#ffffff' })
    .webp({ quality: 78 })
    .toBuffer();
}

async function upload(key: string, bytes: Buffer): Promise<string> {
  const res = await fetch(`${FILES_URL}/admin/objects/${key}`, {
    method: 'PUT',
    headers: { Authorization: `Bearer ${MIGRATION_TOKEN}`, 'Content-Type': 'image/webp' },
    body: bytes,
  });
  const body = (await res.json().catch(() => ({}))) as { url?: string; error?: string };
  if (!res.ok || !body.url) throw new Error(`upload ${res.status}: ${body.error ?? 'no url'}`);
  return body.url;
}

// ─── Main ───────────────────────────────────────────────────────────────────
function strList(v: unknown): string[] {
  return Array.isArray(v) ? v.map((e) => String(e)).filter(Boolean) : [];
}

async function main() {
  const snap = ONLY
    ? await db.collection('master_products').where(admin.firestore.FieldPath.documentId(), '==', ONLY).get()
    : await db.collection('master_products').get();

  const candidates: Product[] = [];
  for (const doc of snap.docs) {
    const d = doc.data();
    if (d.imageSource === 'manual') continue;
    if (!FORCE && typeof d.imageUrl === 'string' && d.imageUrl.trim()) continue;
    candidates.push({
      id: doc.id,
      name: String(d.productName ?? '').trim(),
      generic: String(d.genericName ?? '').trim(),
      brand: strList(d.brandNames)[0] ?? '',
      barcodes: strList(d.commonBarcodes),
      businessTypes: strList(d.businessTypes),
    });
  }
  const todo = candidates.filter((p) => p.name).slice(0, LIMIT > 0 ? LIMIT : undefined);

  console.log(`📦 ${snap.size} catalog products · ${candidates.length} without a picture · doing ${todo.length}`);
  if (COUNT_ONLY) return;
  if (DRY_RUN) {
    fs.mkdirSync(PREVIEW_DIR, { recursive: true });
    console.log(`🧪 Dry run — pictures go to ${PREVIEW_DIR}, nothing is uploaded or written.`);
  }

  let ok = 0;
  let failed = 0;
  const stats = { openfoodfacts: 0, ai: 0 };

  async function handle(p: Product) {
    try {
      let raw: Buffer | null = null;
      let source = '';
      if (SOURCE !== 'ai') {
        raw = await fromOpenFoodFacts(p);
        if (raw) source = 'openfoodfacts';
      }
      if (!raw && SOURCE !== 'off') {
        raw = await fromWorkersAi(p);
        source = `ai:${AI_MODEL.split('/').pop()}`;
      }
      if (!raw) {
        console.log(`  · ${p.id} — no picture found (${p.name})`);
        return;
      }
      const webp = await toWebp(raw);
      const hash = crypto.createHash('sha256').update(webp).digest('hex').slice(0, 10);
      const key = `catalog/${p.id.replace(/[^A-Za-z0-9_-]/g, '_')}-${hash}.webp`;

      if (DRY_RUN) {
        fs.writeFileSync(path.join(PREVIEW_DIR, path.basename(key)), webp);
      } else {
        const url = await upload(key, webp);
        await db.collection('master_products').doc(p.id).set(
          {
            imageUrl: url,
            imageSource: source,
            imageUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
          },
          { merge: true },
        );
      }
      source === 'openfoodfacts' ? stats.openfoodfacts++ : stats.ai++;
      ok++;
      console.log(`  ✓ ${p.id} [${source}] ${p.name} (${Math.round(webp.length / 1024)} KB)`);
    } catch (e) {
      failed++;
      console.error(`  ✗ ${p.id} ${p.name}: ${(e as Error).message}`);
    }
  }

  // Small worker pool — Workers AI rate-limits bursts.
  let next = 0;
  await Promise.all(
    Array.from({ length: Math.min(CONCURRENCY, todo.length) }, async () => {
      while (next < todo.length) await handle(todo[next++]);
    }),
  );

  console.log(`\n✅ ${ok} pictures (${stats.openfoodfacts} Open Food Facts, ${stats.ai} AI) · ❌ ${failed} failed`);
  if (failed > 0) console.log('   Re-run the same command to retry just the failures.');

  if (DO_INVENTORY) await backfillInventory();
}

/** Copies catalog pictures onto existing inventory items matched by name. */
async function backfillInventory() {
  console.log('\n🏪 Back-filling existing inventory by product name…');
  const byName = new Map<string, string>();
  const all = await db.collection('master_products').get();
  for (const doc of all.docs) {
    const d = doc.data();
    const url = typeof d.imageUrl === 'string' ? d.imageUrl.trim() : '';
    const name = String(d.productName ?? '').trim().toLowerCase();
    if (url && name && !byName.has(name)) byName.set(name, url);
  }

  const items = await db.collectionGroup('inventory_items').get();
  let writer = db.batch();
  let pending = 0;
  let matched = 0;
  for (const doc of items.docs) {
    const d = doc.data();
    if (typeof d.imageUrl === 'string' && d.imageUrl.trim()) continue;
    const url = byName.get(String(d.name ?? '').trim().toLowerCase());
    if (!url) continue;
    matched++;
    if (DRY_RUN) continue;
    writer.update(doc.ref, { imageUrl: url, updatedAt: admin.firestore.FieldValue.serverTimestamp() });
    if (++pending >= 400) {
      await writer.commit();
      writer = db.batch();
      pending = 0;
    }
  }
  if (pending > 0) await writer.commit();
  console.log(`   ${matched} of ${items.size} inventory items ${DRY_RUN ? 'would get' : 'got'} a picture.`);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
