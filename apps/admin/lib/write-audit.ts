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

export async function writeAudit(params: AuditParams): Promise<void> {
  try {
    const [session, hdrs] = await Promise.all([auth(), headers()])
    const ip =
      hdrs.get('x-forwarded-for')?.split(',')[0].trim() ??
      hdrs.get('x-real-ip') ??
      undefined

    await adminFirestore.collection('admin_audit_log').add({
      adminId:   session?.user?.id ?? 'unknown',
      adminName: session?.user?.name ?? session?.user?.email ?? 'Admin',
      ...params,
      createdAt: new Date(),
      ...(ip ? { ip } : {}),
    })
  } catch (err) {
    // Audit failures must not break the main action
    console.error('[writeAudit]', err)
  }
}
