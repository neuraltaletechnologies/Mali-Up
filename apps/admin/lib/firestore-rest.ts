import { importPKCS8, SignJWT } from 'jose'

/**
 * Firestore client backed directly by the Firestore REST API (plain
 * `fetch()`, plain JSON), authenticated with a self-signed service-account
 * JWT — no @google-cloud/firestore, no gRPC, no protobufjs.
 *
 * Why this exists: @google-cloud/firestore's own client (used by
 * `firebase-admin`) always routes reads/writes through protobufjs to
 * compile message encoders/decoders/verifiers (visible in error stacks as
 * `Codegen`/`Type.resolveAll`/`Namespace.resolveAll`), and protobufjs does
 * that with `new Function(source)` — dynamic code-eval that Cloudflare
 * Workers' V8 isolates block outright, with no compatibility flag to
 * re-enable it. That's true for gRPC *and* REST transport, so nothing in
 * `@google-cloud/firestore`'s own `settings({ preferRest: true })` can fix
 * it. A plain REST call with hand-rolled JSON encode/decode has no such
 * dependency and works identically in Workers and plain Node.
 *
 * This mirrors just the slice of the SDK's chainable API this codebase
 * actually uses: collection/doc get/set/update/delete, where/orderBy/limit
 * queries, collectionGroup, `.count()` aggregation, batched writes,
 * `recursiveDelete`, and the FieldValue sentinels (serverTimestamp/
 * increment/arrayUnion/arrayRemove/delete). No transactions, no query
 * cursors (startAfter/startAt), no realtime listeners — none of the 38
 * call sites migrated onto this use those.
 */

const PROJECT_ID = process.env.FIREBASE_PROJECT_ID ?? 'neuraltale-mali-up'
const DOCUMENTS_ROOT = `projects/${PROJECT_ID}/databases/(default)/documents`
const API_ROOT = 'https://firestore.googleapis.com/v1'

// ─────────────────────────── Auth ───────────────────────────────────────

// Self-signed JWT for calling Google APIs directly. Google accepts a service
// account's own RS256 JWT as a Bearer token (no token-endpoint round trip)
// when `aud` names the full gRPC service — see
// https://developers.google.com/identity/protocols/oauth2/service-account#jwt-auth.
// Cached per-isolate and refreshed a minute before expiry.
let cachedJwt: { token: string; exp: number } | null = null

async function getBearerToken(): Promise<string> {
  const now = Math.floor(Date.now() / 1000)
  if (cachedJwt && cachedJwt.exp - 60 > now) return cachedJwt.token

  const clientEmail = process.env.FIREBASE_CLIENT_EMAIL
  const rawPrivateKey = process.env.FIREBASE_PRIVATE_KEY
  if (!clientEmail || !rawPrivateKey) {
    throw new Error(
      'Missing FIREBASE_CLIENT_EMAIL or FIREBASE_PRIVATE_KEY — required for Firestore REST access.'
    )
  }

  const privateKey = await importPKCS8(rawPrivateKey.replace(/\\n/g, '\n'), 'RS256')
  const exp = now + 3600
  const token = await new SignJWT({})
    .setProtectedHeader({ alg: 'RS256' })
    .setIssuer(clientEmail)
    .setSubject(clientEmail)
    .setAudience('https://firestore.googleapis.com/google.firestore.v1.Firestore')
    .setIssuedAt(now)
    .setExpirationTime(exp)
    .sign(privateKey)

  cachedJwt = { token, exp }
  return token
}

async function firestoreFetch(pathAndVerb: string, init?: RequestInit): Promise<Response> {
  const token = await getBearerToken()
  try {
    return await fetch(`${API_ROOT}/${pathAndVerb}`, {
      ...init,
      headers: {
        Authorization: `Bearer ${token}`,
        'Content-Type': 'application/json',
        ...(init?.headers ?? {}),
      },
    })
  } catch (err) {
    // Cloudflare's log viewer has repeatedly shown these as stack-frames-only
    // with no visible message (console.error(label, err) renders blank where
    // err.message should be) — normalize to a guaranteed, visible message so
    // a future failure here is actually diagnosable from the dashboard.
    const reason = err instanceof Error ? err.message : String(err)
    throw new Error(`Firestore fetch to ${pathAndVerb} failed: ${reason}`)
  }
}

