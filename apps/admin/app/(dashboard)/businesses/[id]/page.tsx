'use client'

import { useEffect } from 'react'
import { useRouter } from 'next/navigation'

// This route has been superseded by /businesses/[uid]/[bizId].
// Redirect any stale bookmarks to the businesses list.
export default function LegacyBusinessRoute() {
  const router = useRouter()
  useEffect(() => { router.replace('/businesses') }, [router])
  return null
}
