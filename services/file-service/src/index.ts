/**
 * Mali Up file service — Cloudflare Worker in front of the `maliup-files` R2
 * bucket. Replaces Firebase Storage for the app's photo uploads (business
 * logos, expense receipts, sales-return proof photos).
 *
 *   POST /v1/files?kind=logo|receipt|return
 *        Authorization: Bearer <Firebase ID token>
 *        Content-Type: image/jpeg | image/png | image/webp
 *        body: raw image bytes (max 5 MB)
 *     → 201 { key, url }
 *
 *   GET|HEAD /f/<key>
 *     → the object. Public, like a Firebase download URL: the key carries a
 *       random UUID, so the URL itself is the capability. That keeps every
 *       existing `Image.network(url)` / PDF-logo fetch in the app working
 *       unchanged.
 *
 *   PUT /admin/objects/legacy/<name>
 *        Authorization: Bearer <MIGRATION_TOKEN secret>
 *     → used only by scripts/migrate-storage-to-r2.ts to copy the old
 *       Firebase Storage objects across. Disabled unless the secret is set.
 */
import { createRemoteJWKSet, jwtVerify } from 'jose';

export interface Env {
  FILES: R2Bucket;
  FIREBASE_PROJECT_ID: string;
  PUBLIC_BASE_URL: string;
  MIGRATION_TOKEN?: string;
}

const MAX_BYTES = 5 * 1024 * 1024;

/** Upload kind (query param) → top-level key prefix. */
const KIND_PREFIX: Record<string, string> = {
  logo: 'logos',
  receipt: 'receipts',
  return: 'returns',
};

const EXT_FOR_TYPE: Record<string, string> = {
  'image/jpeg': '.jpg',
  'image/png': '.png',
  'image/webp': '.webp',
};

// Firebase ID tokens are signed by this Google service account. jose caches
// the key set per isolate and refetches on an unknown `kid`.
const FIREBASE_JWKS = createRemoteJWKSet(
  new URL(
    'https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com',
  ),
);

const CORS_HEADERS: Record<string, string> = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, HEAD, POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Authorization, Content-Type',
  'Access-Control-Max-Age': '86400',
};

export default {
  async fetch(request: Request, env: Env, ctx: ExecutionContext): Promise<Response> {
    const url = new URL(request.url);
    try {
      if (request.method === 'OPTIONS') {
        return new Response(null, { status: 204, headers: CORS_HEADERS });
      }
      if (url.pathname === '/v1/files' && request.method === 'POST') {
        return await handleUpload(request, env, url);
      }
      if (url.pathname.startsWith('/f/') && (request.method === 'GET' || request.method === 'HEAD')) {
        return await handleGet(request, env, ctx, decodeURIComponent(url.pathname.slice(3)));
      }
      if (url.pathname.startsWith('/admin/objects/') && request.method === 'PUT') {
        return await handleAdminPut(request, env, decodeURIComponent(url.pathname.slice('/admin/objects/'.length)));
      }
      if (url.pathname === '/health') return json({ ok: true });
      return json({ error: 'not-found' }, 404);
    } catch (err) {
      console.error('file-service error', err);
      return json({ error: 'internal' }, 500);
    }
  },
} satisfies ExportedHandler<Env>;

async function handleUpload(request: Request, env: Env, url: URL): Promise<Response> {
  const uid = await verifyFirebaseUser(request, env);
  if (!uid) return json({ error: 'unauthenticated' }, 401);

  const prefix = KIND_PREFIX[url.searchParams.get('kind') ?? ''];
  if (!prefix) return json({ error: 'invalid-kind' }, 400);

  const contentType = (request.headers.get('Content-Type') ?? '').split(';')[0].trim().toLowerCase();
  const ext = EXT_FOR_TYPE[contentType];
  if (!ext) return json({ error: 'unsupported-type' }, 415);

  const declared = Number(request.headers.get('Content-Length') ?? '0');
  if (declared > MAX_BYTES) return json({ error: 'too-large' }, 413);

  const body = new Uint8Array(await request.arrayBuffer());
  if (body.byteLength === 0) return json({ error: 'empty' }, 400);
  if (body.byteLength > MAX_BYTES) return json({ error: 'too-large' }, 413);
  if (!matchesImageSignature(body, contentType)) return json({ error: 'not-an-image' }, 415);

  const key = `${prefix}/${uid}/${crypto.randomUUID()}${ext}`;
  await env.FILES.put(key, body, {
    httpMetadata: { contentType, cacheControl: 'public, max-age=31536000, immutable' },
    customMetadata: { uid },
  });

  return json({ key, url: publicUrl(env, key) }, 201);
}

