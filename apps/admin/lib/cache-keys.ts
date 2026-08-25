/**
 * Shared cache keys for withCache()/invalidateCache() (lib/api-cache.ts).
 *
 * Kept out of app/api/**\/route.ts files deliberately: Next's generated
 * route-module types only allow a fixed set of exports there (GET/POST/...
 * plus a small allowlist like `config`/`generateStaticParams`) — any other
 * named export, e.g. a `CACHE_KEY` constant, fails `next build`'s route-type
 * validation (TS2344, "does not satisfy the constraint '{ [x: string]: never
 * }'"). Centralising the keys here means a route and the other routes that
 * write the same collection can share one source of truth without either
 * side exporting non-handler symbols from a route.ts.
 */
export const CACHE_KEYS = {
  features: 'features',
  planRequests: 'plan-requests',
  refunds: 'refunds',
  support: 'support',
  catalog: 'catalog',
  catalogSubmissions: 'catalog-submissions',
  users: (limitParam: number) => `users:${limitParam}`,
} as const