async function throwIfNotOk(res: Response, what: string): Promise<void> {
  if (!res.ok) {
    throw new Error(`Firestore REST ${what} failed: ${res.status} ${await res.text()}`)
  }
}

// ────────────────────────── Value codec ─────────────────────────────────

export class RestTimestamp {
  readonly seconds: number
  readonly nanoseconds: number
  readonly _seconds: number
  readonly _nanoseconds: number

  constructor(iso: string) {
    const ms = Date.parse(iso)
    this.seconds = Math.floor(ms / 1000)
    this.nanoseconds = (ms % 1000) * 1e6
    this._seconds = this.seconds
    this._nanoseconds = this.nanoseconds
  }

  toDate(): Date {
    return new Date(this.seconds * 1000 + this.nanoseconds / 1e6)
  }

  toMillis(): number {
    return this.seconds * 1000 + Math.round(this.nanoseconds / 1e6)
  }
}

type FieldValueKind = 'serverTimestamp' | 'increment' | 'arrayUnion' | 'arrayRemove' | 'delete'

class FieldValueSentinel {
  constructor(
    public readonly kind: FieldValueKind,
    public readonly value?: unknown
  ) {}
}

/** Drop-in for `firebase-admin/firestore`'s `FieldValue` sentinels. */
export const FieldValue = {
  serverTimestamp: (): FieldValueSentinel => new FieldValueSentinel('serverTimestamp'),
  increment: (n: number): FieldValueSentinel => new FieldValueSentinel('increment', n),
  arrayUnion: (...items: unknown[]): FieldValueSentinel => new FieldValueSentinel('arrayUnion', items),
  arrayRemove: (...items: unknown[]): FieldValueSentinel => new FieldValueSentinel('arrayRemove', items),
  delete: (): FieldValueSentinel => new FieldValueSentinel('delete'),
}

function encodeValue(v: unknown): any {
  if (v === null || v === undefined) return { nullValue: null }
  if (typeof v === 'boolean') return { booleanValue: v }
  if (typeof v === 'number') {
    return Number.isInteger(v) ? { integerValue: String(v) } : { doubleValue: v }
  }
  if (typeof v === 'string') return { stringValue: v }
  if (v instanceof Date) return { timestampValue: v.toISOString() }
  if (v instanceof RestTimestamp) return { timestampValue: v.toDate().toISOString() }
  if (Array.isArray(v)) return { arrayValue: { values: v.map(encodeValue) } }
  if (typeof v === 'object') {
    const fields: Record<string, any> = {}
    for (const [k, val] of Object.entries(v as Record<string, unknown>)) {
      if (val === undefined) continue // Firestore rejects undefined; SDK behaviour was "throws", callers already sanitize
      fields[k] = encodeValue(val)
    }
    return { mapValue: { fields } }
  }
  throw new Error(`Cannot encode Firestore value of type ${typeof v}`)
}

function decodeValue(v: any): unknown {
  if (!v) return null
  if ('nullValue' in v) return null
  if ('booleanValue' in v) return v.booleanValue
  if ('integerValue' in v) return Number(v.integerValue)
  if ('doubleValue' in v) return v.doubleValue
  if ('stringValue' in v) return v.stringValue
  if ('timestampValue' in v) return new RestTimestamp(v.timestampValue)
  if ('arrayValue' in v) return (v.arrayValue.values ?? []).map(decodeValue)
  if ('mapValue' in v) return decodeFields(v.mapValue.fields ?? {})
  if ('referenceValue' in v) return v.referenceValue
  if ('geoPointValue' in v) return v.geoPointValue
  if ('bytesValue' in v) return v.bytesValue
  return null
}

/** Matches `firebase-admin`'s own `DocumentData` — `any`-valued so callers can
 *  index/assign without a cast, same leniency the real SDK gives them. */
export type DocumentData = Record<string, any>

