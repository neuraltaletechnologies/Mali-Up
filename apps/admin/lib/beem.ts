import { restFirestore as adminFirestore } from '@/lib/firestore-rest'

export interface BeemConfig {
  apiKey: string
  secretKey: string
  senderId: string
}

export interface BeemBalance {
  credit_bal: number
  currency?: string
}

export interface BeemTemplate {
  sms_title: string
  message: string
  sender_name?: string
  status?: string
}

const BEEM_SMS_SEND_URL = 'https://apisms.beem.africa/v1/send'
const BEEM_SMS_TEMPLATES_URL = 'https://apisms.beem.africa/public/v1/sms-templates'
const BEEM_BALANCE_URL = 'https://apisms.beem.africa/public/v1/vendors/balance'

/**
 * Strips all non-digit characters and normalizes international format.
 * E.g. "+255 712 345 678" -> "255712345678", "0712345678" -> "255712345678"
 */
export function normalizePhone(raw: string): string {
  let digits = String(raw ?? '').replace(/\D/g, '')
  if (digits.startsWith('0') && digits.length === 10) {
    digits = '255' + digits.slice(1)
  }
  return digits
}

/**
 * Gets Beem Africa API credentials from environment variables or Firestore config.
 * Prioritizes dedicated SMS credentials (BEEM_SMS_API_KEY) and falls back to BEEM_API_KEY.
 */
export async function getBeemCredentials(): Promise<BeemConfig> {
  const envKey = process.env.BEEM_SMS_API_KEY || process.env.BEEM_API_KEY || ''
  const envSecret = process.env.BEEM_SMS_SECRET_KEY || process.env.BEEM_SECRET_KEY || ''
  const envSender = process.env.BEEM_SMS_SENDER_ID || process.env.BEEM_SENDER_ID || 'INFO'

  if (envKey && envSecret) {
    return {
      apiKey: envKey,
      secretKey: envSecret,
      senderId: envSender,
    }
  }

  // Fallback: check Firestore platform_config/beem
  try {
    const doc = await adminFirestore.collection('platform_config').doc('beem').get()
    if (doc.exists) {
      const data = doc.data()!
      return {
        apiKey: (data.smsApiKey as string) || (data.apiKey as string) || envKey,
        secretKey: (data.smsSecretKey as string) || (data.secretKey as string) || envSecret,
        senderId: (data.senderId as string) || envSender,
      }
    }
  } catch (err) {
    console.error('[Beem] Error reading credentials from Firestore:', err)
  }

  return {
    apiKey: envKey,
    secretKey: envSecret,
    senderId: envSender,
  }
}

function getAuthHeader(apiKey: string, secretKey: string): string {
  return 'Basic ' + Buffer.from(`${apiKey}:${secretKey}`).toString('base64')
}

/**
 * Checks current Beem SMS credit balance.
 */
export async function fetchBeemBalance(): Promise<{ success: boolean; balance?: number; raw?: unknown; error?: string }> {
  const creds = await getBeemCredentials()
  if (!creds.apiKey || !creds.secretKey) {
    return { success: false, error: 'Beem API credentials not configured' }
  }

  try {
    const res = await fetch(BEEM_BALANCE_URL, {
      method: 'GET',
      headers: {
        Authorization: getAuthHeader(creds.apiKey, creds.secretKey),
        'Content-Type': 'application/json',
      },
    })

    if (!res.ok) {
      const text = await res.text()
      return { success: false, error: `Beem HTTP ${res.status}: ${text}` }
    }

    const data = (await res.json()) as { data?: { credit_bal?: number }; credit_bal?: number }
    const credit = data.data?.credit_bal ?? data.credit_bal ?? 0
    return { success: true, balance: Number(credit), raw: data }
  } catch (err) {
    return { success: false, error: err instanceof Error ? err.message : String(err) }
  }
}

/**
 * Fetches approved SMS templates from Beem Africa.
 */
