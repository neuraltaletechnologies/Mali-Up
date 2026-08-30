/**
 * Small date/aggregation helpers shared by the analytics-style API routes
 * (`app/api/admin/analytics/route.ts`, `app/api/admin/growth/route.ts`).
 * Extracted so the two routes agree on how a Firestore timestamp becomes a
 * millisecond epoch and how trailing time windows are bucketed.
 */

/** Coerce a Firestore timestamp / ISO string / `{_seconds}` shape to epoch ms (0 if unparseable). */
export function toMs(value: unknown): number {
  if (!value) return 0
  if (typeof value === 'string') {
    const t = new Date(value).getTime()
    return Number.isNaN(t) ? 0 : t
  }
  if (typeof value === 'object' && value !== null) {
    const s = (value as Record<string, number>)._seconds ?? (value as Record<string, number>).seconds
    if (typeof s === 'number') return s * 1000
  }
  return 0
}

/** The last N months as `{ label, endMs }` pairs (last day of each month), oldest first. */
export function lastNMonths(n: number): { label: string; endMs: number }[] {
  const result: { label: string; endMs: number }[] = []
  const now = new Date()
  for (let i = n - 1; i >= 0; i--) {
    const d = new Date(now.getFullYear(), now.getMonth() - i + 1, 0)
    const label = d.toLocaleString('en-GB', { month: 'short', year: '2-digit' })
    result.push({ label, endMs: d.getTime() })
  }
  return result
}

/** ISO week-ish bucket start (Monday 00:00 UTC) for a given epoch ms. */
function weekStartMs(ms: number): number {
  const d = new Date(ms)
  const day = (d.getUTCDay() + 6) % 7 // 0 = Monday
  return Date.UTC(d.getUTCFullYear(), d.getUTCMonth(), d.getUTCDate() - day)
}

/**
 * Bucket a list of epoch-ms timestamps into the last `weeks` Monday-aligned
 * weeks, oldest first. `label` is `dd MMM` of the week start.
 */
export function weeklyCounts(timestamps: number[], weeks: number): { label: string; value: number }[] {
  const thisWeekStart = weekStartMs(Date.now())
  const weekMs = 7 * 24 * 60 * 60 * 1000
  const buckets: { start: number; label: string; value: number }[] = []
  for (let i = weeks - 1; i >= 0; i--) {
    const start = thisWeekStart - i * weekMs
    buckets.push({
      start,
      label: new Date(start).toLocaleString('en-GB', { day: '2-digit', month: 'short' }),
      value: 0,
    })
  }
  const firstStart = buckets[0].start
  for (const ts of timestamps) {
    if (ts < firstStart) continue
    const idx = Math.floor((weekStartMs(ts) - firstStart) / weekMs)
    if (idx >= 0 && idx < buckets.length) buckets[idx].value += 1
  }
  return buckets.map(({ label, value }) => ({ label, value }))
}

/** Percentage change from `prev` to `current`, rounded. `null` when there is no baseline. */
export function deltaPct(current: number, prev: number): number | null {
  if (prev === 0) return current === 0 ? 0 : null
  return Math.round(((current - prev) / prev) * 100)
}