function decodeFields(fields: Record<string, any>): DocumentData {
  const out: DocumentData = {}
  for (const [k, v] of Object.entries(fields)) out[k] = decodeValue(v)
  return out
}

interface SplitFields {
  fields: Record<string, any>
  fieldPaths: string[]
  transforms: any[]
}

function splitFieldsAndTransforms(data: Record<string, unknown>): SplitFields {
  const fields: Record<string, any> = {}
  const fieldPaths: string[] = []
  const transforms: any[] = []

  for (const [key, val] of Object.entries(data)) {
    if (val instanceof FieldValueSentinel) {
      switch (val.kind) {
        case 'serverTimestamp':
          transforms.push({ fieldPath: key, setToServerValue: 'REQUEST_TIME' })
          break
        case 'increment':
          transforms.push({ fieldPath: key, increment: encodeValue(val.value) })
          break
        case 'arrayUnion':
          transforms.push({
            fieldPath: key,
            appendMissingElements: { values: (val.value as unknown[]).map(encodeValue) },
          })
          break
        case 'arrayRemove':
          transforms.push({
            fieldPath: key,
            removeAllFromArray: { values: (val.value as unknown[]).map(encodeValue) },
          })
          break
        case 'delete':
          // Omitted from `fields`; present in `fieldPaths` only -> Firestore deletes it.
          fieldPaths.push(key)
          break
      }
      // IMPORTANT: transform sentinels (serverTimestamp/increment/arrayUnion/
      // arrayRemove) must NOT be added to `fieldPaths`. `updateMask` and
      // `updateTransforms` on the same Write both apply, but the masked
      // `update` (which would clear any field named in the mask but absent
      // from `fields`) runs BEFORE `updateTransforms` — so masking a
      // transformed field clears it to nothing right before the transform
      // reads it, e.g. increment(5) on 10 would compute 0+5=5, not 15.
    } else {
      fields[key] = encodeValue(val)
      fieldPaths.push(key)
    }
  }

  return { fields, fieldPaths, transforms }
}

async function commitWrites(writes: any[]): Promise<void> {
  if (writes.length === 0) return
  // Firestore caps a single commit at 500 writes.
  for (let i = 0; i < writes.length; i += 500) {
    const chunk = writes.slice(i, i + 500)
    const res = await firestoreFetch(`${DOCUMENTS_ROOT}:commit`, {
      method: 'POST',
      body: JSON.stringify({ writes: chunk }),
    })
    await throwIfNotOk(res, 'commit')
  }
}

function docFullName(path: string): string {
  return `${DOCUMENTS_ROOT}/${path}`
}

// Firestore's own auto-ID alphabet/length for `.add()`-generated document IDs.
const AUTO_ID_ALPHABET = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789'
function generateAutoId(): string {
  const bytes = new Uint8Array(20)
  crypto.getRandomValues(bytes)
  let id = ''
  for (let i = 0; i < 20; i++) id += AUTO_ID_ALPHABET[bytes[i] % AUTO_ID_ALPHABET.length]
  return id
}

// ────────────────────────── Snapshots ────────────────────────────────────

export class DocumentSnapshot {
  constructor(
    public readonly ref: DocumentReference,
    public readonly exists: boolean,
    protected readonly fields: DocumentData
  ) {}

  get id(): string {
    return this.ref.id
  }

  data(): DocumentData | undefined {
    return this.exists ? this.fields : undefined
  }
}

/**
 * A snapshot known to exist (it came back from a query, which by definition
 * only returns matching, existing documents) — mirrors the real SDK's
 * `QueryDocumentSnapshot`, whose `.data()` is non-optional unlike a plain
 * `DocumentSnapshot` from a direct `.doc(id).get()` (which may not exist).
 */
export class QueryDocumentSnapshot extends DocumentSnapshot {
  constructor(ref: DocumentReference, fields: DocumentData) {
    super(ref, true, fields)
  }

  data(): DocumentData {
    return this.fields
  }
}

export class QuerySnapshot {
  constructor(public readonly docs: QueryDocumentSnapshot[]) {}
  get empty(): boolean {
    return this.docs.length === 0
  }
  get size(): number {
    return this.docs.length
  }
}