export async function fetchBeemTemplates(): Promise<{ success: boolean; templates: BeemTemplate[]; error?: string }> {
  const creds = await getBeemCredentials()
  if (!creds.apiKey || !creds.secretKey) {
    return { success: false, templates: [], error: 'Beem API credentials not configured' }
  }

  try {
    const res = await fetch(BEEM_SMS_TEMPLATES_URL, {
      method: 'GET',
      headers: {
        Authorization: getAuthHeader(creds.apiKey, creds.secretKey),
        'Content-Type': 'application/json',
      },
    })

    if (!res.ok) {
      const text = await res.text()
      return { success: false, templates: [], error: `Beem HTTP ${res.status}: ${text}` }
    }

    const body = (await res.json()) as { data?: Array<{ sms_title?: string; message?: string; sender_name?: string }> }
    const list: BeemTemplate[] = (body.data ?? []).map((t) => ({
      sms_title: t.sms_title ?? '',
      message: t.message ?? '',
      sender_name: t.sender_name ?? '',
    }))

    return { success: true, templates: list }
  } catch (err) {
    return { success: false, templates: [], error: err instanceof Error ? err.message : String(err) }
  }
}

export interface SmsRecipient {
  recipientId: number | string
  phone: string
  name?: string
  businessName?: string
}

export interface SendSmsBatchOptions {
  recipients: SmsRecipient[]
  message: string
  senderId?: string
  scheduleTime?: string // format: YYYY-MM-DD HH:mm:ss
}

export interface SendSmsBatchResult {
  success: boolean
  totalSent: number
  totalFailed: number
  successfulNumbers: string[]
  failedNumbers: { phone: string; reason: string }[]
  error?: string
  beemResponse?: unknown
}

/**
 * Formats message by replacing `{name}`, `{businessName}`, `{phone}` tags.
 */
export function formatPersonalizedMessage(
  template: string,
  recipient: { name?: string; businessName?: string; phone: string }
): string {
  let msg = template
  const name = recipient.name?.trim() || 'Mteja'
  const biz = recipient.businessName?.trim() || 'Biashara yako'
  const phone = recipient.phone || ''

  msg = msg.replace(/\{name\}/gi, name)
  msg = msg.replace(/\{\{name\}\}/gi, name)
  msg = msg.replace(/\{businessName\}/gi, biz)
  msg = msg.replace(/\{\{businessName\}\}/gi, biz)
  msg = msg.replace(/\{phone\}/gi, phone)
  msg = msg.replace(/\{\{phone\}\}/gi, phone)
  msg = msg.replace(/\{appName\}/gi, 'Mali Up')
  return msg
}

/**
 * Calculates GSM character count and SMS segment parts.
 * Standard GSM 7-bit: 160 chars per SMS (153 chars/part if multi-part).
 * Unicode/Emoji: 70 chars per SMS (67 chars/part if multi-part).
 */
export function calculateSmsParts(text: string): { chars: number; parts: number; isUnicode: boolean } {
  const chars = text.length
  // Basic check for unicode characters outside GSM 03.38 standard
  // eslint-disable-next-line no-control-regex
  const isUnicode = /[^\u0000-\u007F]/.test(text)

  if (isUnicode) {
    if (chars <= 70) return { chars, parts: 1, isUnicode: true }
    return { chars, parts: Math.ceil(chars / 67), isUnicode: true }
  } else {
    if (chars <= 160) return { chars, parts: 1, isUnicode: false }
    return { chars, parts: Math.ceil(chars / 153), isUnicode: false }
  }
}

/**
 * Sends SMS via Beem Africa API.
 * If personalization tags ({name}, etc.) are present, dispatches customized messages.
 * Otherwise batches recipients in chunks of 500 into Beem's bulk endpoint.
 */
