import { adminFirestore } from './firebase-admin'
import { auth } from './auth'
import { headers } from 'next/headers'

interface AuditParams {
  action: string
  resourceType: string
  resourceId: string
  resourceName: string
  isDestructive: boolean
  before?: Record<string, unknown>
  after?: Record<string, unknown>
}

const omitValue = Symbol('omitValue')

/**
 * Firestore rejects undefined values at any depth. Audit payloads often contain
 * snapshots of optional fields, so remove undefined map properties centrally
 * while leaving Firestore-native class instances (Timestamp, GeoPoint, etc.)
 * untouched. Array positions are preserved by replacing undefined with null.
 */
function sanitizeFirestoreValue(value: unknown): unknown | typeof omitValue {
  if (value === undefined) return omitValue

  if (Array.isArray(value)) {
    return value.map((item) => {
      const sanitized = sanitizeFirestoreValue(item)
      return sanitized === omitValue ? null : sanitized
    })
  }

  if (value !== null && typeof value === 'object') {
    const prototype = Object.getPrototypeOf(value)
    const isPlainObject = prototype === Object.prototype || prototype === null

    if (isPlainObject) {
      const sanitized: Record<string, unknown> = {}
      for (const [key, item] of Object.entries(value)) {
        const sanitizedItem = sanitizeFirestoreValue(item)
        if (sanitizedItem !== omitValue) sanitized[key] = sanitizedItem
      }
      return sanitized
    }
  }

  return value
}

function sanitizeFirestoreDocument(
  document: Record<string, unknown>,
): Record<string, unknown> {
  return sanitizeFirestoreValue(document) as Record<string, unknown>
}

export async function writeAudit(params: AuditParams): Promise<void> {
  try {
    const [session, hdrs] = await Promise.all([auth(), headers()])
    const ip =
      hdrs.get('x-forwarded-for')?.split(',')[0].trim() ??
      hdrs.get('x-real-ip') ??
      undefined

    const auditDocument = sanitizeFirestoreDocument({
      adminId:   session?.user?.id ?? 'unknown',
      adminName: session?.user?.name ?? session?.user?.email ?? 'Admin',
      ...params,
      createdAt: new Date(),
      ...(ip ? { ip } : {}),
    })

    await adminFirestore.collection('admin_audit_log').add(auditDocument)
  } catch (err) {
    // Audit failures must not break the main action
    console.error('[writeAudit]', err)
  }
}