class AggregateQuerySnapshot {
  constructor(private readonly count: number) {}
  data(): { count: number } {
    return { count: this.count }
  }
}

// ─────────────────────── Document reference ──────────────────────────────

export interface SetOptions {
  merge?: boolean
  mergeFields?: string[]
}

export class DocumentReference {
  constructor(public readonly path: string) {}

  get id(): string {
    const parts = this.path.split('/')
    return parts[parts.length - 1]
  }

  /** Full REST resource name, e.g. `projects/p/databases/(default)/documents/users/uid`. */
  get fullName(): string {
    return docFullName(this.path)
  }

  /** The collection this document lives in. */
  get parent(): CollectionReference {
    const parts = this.path.split('/')
    return new CollectionReference(parts.slice(0, -1).join('/'))
  }

  collection(collectionId: string): CollectionReference {
    return new CollectionReference(`${this.path}/${collectionId}`)
  }

  async get(): Promise<DocumentSnapshot> {
    const res = await firestoreFetch(this.fullName)
    if (res.status === 404) return new DocumentSnapshot(this, false, {})
    await throwIfNotOk(res, `get ${this.path}`)
    const body = await res.json()
    return new DocumentSnapshot(this, true, decodeFields(body.fields ?? {}))
  }

  async set(data: Record<string, unknown>, options?: SetOptions): Promise<void> {
    await commitWrites([buildSetWrite(this, data, options)])
  }

  async update(data: Record<string, unknown>): Promise<void> {
    await commitWrites([buildUpdateWrite(this, data)])
  }

  async delete(): Promise<void> {
    await commitWrites([{ delete: this.fullName }])
  }
}

function buildSetWrite(ref: DocumentReference, data: Record<string, unknown>, options?: SetOptions): any {
  const { fields, fieldPaths, transforms } = splitFieldsAndTransforms(data)
  const write: any = { update: { name: ref.fullName, fields } }

  if (options?.mergeFields) {
    write.updateMask = { fieldPaths: options.mergeFields }
  } else if (options?.merge) {
    write.updateMask = { fieldPaths }
  }
  // Plain `.set()` (no options): full replace, no updateMask, no precondition.

  if (transforms.length) write.updateTransforms = transforms
  return write
}

function buildUpdateWrite(ref: DocumentReference, data: Record<string, unknown>): any {
  const { fields, fieldPaths, transforms } = splitFieldsAndTransforms(data)
  const write: any = {
    update: { name: ref.fullName, fields },
    updateMask: { fieldPaths },
    currentDocument: { exists: true },
  }
  if (transforms.length) write.updateTransforms = transforms
  return write
}

// ────────────────────────────── Query ────────────────────────────────────

export type WhereOp =
  | '=='
  | '!='
  | '<'
  | '<='
  | '>'
  | '>='
  | 'array-contains'
  | 'array-contains-any'
  | 'in'
  | 'not-in'

const OP_MAP: Record<WhereOp, string> = {
  '==': 'EQUAL',
  '!=': 'NOT_EQUAL',
  '<': 'LESS_THAN',
  '<=': 'LESS_THAN_OR_EQUAL',
  '>': 'GREATER_THAN',
  '>=': 'GREATER_THAN_OR_EQUAL',
  'array-contains': 'ARRAY_CONTAINS',
  'array-contains-any': 'ARRAY_CONTAINS_ANY',
  in: 'IN',
  'not-in': 'NOT_IN',
}

interface WhereSpec {
  field: string
  op: WhereOp
  value: unknown
}
interface OrderBySpec {
  field: string
  direction: 'asc' | 'desc'
}

export class Query {
  protected wheres: WhereSpec[] = []
  protected orderBys: OrderBySpec[] = []
  protected limitN: number | undefined

  constructor(
    protected readonly collectionId: string,
    protected readonly parentPath: string | undefined,
    protected readonly allDescendants: boolean
  ) {}

  where(field: string, op: WhereOp, value: unknown): this {
    const clone = this.clone()
    clone.wheres = [...this.wheres, { field, op, value }]
    return clone
  }

