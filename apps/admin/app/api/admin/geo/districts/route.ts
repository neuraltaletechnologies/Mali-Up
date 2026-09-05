import { NextResponse } from 'next/server'
import { requireAdminSession } from '@/lib/api-guard'
import { withCache } from '@/lib/api-cache'

// Districts ("wilaya") for a region within a non-Tanzania country. Mirrors
// GeoLookupService.fetchDistricts() in
// apps/mobile-app/lib/core/services/geo_lookup_service.dart — see
// app/api/admin/geo/regions/route.ts for the region half of this pair.
const CSC_BASE = 'https://api.countrystatecity.in/v1'

export interface GeoDistrict {
  name: string
}

export async function GET(request: Request) {
  const denied = await requireAdminSession()
  if (denied) return denied

  const { searchParams } = new URL(request.url)
  const country = (searchParams.get('country') ?? '').toUpperCase().trim()
  const region = (searchParams.get('region') ?? '').toUpperCase().trim()
  if (!country || !region) {
    return NextResponse.json({ error: 'country and region are required' }, { status: 400 })
  }

  const apiKey = process.env.CSC_API_KEY
  if (!apiKey) {
    return NextResponse.json({ districts: [] })
  }

  try {
    const districts = await withCache(`geo:districts:${country}:${region}`, 24 * 60 * 60_000, async () => {
      const res = await fetch(`${CSC_BASE}/countries/${country}/states/${region}/cities`, {
        headers: { 'X-CSCAPI-KEY': apiKey },
      })
      if (!res.ok) return [] as GeoDistrict[]
      const data = (await res.json()) as unknown
      if (!Array.isArray(data)) return [] as GeoDistrict[]
      return (data as Array<{ name?: string }>)
        .map((d) => ({ name: (d.name ?? '').toString().trim() }))
        .filter((d) => d.name.length > 0)
        .sort((a, b) => a.name.toLowerCase().localeCompare(b.name.toLowerCase()))
    })
    return NextResponse.json({ districts })
  } catch (err) {
    console.error('[GET /api/admin/geo/districts]', err)
    return NextResponse.json({ districts: [] })
  }
}
