import type { BeemAutoCampaign, BeemAutoCampaignInput, SmsCampaignAudience, SmsCampaignType } from '@/types'

export const AUTO_CAMPAIGNS_COLLECTION = 'beem_sms_auto_campaigns'
export const AUTO_CAMPAIGNS_CACHE_KEY = 'beem-sms-auto-campaigns'

function toIso(value: unknown): string | undefined {
  if (!value) return undefined
  if (typeof value === 'string') return value
  if (typeof value === 'object' && value !== null) {
    const s = (value as Record<string, number>)._seconds ?? (value as Record<string, number>).seconds
    if (typeof s === 'number') return new Date(s * 1000).toISOString()
  }
  return undefined
}

export function mapAutoCampaign(id: string, d: Record<string, unknown>): BeemAutoCampaign {
  return {
    id,
    name: (d.name as string) || 'Auto campaign',
    campaignType: (d.campaignType as SmsCampaignType) || 'custom',
    enabled: d.enabled === true,
    month: Number(d.month) || 1,
    day: Number(d.day) || 1,
    hour: Number.isFinite(Number(d.hour)) ? Number(d.hour) : 9,
    message: (d.message as string) || '',
    senderId: (d.senderId as string) || undefined,
    audience: (d.audience as SmsCampaignAudience) || { kind: 'all' },
    lastRunYear: typeof d.lastRunYear === 'number' ? d.lastRunYear : undefined,
    lastCampaignId: (d.lastCampaignId as string) || undefined,
    updatedAt: toIso(d.updatedAt),
  }
}

const DAYS_IN_MONTH = [31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]

/**
 * Validates and normalises a (partial) rule from the request body. Returns an
 * error string, or the cleaned fields. Only audience kinds that make sense
 * year after year are allowed (no hand-picked businesses / numbers).
 */
export function parseAutoCampaignInput(
  body: Partial<BeemAutoCampaignInput>,
  partial: boolean
): { error: string } | { data: Partial<BeemAutoCampaignInput> } {
  const out: Partial<BeemAutoCampaignInput> = {}

  if (body.name !== undefined || !partial) {
    const name = String(body.name ?? '').trim()
    if (!name) return { error: 'Name is required' }
    out.name = name.slice(0, 120)
  }
  if (body.message !== undefined || !partial) {
    const message = String(body.message ?? '').trim()
    if (!message) return { error: 'Message is required' }
    out.message = message.slice(0, 918) // 6 SMS parts max
  }
  if (body.month !== undefined || body.day !== undefined || !partial) {
    const month = Number(body.month)
    const day = Number(body.day)
    if (!Number.isInteger(month) || month < 1 || month > 12) return { error: 'Month must be 1-12' }
    if (!Number.isInteger(day) || day < 1 || day > DAYS_IN_MONTH[month - 1]) return { error: 'Invalid day for that month' }
    out.month = month
    out.day = day
  }
  if (body.hour !== undefined || !partial) {
    const hour = Number(body.hour ?? 9)
    if (!Number.isInteger(hour) || hour < 0 || hour > 23) return { error: 'Hour must be 0-23' }
    out.hour = hour
  }
  if (body.enabled !== undefined || !partial) out.enabled = body.enabled === true
  if (body.campaignType !== undefined || !partial) out.campaignType = body.campaignType || 'custom'
  if (body.senderId !== undefined) out.senderId = String(body.senderId).trim() || undefined
  if (body.audience !== undefined || !partial) {
    const a = body.audience ?? { kind: 'all' }
    if (a.kind === 'all') out.audience = { kind: 'all' }
    else if (a.kind === 'plan_tier' && a.planTier) out.audience = { kind: 'plan_tier', planTier: a.planTier }
    else return { error: 'Audience must be all users or a plan tier' }
  }
  return { data: out }
}