  orderBy(field: string, direction: 'asc' | 'desc' = 'asc'): this {
    const clone = this.clone()
    clone.orderBys = [...this.orderBys, { field, direction }]
    return clone
  }

  limit(n: number): this {
    const clone = this.clone()
    clone.limitN = n
    return clone
  }

  protected clone(): this {
    const c = new (this.constructor as any)(this.collectionId, this.parentPath, this.allDescendants)
    c.wheres = this.wheres
    c.orderBys = this.orderBys
    c.limitN = this.limitN
    return c
  }

  private buildStructuredQuery(): any {
    const sq: any = { from: [{ collectionId: this.collectionId, allDescendants: this.allDescendants }] }

    if (this.wheres.length) {
      const filters = this.wheres.map((w) => ({
        fieldFilter: { field: { fieldPath: w.field }, op: OP_MAP[w.op], value: encodeValue(w.value) },
      }))
      sq.where = filters.length === 1 ? filters[0] : { compositeFilter: { op: 'AND', filters } }
    }
    if (this.orderBys.length) {
      sq.orderBy = this.orderBys.map((o) => ({
        field: { fieldPath: o.field },
        direction: o.direction === 'desc' ? 'DESCENDING' : 'ASCENDING',
      }))
    }
    if (this.limitN !== undefined) sq.limit = this.limitN

    return sq
  }

  private get parentUrl(): string {
    return this.parentPath ? `${DOCUMENTS_ROOT}/${this.parentPath}` : DOCUMENTS_ROOT
  }

  async get(): Promise<QuerySnapshot> {
    const res = await firestoreFetch(`${this.parentUrl}:runQuery`, {
      method: 'POST',
      body: JSON.stringify({ structuredQuery: this.buildStructuredQuery() }),
    })
    await throwIfNotOk(res, `query ${this.collectionId}`)
    const rows: any[] = await res.json()

    const docs: QueryDocumentSnapshot[] = []
    for (const row of rows) {
      if (!row.document) continue // skippedResults-only row
      const name: string = row.document.name
      const relativePath = name.slice(`${DOCUMENTS_ROOT}/`.length)
      const ref = new DocumentReference(relativePath)
      docs.push(new QueryDocumentSnapshot(ref, decodeFields(row.document.fields ?? {})))
    }
    return new QuerySnapshot(docs)
  }

  count(): { get(): Promise<AggregateQuerySnapshot> } {
    return {
      get: async () => {
        const res = await firestoreFetch(`${this.parentUrl}:runAggregationQuery`, {
          method: 'POST',
          body: JSON.stringify({
            structuredAggregationQuery: {
              structuredQuery: this.buildStructuredQuery(),
              aggregations: [{ alias: 'count', count: {} }],
            },
          }),
        })
        await throwIfNotOk(res, `count ${this.collectionId}`)
        const rows: any[] = await res.json()
        const countStr = rows[0]?.result?.aggregateFields?.count?.integerValue ?? '0'
        return new AggregateQuerySnapshot(Number(countStr))
      },
    }
  }
}

export class CollectionReference extends Query {
  constructor(public readonly path: string) {
    const parts = path.split('/')
    const collectionId = parts[parts.length - 1]
    const parentPath = parts.length > 1 ? parts.slice(0, -1).join('/') : undefined
    super(collectionId, parentPath, false)
  }

  /** The document this (sub)collection lives under, or `null` for a root-level collection. */
  get parent(): DocumentReference | null {
    return this.parentPath ? new DocumentReference(this.parentPath) : null
  }

  doc(id?: string): DocumentReference {
    return new DocumentReference(`${this.path}/${id ?? generateAutoId()}`)
  }

  async add(data: Record<string, unknown>): Promise<DocumentReference> {
    const ref = this.doc()
    await ref.set(data)
    return ref
  }
}

// ─────────────────────────── Write batch ─────────────────────────────────

export class WriteBatch {
  private writes: any[] = []

  set(ref: DocumentReference, data: Record<string, unknown>, options?: SetOptions): this {
    this.writes.push(buildSetWrite(ref, data, options))
    return this
  }

