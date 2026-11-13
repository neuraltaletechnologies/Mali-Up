'use client'

import { useCallback, useEffect, useState } from 'react'
import { PageHeader } from '@/components/ui/page-header'
import { SkeletonTable, RevalidatingBar } from '@/components/ui/skeleton'
import { BeemStatusBar } from './beem-status-bar'
import { BeemCampaignComposer } from './beem-campaign-composer'
import { BeemCampaignsTable } from './beem-campaigns-table'
import {
  fetchBeemCampaigns,
  fetchBeemStatus,
  fetchBusinesses,
  deleteBeemCampaign,
} from '@/lib/admin-api'
import { useAdminFetch } from '@/hooks/use-admin-fetch'
import { AlertCircle } from 'lucide-react'

const ACTIVE_WINDOW_MS = 15 * 60_000

export function BeemCampaignsSection({ afterStatus }: { afterStatus?: React.ReactNode } = {}) {
  const {
    data: statusData,
    loading: statusLoading,
    refetch: refetchStatus,
  } = useAdminFetch(useCallback(() => fetchBeemStatus(), []), {
    // No polling: balance/templates hit Beem's API. Refreshed after a send
    // and via the status bar's refresh button.
    key: 'beem-status',
  })

  // Poll history only while a campaign is mid-send, so the table isn't
  // reloading every few seconds when nothing can change.
  const [hasActiveCampaign, setHasActiveCampaign] = useState(false)

  const {
    data: campaignsData,
    loading: campaignsLoading,
    revalidating,
    error: campaignsError,
    refetch: refetchCampaigns,
  } = useAdminFetch(useCallback(() => fetchBeemCampaigns(), []), {
    key: 'beem-sms-campaigns',
    pollingInterval: hasActiveCampaign ? 15_000 : undefined,
  })

  useEffect(() => {
    // Each poll re-reads the campaign list, so only poll for campaigns that
    // are genuinely in flight: queued/sending AND recent. The sender times out
    // after 9 minutes, so anything older is stuck and polling can't help —
    // without this cutoff one stuck doc polled forever.
    const cutoff = Date.now() - ACTIVE_WINDOW_MS
    setHasActiveCampaign(
      (campaignsData?.campaigns ?? []).some(
        (c) =>
          (c.status === 'queued' || c.status === 'sending') &&
          Date.parse(c.createdAt) > cutoff
      )
    )
  }, [campaignsData])

  const { data: businessData } = useAdminFetch(
    useCallback(() => fetchBusinesses(), []),
    { key: 'businesses' }
  )

  const campaigns = campaignsData?.campaigns ?? []
  const businesses = businessData?.businesses ?? []

  async function handleDeleteCampaign(id: string) {
    try {
      await deleteBeemCampaign(id)
      refetchCampaigns()
    } catch (err) {
      console.error('Failed to delete campaign:', err)
    }
  }

  return (
    <div>
      {/* ── Status Bar (Balance & Live Gateway Connection) ── */}
      <BeemStatusBar
        status={statusData ?? null}
        loading={statusLoading}
        onRefresh={() => {
          refetchStatus()
          refetchCampaigns()
        }}
      />

      {afterStatus}

      {/* ── Campaign Composer ── */}
      <BeemCampaignComposer
        businesses={businesses}
        defaultSenderId={statusData?.senderId || 'Mali Up'}
        onCampaignCreated={() => {
          refetchCampaigns()
          refetchStatus()
        }}
      />

      {/* ── Campaign History ── */}
      <div className="mb-3 flex items-center justify-between">
        <PageHeader
          title="SMS Campaign History"
          description="Track dispatched and scheduled SMS campaigns via Beem Africa."
        />
      </div>

      {revalidating && <RevalidatingBar />}

      {campaignsLoading ? (
        <SkeletonTable rows={5} cols={4} />
      ) : campaignsError && !campaignsData ? (
        <div className="flex items-center gap-3 rounded-lg border border-[var(--status-bad)] bg-[var(--status-bad-bg)] p-4 text-[var(--status-bad)]">
          <AlertCircle className="h-4 w-4 shrink-0" />
          <span className="text-[13px]">{campaignsError}</span>
        </div>
      ) : (
        <BeemCampaignsTable
          campaigns={campaigns}
          onDeleteCampaign={handleDeleteCampaign}
          onCampaignResent={refetchCampaigns}
        />
      )}
    </div>
  )
}
