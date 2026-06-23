'use client'

import { useState, useEffect, useCallback } from 'react'

// Module-level cache: survives component remounts / client-side navigations
const _cache = new Map<string, unknown>()

/** Call on logout to clear stale data so the next user starts fresh */
export function clearAdminCache() {
  _cache.clear()
}

interface FetchState<T> {
  data: T | null
  loading: boolean       // true only on first load when no cached data exists
  revalidating: boolean  // true when refreshing stale cached data in background
  error: string | null
  refetch: () => void
}

export function useAdminFetch<T>(
  fetcher: () => Promise<T>,
  options?: { key?: string },
): FetchState<T> {
  const key = options?.key
  const initial = key ? (_cache.get(key) as T | undefined) ?? null : null

  const [data, setData] = useState<T | null>(initial)
  const [loading, setLoading] = useState(initial === null)
  const [revalidating, setRevalidating] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [tick, setTick] = useState(0)

  const refetch = useCallback(() => setTick((t) => t + 1), [])

  useEffect(() => {
    let cancelled = false
    const hasCached = key ? _cache.has(key) : false

    setError(null)
    if (hasCached) {
      setRevalidating(true)
    } else {
      setLoading(true)
    }

    fetcher()
      .then((result) => {
        if (!cancelled) {
          if (key) _cache.set(key, result)
          setData(result)
          setLoading(false)
          setRevalidating(false)
        }
      })
      .catch((err: Error) => {
        if (!cancelled) {
          setError(err.message)
          setLoading(false)
          setRevalidating(false)
        }
      })

    return () => { cancelled = true }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [tick])

  return { data, loading, revalidating, error, refetch }
}
