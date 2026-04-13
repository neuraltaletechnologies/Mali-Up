import { promises as fs } from 'node:fs'
import path from 'node:path'

const SITE_URL = (process.env.NEXT_PUBLIC_SITE_URL || 'https://maliup.neuraltale.com').replace(/\/$/, '')
const APP_DIR = path.join(process.cwd(), 'app')
const OUTPUT_FILE = path.join(process.cwd(), 'public', 'sitemap.xml')

const EXCLUDED_SEGMENTS = new Set(['api'])
const EXCLUDED_ROUTE_PREFIXES = ['/admin', '/private']

async function findPageFiles(dir) {
  const entries = await fs.readdir(dir, { withFileTypes: true })
  const results = []

  for (const entry of entries) {
    const entryPath = path.join(dir, entry.name)

    if (entry.isDirectory()) {
      if (entry.name.startsWith('_') || entry.name.startsWith('@')) {
        continue
      }

      results.push(...(await findPageFiles(entryPath)))
      continue
    }

    if (entry.isFile() && entry.name === 'page.tsx') {
      results.push(entryPath)
    }
  }

  return results
}

function routeFromFile(filePath) {
  const relativePath = path.relative(APP_DIR, filePath)
  const dirSegments = relativePath.split(path.sep).slice(0, -1)

  const cleanedSegments = dirSegments
    .filter((segment) => segment.length > 0)
    .filter((segment) => !(segment.startsWith('(') && segment.endsWith(')')))

  if (cleanedSegments.some((segment) => segment.startsWith('[') && segment.endsWith(']'))) {
    return null
  }

  if (cleanedSegments.some((segment) => EXCLUDED_SEGMENTS.has(segment))) {
    return null
  }

  const route = `/${cleanedSegments.join('/')}`.replace(/\/+/g, '/')
  return route === '/' ? '/' : route.replace(/\/$/, '')
}

function isRouteAllowed(route) {
  return !EXCLUDED_ROUTE_PREFIXES.some((prefix) => route === prefix || route.startsWith(`${prefix}/`))
}

function buildSitemapXml(routes) {
  const lastmod = new Date().toISOString().slice(0, 10)

  const urls = routes
    .map((route) => {
      const priority = route === '/' ? '1.0' : '0.8'
      const loc = `${SITE_URL}${route === '/' ? '/' : route}`
      return `  <url>\n    <loc>${loc}</loc>\n    <lastmod>${lastmod}</lastmod>\n    <changefreq>weekly</changefreq>\n    <priority>${priority}</priority>\n  </url>`
    })
    .join('\n')

  return `<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n${urls}\n</urlset>\n`
}

async function main() {
  const pageFiles = await findPageFiles(APP_DIR)
  const routes = Array.from(
    new Set(
      pageFiles
        .map(routeFromFile)
        .filter((route) => route && isRouteAllowed(route))
    )
  ).sort((a, b) => a.localeCompare(b))

  if (routes.length === 0) {
    throw new Error('No public routes found to generate sitemap.xml')
  }

  const sitemapXml = buildSitemapXml(routes)
  await fs.writeFile(OUTPUT_FILE, sitemapXml, 'utf8')

  console.log(`Generated sitemap with ${routes.length} route(s): ${routes.join(', ')}`)
}

main().catch((error) => {
  console.error(error)
  process.exit(1)
})
