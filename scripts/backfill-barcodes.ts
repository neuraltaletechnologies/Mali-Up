'use strict';
/**
 * backfill-barcodes.ts — one-time / repeatable backfill
 * ─────────────────────────────────────────────────────────────────────────────
 * Every doc in `master_products` ships with `commonBarcodes: []`. The mobile
 * import flow (import_product_screen.dart, inventory_screen.dart) already
 * pre-fills a product's SKU / barcode field from `commonBarcodes.first`, so
 * once this array is populated every catalog import carries a real, scannable
 * EAN/UPC code — no app change needed.
 *
 * This script walks `master_products`, looks each product up against the
 * Barcode Lookup API (https://www.barcodelookup.com/api) by name + brand, and
 * writes the first real barcode it finds back to `commonBarcodes`.
 *
 * Matching is deliberately LENIENT — it takes the API's best match even when
 * the pack size or brand isn't a perfect fit. That's a product decision: more
 * products get a usable barcode at the cost of the occasional near-miss. The
 * business owner can always rescan / edit the SKU after import.
 *
 * ── Setup ───────────────────────────────────────────────────────────────────
 *   1. Service account: drop `serviceAccountKey.json` in this folder (same key
 *      the seed script uses), or `service-account.json` in the repo root.
 *   2. export BARCODE_API_KEY="<your Barcode Lookup API key>"
 *
 * ── Usage ───────────────────────────────────────────────────────────────────
 *   npm run backfill:barcodes:dry        # look products up, print, write NOTHING
 *   npm run backfill:barcodes            # look up + write commonBarcodes
 *
 *   ts-node backfill-barcodes.ts --limit 20      # only the first 20 candidates
 *   ts-node backfill-barcodes.ts --force         # re-look-up docs that already
 *                                                # have a barcode
 *   ts-node backfill-barcodes.ts --delay 400     # ms between API calls
 *                                                # (default 1100 ≈ the 1 req/sec
 *                                                #  free-tier limit; lower it on
 *                                                #  a paid plan)
 *   ts-node backfill-barcodes.ts --count-only    # just report how many docs
 *                                                # are missing a barcode, no API
 *
 * API responses are cached in `scripts/barcode-cache.json` (git-ignored) so a
 * re-run doesn't pay for the same lookups twice. Delete that file or pass
 * --force to bypass it.
 */

import * as admin from 'firebase-admin';
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
const FORCE = process.argv.includes('--force');
const COUNT_ONLY = process.argv.includes('--count-only');
const LIMIT = Number(flagValue('--limit') ?? '0'); // 0 = no limit
const DELAY_MS = Number(flagValue('--delay') ?? '1100'); // ≈ 1 req/sec free-tier cap
const BATCH_SIZE = 400;

const API_KEY = process.env.BARCODE_API_KEY ?? '';
const API_BASE = 'https://api.barcodelookup.com/v3/products';
const CACHE_FILE = path.join(__dirname, 'barcode-cache.json');

if (!COUNT_ONLY && !API_KEY) {
  console.error(
    '❌ Set the BARCODE_API_KEY environment variable to your Barcode Lookup API key.\n' +
      '   (Use --count-only to report missing barcodes without hitting the API.)',
  );
  process.exit(1);
}

// ─── Types ─────────────────────────────────────────────────────────────────
interface ProductDoc {
  productName?: string;
  genericName?: string;
  brandNames?: unknown;
  commonBarcodes?: unknown;
}

interface CacheEntry {
  barcode: string | null; // null = looked up, nothing found
  title: string;
  ts: number;
}
type Cache = Record<string, CacheEntry>;

// ─── Local cache ───────────────────────────────────────────────────────────
function loadCache(): Cache {
  try {
    return JSON.parse(fs.readFileSync(CACHE_FILE, 'utf8')) as Cache;
  } catch {
    return {};
  }
}
function saveCache(cache: Cache): void {
  try {
    fs.writeFileSync(CACHE_FILE, JSON.stringify(cache, null, 2));
  } catch (err) {
    console.warn('⚠  could not write cache file:', (err as Error).message);
  }
}