async function handleGet(request: Request, env: Env, ctx: ExecutionContext, key: string): Promise<Response> {
  if (!key || key.includes('..')) return json({ error: 'not-found' }, 404);

  const cache = caches.default;
  const cacheKey = new Request(new URL(request.url).toString(), { method: 'GET' });
  if (request.method === 'GET') {
    const hit = await cache.match(cacheKey);
    if (hit) return hit;
  }

  const object = request.method === 'HEAD' ? await env.FILES.head(key) : await env.FILES.get(key);
  if (!object) return json({ error: 'not-found' }, 404);

  const headers = new Headers(CORS_HEADERS);
  object.writeHttpMetadata(headers);
  headers.set('ETag', object.httpEtag);
  headers.set('X-Content-Type-Options', 'nosniff');
  if (!headers.has('Cache-Control')) headers.set('Cache-Control', 'public, max-age=31536000, immutable');

  const body = 'body' in object ? (object as R2ObjectBody).body : null;
  const response = new Response(body, { headers });
  if (request.method === 'GET') ctx.waitUntil(cache.put(cacheKey, response.clone()));
  return response;
}

async function handleAdminPut(request: Request, env: Env, key: string): Promise<Response> {
  if (!env.MIGRATION_TOKEN) return json({ error: 'not-found' }, 404);
  const presented = bearerToken(request) ?? '';
  if (!timingSafeEqual(presented, env.MIGRATION_TOKEN)) return json({ error: 'unauthenticated' }, 401);
  if (!key.startsWith('legacy/') || key.includes('..')) return json({ error: 'invalid-key' }, 400);

  const contentType = request.headers.get('Content-Type') ?? 'application/octet-stream';
  const body = await request.arrayBuffer();
  await env.FILES.put(key, body, {
    httpMetadata: { contentType, cacheControl: 'public, max-age=31536000, immutable' },
    customMetadata: { source: 'firebase-storage' },
  });
  return json({ key, url: publicUrl(env, key) }, 201);
}

/** Returns the Firebase uid for a valid ID token, or null. */
async function verifyFirebaseUser(request: Request, env: Env): Promise<string | null> {
  const token = bearerToken(request);
  if (!token) return null;
  try {
    const { payload } = await jwtVerify(token, FIREBASE_JWKS, {
      issuer: `https://securetoken.google.com/${env.FIREBASE_PROJECT_ID}`,
      audience: env.FIREBASE_PROJECT_ID,
      algorithms: ['RS256'],
    });
    const uid = typeof payload.sub === 'string' ? payload.sub : '';
    // Firebase uids are ≤128 chars; reject anything that could escape the key.
    return uid && uid.length <= 128 && !/[/\\]/.test(uid) ? uid : null;
  } catch {
    return null;
  }
}

function bearerToken(request: Request): string | null {
  const header = request.headers.get('Authorization') ?? '';
  return header.startsWith('Bearer ') ? header.slice(7).trim() || null : null;
}

/** Checks magic bytes so the public bucket can only ever hold real images. */
function matchesImageSignature(b: Uint8Array, contentType: string): boolean {
  switch (contentType) {
    case 'image/jpeg':
      return b.length > 3 && b[0] === 0xff && b[1] === 0xd8 && b[2] === 0xff;
    case 'image/png':
      return b.length > 8 && b[0] === 0x89 && b[1] === 0x50 && b[2] === 0x4e && b[3] === 0x47;
    case 'image/webp':
      return (
        b.length > 12 &&
        String.fromCharCode(b[0], b[1], b[2], b[3]) === 'RIFF' &&
        String.fromCharCode(b[8], b[9], b[10], b[11]) === 'WEBP'
      );
    default:
      return false;
  }
}

function timingSafeEqual(a: string, b: string): boolean {
  const enc = new TextEncoder();
  const x = enc.encode(a);
  const y = enc.encode(b);
  if (x.length !== y.length) return false;
  let diff = 0;
  for (let i = 0; i < x.length; i++) diff |= x[i] ^ y[i];
  return diff === 0;
}

function publicUrl(env: Env, key: string): string {
  const base = env.PUBLIC_BASE_URL.replace(/\/+$/, '');
  return `${base}/f/${key.split('/').map(encodeURIComponent).join('/')}`;
}

function json(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' },
  });
}
