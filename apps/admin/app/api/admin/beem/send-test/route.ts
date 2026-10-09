import { NextResponse } from 'next/server'
import { requireAdminSession } from '@/lib/api-guard'
import { normalizePhone, sendBeemSmsBatch } from '@/lib/beem'

export async function POST(request: Request) {
  const denied = await requireAdminSession()
  if (denied) return denied

  try {
    const body = (await request.json()) as { phone?: string; message?: string; senderId?: string }
    const phone = normalizePhone(body.phone ?? '')
    const message = body.message?.trim() ?? ''
    const senderId = body.senderId?.trim()

    if (!phone || phone.length < 9) {
      return NextResponse.json({ error: 'Valid phone number is required (e.g. 0712345678 or 255712345678)' }, { status: 400 })
    }
    if (!message) {
      return NextResponse.json({ error: 'Message content cannot be empty' }, { status: 400 })
    }

    const result = await sendBeemSmsBatch({
      recipients: [{ recipientId: 1, phone, name: 'Admin Test' }],
      message,
      senderId,
    })

    if (!result.success || result.totalSent === 0) {
      const reason = result.failedNumbers[0]?.reason || result.error || 'Failed to dispatch test SMS'
      return NextResponse.json({ error: reason, details: result }, { status: 502 })
    }

    return NextResponse.json({
      success: true,
      message: `Test SMS dispatched successfully to ${phone}`,
      result,
    })
  } catch (err) {
    console.error('[POST /api/admin/beem/send-test]', err)
    return NextResponse.json({ error: 'Internal server error while sending test SMS' }, { status: 500 })
  }
}