// ─── Helpers ───────────────────────────────────────────────────────────────
const sleep = (ms: number) => new Promise((r) => setTimeout(r, ms));

function firstBrand(raw: unknown): string {
  if (Array.isArray(raw) && raw.length > 0 && typeof raw[0] === 'string') {
    return raw[0].trim();
  }
  return '';
}

function hasBarcode(raw: unknown): boolean {
  return (
    Array.isArray(raw) &&
    raw.some((x) => typeof x === 'string' && /\d/.test(x) && x.trim().length > 0)
  );
}

/** Ordered list of search strings to try, most specific first. */
function buildQueries(p: ProductDoc): string[] {
  const name = (p.productName ?? '').trim();
  const brand = firstBrand(p.brandNames);
  const generic = (p.genericName ?? '').trim();

  // Drop parenthetical notes and Swahili pack words that confuse keyword search
  // e.g. "Rice (Mwea Pishori) 5kg" → "Rice 5kg"
  const cleanName = name
    .replace(/\([^)]*\)/g, ' ')
    .replace(/\b(kesi|roli|roll|pakiti|pack|case|tray|trei)\b/gi, ' ')
    .replace(/\s+/g, ' ')
    .trim();

  const queries = [
    brand && name ? `${brand} ${name}` : '',
    cleanName,
    brand && generic ? `${brand} ${generic}` : '',
    generic,
  ]
    .map((q) => q.trim())
    .filter(Boolean);

  return [...new Set(queries)];
}

/**
 * Queries the Barcode Lookup API. Returns the first product whose
 * `barcode_number` is a plausible 8–14 digit EAN/UPC, or null.
 */
async function lookup(query: string): Promise<{ barcode: string; title: string } | null> {
  // `search` matches against product name, brand, manufacturer, MPN and category.
  const url = `${API_BASE}?search=${encodeURIComponent(query)}&key=${API_KEY}`;

  for (let attempt = 0; attempt < 4; attempt++) {
    let res: Response;
    try {
      res = await fetch(url);
    } catch (err) {
      // transient network error — back off and retry
      await sleep(1500 * (attempt + 1));
      continue;
    }

    if (res.status === 429) {
      await sleep(2500 * (attempt + 1));
      continue;
    }
    // 404 = "no product found for this search" per the API docs
    if (res.status === 404) return null;
    if (res.status === 401 || res.status === 403) {
      throw new Error(`Barcode API rejected the key (HTTP ${res.status}). Check BARCODE_API_KEY.`);
    }
    if (!res.ok) {
      const body = await res.text().catch(() => '');
      throw new Error(`Barcode API HTTP ${res.status}: ${body.slice(0, 200)}`);
    }

    const json = (await res.json()) as { products?: Array<Record<string, unknown>> };
    const products = json.products ?? [];
    for (const prod of products) {
      const code = String(prod.barcode_number ?? '').replace(/\s+/g, '').trim();
      if (/^\d{8,14}$/.test(code)) {
        return { barcode: code, title: String(prod.title ?? '') };
      }
    }
    return null;
  }
  throw new Error(`Barcode API: gave up after repeated throttling for "${query}"`);
}

