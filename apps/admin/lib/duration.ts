// Shared duration helpers for manually assigning a plan from admin — lets the
// admin pick "how long" in whichever unit makes sense (a trial extension of
// a few days, a week, a month, a year) instead of only ever entering months.
// Used both client-side (duration-picker.tsx, for the "expires on" preview)
// and server-side (app/api/admin/plans/assign/route.ts, to compute the real
// planExpiresAt).

export type DurationUnit = 'days' | 'weeks' | 'months' | 'years'

export const DURATION_UNITS: DurationUnit[] = ['days', 'weeks', 'months', 'years']

export const DURATION_UNIT_LABELS: Record<DurationUnit, string> = {
  days: 'Days',
  weeks: 'Weeks',
  months: 'Months',
  years: 'Years',
}

/** Adds `value` of `unit` to `base`, using calendar-correct month/year math
 *  (not a fixed 30-day approximation) so "1 month" from Jan 31 lands on a
 *  sensible date rather than drifting. */
export function addDuration(base: Date, value: number, unit: DurationUnit): Date {
  const d = new Date(base)
  switch (unit) {
    case 'days':   d.setDate(d.getDate() + value); break
    case 'weeks':  d.setDate(d.getDate() + value * 7); break
    case 'months': d.setMonth(d.getMonth() + value); break
    case 'years':  d.setFullYear(d.getFullYear() + value); break
  }
  return d
}

export function isValidDurationUnit(value: unknown): value is DurationUnit {
  return typeof value === 'string' && (DURATION_UNITS as string[]).includes(value)
}

export function formatDuration(value: number, unit: DurationUnit): string {
  const singular = unit.slice(0, -1)
  return `${value} ${value === 1 ? singular : unit}`
}
