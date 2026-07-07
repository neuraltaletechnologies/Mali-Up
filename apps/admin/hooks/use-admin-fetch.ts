'use client'

import { useState, useEffect, useCallback, useRef } from 'react'

// Module-level cache: survives component remounts / client-side navigations
const _cache = new Map<string, unknown>()

/** Call on logout to clear stale data so the next user starts fresh */
export function clearAdminCache() {
  _cache.clear()
}

/** Remove specific keys so the next mount fetches fresh data */
export function invalidateAdminCache(keys: string[]) {
  for (const key of keys) _cache.delete(key)
}

interface FetchOptions {
  key?: string
  /** Auto-refetch on this interval (ms). Useful for live dashboard panels. */
  pollingInterval?: number
  /** Skip the focus-triggered refetch if the last fetch is younger than this (ms). */
  minStaleMs?: number
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
  options?: FetchOptions,
): FetchState<T> {
  const key = options?.key
  const pollingInterval = options?.pollingInterval
  const minStaleMs = options?.minStaleMs
  const initial = key ? (_cache.get(key) as T | undefined) ?? null : null

  const [data, setData] = useState<T | null>(initial)
  const [loading, setLoading] = useState(initial === null)
  const [revalidating, setRevalidating] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [tick, setTick] = useState(0)
  const lastFetchedAtRef = useRef(0)

  const refetch = useCallback(() => setTick((t) => t + 1), [])

  // Revalidate whenever the browser tab gains focus — unless data was
  // fetched too recently (avoids doubling up with a running poll interval).
  useEffect(() => {
    function onFocus() {
      if (minStaleMs && Date.now() - lastFetchedAtRef.current < minStaleMs) return
      setTick((t) => t + 1)
    }
    window.addEventListener('focus', onFocus)
    return () => window.removeEventListener('focus', onFocus)
  }, [minStaleMs])

  // Optional polling
  useEffect(() => {
    if (!pollingInterval) return
    const id = setInterval(() => setTick((t) => t + 1), pollingInterval)
    return () => clearInterval(id)
  }, [pollingInterval])

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
          lastFetchedAtRef.current = Date.now()
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
