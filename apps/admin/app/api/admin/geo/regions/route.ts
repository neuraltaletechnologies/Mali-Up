import { NextResponse } from 'next/server'
import { requireAdminSession } from '@/lib/api-guard'
import { withCache } from '@/lib/api-cache'

// Same worldwide region lookup the mobile app's onboarding uses for every
// country except Tanzania (which has its own curated region/district list —
// see lib/locations.ts). Mirrors GeoLookupService.fetchRegions() in
// apps/mobile-app/lib/core/services/geo_lookup_service.dart, proxied
// server-side so the API key never reaches the browser.
const CSC_BASE = 'https://api.countrystatecity.in/v1'

export interface GeoRegion {
  name: string
  /** Alpha-2 state code, needed to look up its districts. Absent for a
   *  handful of divisions the API itself doesn't code. */
  code?: string
}

export async function GET(request: Request) {
  const denied = await requireAdminSession()
  if (denied) return denied

  const { searchParams } = new URL(request.url)
  const country = (searchParams.get('country') ?? '').toUpperCase().trim()
  if (!country) {
    return NextResponse.json({ error: 'country is required' }, { status: 400 })
  }

  const apiKey = process.env.CSC_API_KEY
  if (!apiKey) {
    // No key configured — the client falls back to free-text entry, same as
    // the app does when GeoLookupService.isConfigured is false.
    return NextResponse.json({ regions: [] })
  }

  try {
    const regions = await withCache(`geo:regions:${country}`, 24 * 60 * 60_000, async () => {
      const res = await fetch(`${CSC_BASE}/countries/${country}/states`, {
        headers: { 'X-CSCAPI-KEY': apiKey },
      })
      if (!res.ok) return [] as GeoRegion[]
      const data = (await res.json()) as unknown
      if (!Array.isArray(data)) return [] as GeoRegion[]
      return (data as Array<{ name?: string; iso2?: string }>)
        .map((r) => ({
          name: (r.name ?? '').toString().trim(),
          code: (r.iso2 ?? '').toString().trim() || undefined,
        }))
        .filter((r) => r.name.length > 0)
        .sort((a, b) => a.name.toLowerCase().localeCompare(b.name.toLowerCase())) as GeoRegion[]
    })
    return NextResponse.json({ regions })
  } catch (err) {
    console.error('[GET /api/admin/geo/regions]', err)
    return NextResponse.json({ regions: [] })
  }
}