// ─── Main ──────────────────────────────────────────────────────────────────
async function main(): Promise<void> {
  console.log(
    `\n🔎 Backfilling master_products barcodes` +
      `${DRY_RUN ? ' (DRY RUN — no writes)' : ''}` +
      `${FORCE ? ' (FORCE — re-looking-up existing)' : ''}\n`,
  );

  const snap = await db.collection('master_products').get();
  const targets = snap.docs.filter((d) => FORCE || !hasBarcode((d.data() as ProductDoc).commonBarcodes));

  console.log(`   master_products docs : ${snap.size}`);
  console.log(`   missing a barcode    : ${snap.docs.filter((d) => !hasBarcode((d.data() as ProductDoc).commonBarcodes)).length}`);
  console.log(`   will process         : ${LIMIT > 0 ? Math.min(LIMIT, targets.length) : targets.length}\n`);

  if (COUNT_ONLY) return;

  const queue = LIMIT > 0 ? targets.slice(0, LIMIT) : targets;
  const cache = FORCE ? {} : loadCache();

  let apiCalls = 0;
  let found = 0;
  let notFound = 0;
  let processed = 0;

  // ref → barcode, flushed to Firestore in batches
  const updates: { ref: FirebaseFirestore.DocumentReference; barcode: string }[] = [];

  for (const doc of queue) {
    processed++;
    const data = doc.data() as ProductDoc;
    const queries = buildQueries(data);
    if (queries.length === 0) {
      notFound++;
      continue;
    }

    let hit: { barcode: string; title: string } | null = null;
    for (const q of queries) {
      const key = q.toLowerCase();
      if (key in cache) {
        const cached = cache[key];
        if (cached.barcode) hit = { barcode: cached.barcode, title: cached.title };
      } else {
        if (apiCalls > 0) await sleep(DELAY_MS);
        apiCalls++;
        try {
          hit = await lookup(q);
        } catch (err) {
          console.error(`\n✗ ${(err as Error).message}\n`);
          saveCache(cache);
          if (updates.length) await flush(updates);
          process.exit(1);
        }
        cache[key] = {
          barcode: hit?.barcode ?? null,
          title: hit?.title ?? '',
          ts: Date.now(),
        };
        if (apiCalls % 50 === 0) saveCache(cache);
      }
      if (hit) break;
    }

    if (hit) {
      found++;
      updates.push({ ref: doc.ref, barcode: hit.barcode });
      console.log(
        `  ✓ ${(data.productName ?? doc.id).padEnd(42).slice(0, 42)} → ${hit.barcode}` +
          `${hit.title ? `  (${hit.title.slice(0, 40)})` : ''}`,
      );
    } else {
      notFound++;
      console.log(`  · ${(data.productName ?? doc.id).padEnd(42).slice(0, 42)} → no match`);
    }

    if (processed % 25 === 0) {
      console.log(`    …${processed}/${queue.length}  (found ${found}, none ${notFound}, api ${apiCalls})`);
    }

    if (!DRY_RUN && updates.length >= BATCH_SIZE) {
      await flush(updates.splice(0, updates.length));
    }
  }

  saveCache(cache);
  if (!DRY_RUN && updates.length) await flush(updates);

  console.log('\n═══════════════════════════════════');
  console.log(DRY_RUN ? '✅ Dry run complete' : '✅ Backfill complete');
  console.log(`   Processed   : ${processed}`);
  console.log(`   Barcodes    : ${found} found, ${notFound} without a match`);
  console.log(`   API calls   : ${apiCalls}`);
  if (DRY_RUN) console.log('   (no Firestore writes — re-run without --dry-run to apply)');
  console.log('═══════════════════════════════════\n');
}

/** Commits a group of commonBarcodes updates. */
async function flush(
  group: { ref: FirebaseFirestore.DocumentReference; barcode: string }[],
): Promise<void> {
  let batch = db.batch();
  let n = 0;
  for (const { ref, barcode } of group) {
    batch.update(ref, {
      commonBarcodes: [barcode],
      commonBarcodesSource: 'barcodelookup-api',
      updatedAt: new Date(),
    });
    if (++n >= BATCH_SIZE) {
      await batch.commit();
      batch = db.batch();
      n = 0;
    }
  }
  if (n > 0) await batch.commit();
  console.log(`    ↳ wrote ${group.length} docs`);
}

main().catch((err) => {
  console.error('Fatal error:', err);
  process.exit(1);
});
