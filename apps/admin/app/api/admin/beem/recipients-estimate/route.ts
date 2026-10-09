import { NextResponse } from 'next/server'
import { requireAdminSession } from '@/lib/api-guard'
import { resolveSmsRecipients } from '@/lib/sms-recipients'
import { calculateSmsParts } from '@/lib/beem'
import type { SmsCampaignAudience } from '@/types'

export async function POST(request: Request) {
  const denied = await requireAdminSession()
  if (denied) return denied

  try {
    const body = (await request.json()) as { audience: SmsCampaignAudience; message?: string }
    if (!body.audience) {
      return NextResponse.json({ error: 'Audience definition is required' }, { status: 400 })
    }

    const recipients = await resolveSmsRecipients(body.audience)
    const sampleMessage = body.message?.trim() || ''
    const partsInfo = calculateSmsParts(sampleMessage || 'Sample')
    const estimatedCredits = recipients.length * partsInfo.parts

    return NextResponse.json({
      recipientCount: recipients.length,
      sampleRecipients: recipients.slice(0, 5),
      smsParts: partsInfo.parts,
      charCount: partsInfo.chars,
      isUnicode: partsInfo.isUnicode,
      estimatedCredits,
    })
  } catch (err) {
    console.error('[POST /api/admin/beem/recipients-estimate]', err)
    return NextResponse.json({ error: 'Failed to calculate recipient estimate' }, { status: 500 })
  }
}