export async function sendBeemSmsBatch(options: SendSmsBatchOptions): Promise<SendSmsBatchResult> {
  const creds = await getBeemCredentials()
  if (!creds.apiKey || !creds.secretKey) {
    return {
      success: false,
      totalSent: 0,
      totalFailed: options.recipients.length,
      successfulNumbers: [],
      failedNumbers: options.recipients.map((r) => ({ phone: r.phone, reason: 'Beem credentials not configured' })),
      error: 'Beem credentials not configured',
    }
  }

  const senderId = options.senderId?.trim() || creds.senderId || 'INFO'
  const scheduleTime = options.scheduleTime?.trim() || ''

  const hasTags = /\{(name|businessName|phone|appName)\}/i.test(options.message)

  const successfulNumbers: string[] = []
  const failedNumbers: { phone: string; reason: string }[] = []

  // If message contains personalized tags, send per recipient (or mini-batches)
  if (hasTags) {
    for (const r of options.recipients) {
      const normalizedPhone = normalizePhone(r.phone)
      if (normalizedPhone.length < 9 || normalizedPhone.length > 15) {
        failedNumbers.push({ phone: r.phone, reason: 'Invalid phone format' })
        continue
      }

      const personalized = formatPersonalizedMessage(options.message, {
        name: r.name,
        businessName: r.businessName,
        phone: normalizedPhone,
      })

      const payload = {
        source_addr: senderId,
        schedule_time: scheduleTime,
        encoding: 0,
        message: personalized,
        recipients: [
          {
            recipient_id: 1,
            dest_addr: normalizedPhone,
          },
        ],
      }

      try {
        const res = await fetch(BEEM_SMS_SEND_URL, {
          method: 'POST',
          headers: {
            Authorization: getAuthHeader(creds.apiKey, creds.secretKey),
            'Content-Type': 'application/json',
          },
          body: JSON.stringify(payload),
        })

        if (res.ok) {
          successfulNumbers.push(normalizedPhone)
        } else {
          const errText = await res.text()
          failedNumbers.push({ phone: normalizedPhone, reason: `Beem HTTP ${res.status}: ${errText}` })
        }
      } catch (err) {
        failedNumbers.push({ phone: normalizedPhone, reason: err instanceof Error ? err.message : String(err) })
      }
    }
  } else {
    // Bulk dispatch in chunks of 500
    const chunkSize = 500
    for (let i = 0; i < options.recipients.length; i += chunkSize) {
      const chunk = options.recipients.slice(i, i + chunkSize)
      const validRecipients = []

      for (let idx = 0; idx < chunk.length; idx++) {
        const r = chunk[idx]
        const normalized = normalizePhone(r.phone)
        if (normalized.length >= 9 && normalized.length <= 15) {
          validRecipients.push({
            recipient_id: idx + 1,
            dest_addr: normalized,
          })
        } else {
          failedNumbers.push({ phone: r.phone, reason: 'Invalid phone format' })
        }
      }

      if (validRecipients.length === 0) continue

      const payload = {
        source_addr: senderId,
        schedule_time: scheduleTime,
        encoding: 0,
        message: options.message,
        recipients: validRecipients,
      }

      try {
        const res = await fetch(BEEM_SMS_SEND_URL, {
          method: 'POST',
          headers: {
            Authorization: getAuthHeader(creds.apiKey, creds.secretKey),
            'Content-Type': 'application/json',
          },
          body: JSON.stringify(payload),
        })

        if (res.ok) {
          validRecipients.forEach((vr) => successfulNumbers.push(vr.dest_addr))
        } else {
          const errText = await res.text()
          validRecipients.forEach((vr) => failedNumbers.push({ phone: vr.dest_addr, reason: `Beem HTTP ${res.status}: ${errText}` }))
        }
      } catch (err) {
        const msg = err instanceof Error ? err.message : String(err)
        validRecipients.forEach((vr) => failedNumbers.push({ phone: vr.dest_addr, reason: msg }))
      }
    }
  }

  return {
    success: successfulNumbers.length > 0 || (failedNumbers.length === 0 && options.recipients.length === 0),
    totalSent: successfulNumbers.length,
    totalFailed: failedNumbers.length,
    successfulNumbers,
    failedNumbers,
  }
}
