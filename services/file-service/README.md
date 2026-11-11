# Mali Up File Service

Cloudflare Worker + R2 bucket (`maliup-files`) that stores the app's photos.
It replaces Firebase Storage. The mobile app uploads through
`apps/mobile-app/lib/core/services/file_upload_service.dart`.

| Route | Auth | Purpose |
|---|---|---|
| `POST /v1/files?kind=logo\|receipt\|return` | Firebase ID token | Upload a JPEG/PNG/WebP (≤ 5 MB). Returns `{ key, url }` |
| `GET /f/<key>` | none | Serves the photo. The key contains a random UUID, so the URL works like a Firebase download URL |
| `PUT /admin/objects/legacy/<key>` | `MIGRATION_TOKEN` secret | Only used by `scripts/migrate-storage-to-r2.ts` |

Keys: `logos|receipts|returns/<uid>/<uuid>.<ext>`. Photos copied from Firebase are under `legacy/`.

## Deploy

```bash
npm install
npx wrangler r2 bucket create maliup-files
npx wrangler deploy          # also creates the maliup-files.neuraltale.com custom domain
```

## Move the old Firebase photos

```bash
npx wrangler secret put MIGRATION_TOKEN        # any long random string
cd ../../scripts
MIGRATION_TOKEN=... npm run migrate:r2:dry     # preview
MIGRATION_TOKEN=... npm run migrate:r2         # copy + rewrite Firestore URLs
cd ../services/file-service && npx wrangler secret delete MIGRATION_TOKEN
```

Keep the Firebase bucket readable for a few weeks after the migration. App
builds from before the switch still upload there, and devices pick up the
rewritten URLs only on their next sync.

Part of the [Mali Up](../../README.md) suite.
