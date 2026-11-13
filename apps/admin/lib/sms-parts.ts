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
