/**
 * In-memory TTL cache for expensive admin API GET routes (full collection /
 * collectionGroup scans). Firestore Spark plan caps reads at 50k/day, and
 * these routes are polled + refetched on every browser-tab focus, so without
 * a server-side cache a single dashboard tab can burn through a large chunk
 * of the daily quota on its own.
 *
 * Scoped to one warm serverless instance — not a distributed cache — but
 * that's enough to absorb the polling/focus-refetch bursts that cause most
 * of the read amplification.
 */

const store = new Map<string, { value: unknown; expiresAt: number }>()

export async function withCache<T>(
  key: string,
  ttlMs: number,
  fetcher: () => Promise<T>,
): Promise<T> {
  const hit = store.get(key)
  if (hit && hit.expiresAt > Date.now()) {
    return hit.value as T
  }

  const value = await fetcher()
  store.set(key, { value, expiresAt: Date.now() + ttlMs })
  return value
}

/** Call after a write that should invalidate a cached read (e.g. business created). */
export function invalidateCache(key: string) {
  store.delete(key)
}