  update(ref: DocumentReference, data: Record<string, unknown>): this {
    this.writes.push(buildUpdateWrite(ref, data))
    return this
  }

  delete(ref: DocumentReference): this {
    this.writes.push({ delete: ref.fullName })
    return this
  }

  async commit(): Promise<void> {
    await commitWrites(this.writes)
  }
}

// ───────────────────────── Recursive delete ──────────────────────────────

async function listCollectionIds(docPath: string | undefined): Promise<string[]> {
  const parent = docPath ? `${DOCUMENTS_ROOT}/${docPath}` : DOCUMENTS_ROOT
  const res = await firestoreFetch(`${parent}:listCollectionIds`, {
    method: 'POST',
    body: JSON.stringify({}),
  })
  await throwIfNotOk(res, `listCollectionIds ${docPath ?? '(root)'}`)
  const body = await res.json()
  return body.collectionIds ?? []
}

async function recursiveDelete(ref: DocumentReference): Promise<void> {
  const collectionIds = await listCollectionIds(ref.path)
  for (const collectionId of collectionIds) {
    const sub = new CollectionReference(`${ref.path}/${collectionId}`)
    const snap = await sub.get()
    // Delete this level's docs in batches, then recurse into each doc's own subcollections.
    const batch = new WriteBatch()
    for (const doc of snap.docs) batch.delete(doc.ref)
    await batch.commit()
    for (const doc of snap.docs) await recursiveDelete(doc.ref)
  }
  await ref.delete()
}

// ─────────────────────────────── getAll ──────────────────────────────────

// Firestore's real `:batchGet` endpoint reads arbitrarily many documents in
// ONE request — unlike firing `refs.map(ref => ref.get())` through
// Promise.all, which was N *concurrent* subrequests for N refs. On
// Cloudflare Workers, subrequests per invocation are capped; a page like
// /admin/users batch-fetching one business per user (up to `limit`, i.e. up
// to 200) blew past that cap and failed with an opaque fetch error. Caps at
// 500 docs per call (Firestore's own limit on batchGet), chunking beyond that.
async function batchGetDocs(refs: DocumentReference[]): Promise<DocumentSnapshot[]> {
  if (refs.length === 0) return []

  const byName = new Map<string, DocumentSnapshot>()
  for (let i = 0; i < refs.length; i += 500) {
    const chunk = refs.slice(i, i + 500)
    const res = await firestoreFetch(`${DOCUMENTS_ROOT}:batchGet`, {
      method: 'POST',
      body: JSON.stringify({ documents: chunk.map((r) => r.fullName) }),
    })
    await throwIfNotOk(res, 'batchGet')
    const rows: any[] = await res.json()
    // Order is not guaranteed to match the request — match by name instead.
    for (const row of rows) {
      if (row.found) {
        const relativePath = row.found.name.slice(`${DOCUMENTS_ROOT}/`.length)
        byName.set(row.found.name, new DocumentSnapshot(new DocumentReference(relativePath), true, decodeFields(row.found.fields ?? {})))
      } else if (row.missing) {
        const relativePath = row.missing.slice(`${DOCUMENTS_ROOT}/`.length)
        byName.set(row.missing, new DocumentSnapshot(new DocumentReference(relativePath), false, {}))
      }
    }
  }

  return refs.map((r) => byName.get(r.fullName) ?? new DocumentSnapshot(r, false, {}))
}

// ──────────────────────────── Top-level client ───────────────────────────

export const restFirestore = {
  collection(path: string): CollectionReference {
    return new CollectionReference(path)
  },
  doc(path: string): DocumentReference {
    return new DocumentReference(path)
  },
  collectionGroup(collectionId: string): Query {
    return new Query(collectionId, undefined, true)
  },
  batch(): WriteBatch {
    return new WriteBatch()
  },
  recursiveDelete(ref: DocumentReference): Promise<void> {
    return recursiveDelete(ref)
  },
  /** Batch-fetch multiple docs by ref, preserving order — one HTTP call (or
   *  one per 500-doc chunk), not one call per ref. */
  getAll(...refs: DocumentReference[]): Promise<DocumentSnapshot[]> {
    return batchGetDocs(refs)
  },
}
