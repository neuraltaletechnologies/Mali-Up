import { NextResponse } from 'next/server'
import { requireAdminSession } from '@/lib/api-guard'
import { fetchBeemBalance, fetchBeemTemplates, getBeemCredentials } from '@/lib/beem'

export async function GET() {
  const denied = await requireAdminSession()
  if (denied) return denied

  try {
    const creds = await getBeemCredentials()
    const isConfigured = Boolean(creds.apiKey && creds.secretKey)

    if (!isConfigured) {
      return NextResponse.json({
        configured: false,
        balance: null,
        senderId: creds.senderId || 'INFO',
        templates: [],
        message: 'Beem Africa API credentials are not configured in environment or platform config.',
      })
    }

    const [balanceRes, templatesRes] = await Promise.all([
      fetchBeemBalance(),
      fetchBeemTemplates(),
    ])

    return NextResponse.json({
      configured: true,
      balance: balanceRes.success ? balanceRes.balance : null,
      balanceError: balanceRes.error,
      senderId: creds.senderId || 'INFO',
      templates: templatesRes.templates || [],
      connected: balanceRes.success,
    })
  } catch (err) {
    console.error('[GET /api/admin/beem/status]', err)
    return NextResponse.json({ error: 'Failed to fetch Beem Africa status' }, { status: 500 })
  }
}
