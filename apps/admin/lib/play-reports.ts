import { getAccessToken, playServiceAccount } from './google-access-token'

/**
 * Reads Google Play Console's **install statistics** from the CSV reports
 * Google exports daily to a private Cloud Storage bucket. There is no
 * real-time Play API for installs/uninstalls — these monthly CSVs are the
 * only source, and they lag reality by ~2 days.
 *
 * Setup (bucket id + granting the service account read access):
 *   apps/admin/docs/play-console-reports.md
 *
 * Env:
 *   PLAY_REPORTS_BUCKET   e.g. "pubsite_prod_1234567890"  (no gs:// prefix)
 *   PLAY_PACKAGE_NAME     defaults to "com.neuraltale.maliup"
 *   PLAY_SA_CLIENT_EMAIL / PLAY_SA_PRIVATE_KEY  (optional — falls back to FIREBASE_*)
 */

const STORAGE_SCOPE = 'https://www.googleapis.com/auth/devstorage.read_only'
const DEFAULT_PACKAGE = 'com.neuraltale.maliup'
const MONTHS_BACK = 4
const SERIES_DAYS = 90

export interface PlayDailyPoint {
  date: string // YYYY-MM-DD
  installs: number
  uninstalls: number
}

export type PlayInstallStats =
  | {
      available: true
      dailySeries: PlayDailyPoint[]
      activeDeviceInstalls: number
      totalUserInstalls: number
      lastReportDate: string
    }
  | { available: false; reason: string }

interface OverviewRow {
  date: string
  dailyUserInstalls: number
  dailyUserUninstalls: number
  activeDeviceInstalls: number
  totalUserInstalls: number
}

/** `installs_<package>_<YYYYMM>_overview.csv` for the last N months, newest last. */
function overviewObjectNames(pkg: string): string[] {
  const names: string[] = []
  const now = new Date()
  for (let i = MONTHS_BACK - 1; i >= 0; i--) {
    const d = new Date(now.getFullYear(), now.getMonth() - i, 1)
    const ym = `${d.getFullYear()}${String(d.getMonth() + 1).padStart(2, '0')}`
    names.push(`stats/installs/installs_${pkg}_${ym}_overview.csv`)
  }
  return names
}

/** Play report CSVs are UTF-16LE with a BOM and CRLF line endings. */
function decodeCsv(buf: ArrayBuffer): string[][] {
  const text = new TextDecoder('utf-16le').decode(buf).replace(/^﻿/, '')
  return text
    .split(/\r?\n/)
    .filter((line) => line.trim().length > 0)
    .map((line) => line.split(',').map((cell) => cell.replace(/^"|"$/g, '').trim()))
}

function num(v: string | undefined): number {
  const n = Number(v)
  return Number.isFinite(n) ? n : 0
}

function parseOverview(rows: string[][]): OverviewRow[] {
  if (rows.length < 2) return []
  const header = rows[0].map((h) => h.toLowerCase())
  const col = (name: string) => header.indexOf(name.toLowerCase())
  const iDate = col('Date')
  const iInstalls = col('Daily User Installs')
  const iUninstalls = col('Daily User Uninstalls')
  const iActive = col('Active Device Installs')
  const iTotal = col('Total User Installs')
  if (iDate === -1) return []

  return rows.slice(1).map((r) => ({
    date: r[iDate],
    dailyUserInstalls: num(r[iInstalls]),
    dailyUserUninstalls: num(r[iUninstalls]),
    activeDeviceInstalls: num(r[iActive]),
    totalUserInstalls: num(r[iTotal]),
  }))
}

export async function getPlayInstallStats(): Promise<PlayInstallStats> {
  const bucket = process.env.PLAY_REPORTS_BUCKET
  const pkg = process.env.PLAY_PACKAGE_NAME ?? DEFAULT_PACKAGE
  const sa = playServiceAccount()

  if (!bucket) return { available: false, reason: 'PLAY_REPORTS_BUCKET is not set' }
  if (!sa) return { available: false, reason: 'No service-account credentials for Play reports' }

  let token: string
  try {
    token = await getAccessToken(sa, STORAGE_SCOPE)
  } catch (err) {
    return { available: false, reason: err instanceof Error ? err.message : 'Auth failed' }
  }

  const merged = new Map<string, OverviewRow>()
  let sawAny = false

  for (const name of overviewObjectNames(pkg)) {
    const url = `https://storage.googleapis.com/storage/v1/b/${encodeURIComponent(
      bucket,
    )}/o/${encodeURIComponent(name)}?alt=media`
    const res = await fetch(url, { headers: { Authorization: `Bearer ${token}` } })

    if (res.status === 404) continue // month not exported yet
    if (res.status === 403 || res.status === 401) {
      return {
        available: false,
        reason: `Cloud Storage denied access (${res.status}) — the service account is not authorised for this bucket`,
      }
    }
    if (!res.ok) {
      return { available: false, reason: `Cloud Storage read failed: ${res.status}` }
    }

    sawAny = true
    for (const row of parseOverview(decodeCsv(await res.arrayBuffer()))) {
      if (row.date) merged.set(row.date, row)
    }
  }

  if (!sawAny || merged.size === 0) {
    return { available: false, reason: 'No install reports found for this package yet' }
  }

  const sorted = [...merged.values()].sort((a, b) => a.date.localeCompare(b.date))
  const latest = sorted[sorted.length - 1]
  const cutoff = Date.now() - SERIES_DAYS * 24 * 60 * 60 * 1000

  const dailySeries: PlayDailyPoint[] = sorted
    .filter((r) => new Date(r.date).getTime() >= cutoff)
    .map((r) => ({
      date: r.date,
      installs: r.dailyUserInstalls,
      uninstalls: r.dailyUserUninstalls,
    }))

  return {
    available: true,
    dailySeries,
    activeDeviceInstalls: latest.activeDeviceInstalls,
    totalUserInstalls: latest.totalUserInstalls,
    lastReportDate: latest.date,
  }
}

/** Sum installs/uninstalls over the trailing `days` and the `days` before that. */
export function windowTotals(
  series: PlayDailyPoint[],
  days: number,
): { installs: number; uninstalls: number; prevInstalls: number; prevUninstalls: number } {
  const dayMs = 24 * 60 * 60 * 1000
  const now = Date.now()
  const currentStart = now - days * dayMs
  const prevStart = now - 2 * days * dayMs

  let installs = 0
  let uninstalls = 0
  let prevInstalls = 0
  let prevUninstalls = 0

  for (const p of series) {
    const t = new Date(p.date).getTime()
    if (t >= currentStart) {
      installs += p.installs
      uninstalls += p.uninstalls
    } else if (t >= prevStart) {
      prevInstalls += p.installs
      prevUninstalls += p.uninstalls
    }
  }
  return { installs, uninstalls, prevInstalls, prevUninstalls }
}
