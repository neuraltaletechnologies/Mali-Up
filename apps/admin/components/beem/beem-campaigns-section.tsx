'use client'

import { useCallback } from 'react'
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

export function BeemCampaignsSection() {
  const {
    data: statusData,
    loading: statusLoading,
    refetch: refetchStatus,
  } = useAdminFetch(useCallback(() => fetchBeemStatus(), []), {
    key: 'beem-status',
    pollingInterval: 30_000,
  })

  const {
    data: campaignsData,
    loading: campaignsLoading,
    revalidating,
    error: campaignsError,
    refetch: refetchCampaigns,
  } = useAdminFetch(useCallback(() => fetchBeemCampaigns(), []), {
    key: 'beem-sms-campaigns',
    pollingInterval: 15_000,
  })

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

      {/* ── Campaign Composer ── */}
      <BeemCampaignComposer
        businesses={businesses}
        defaultSenderId={statusData?.senderId || 'INFO'}
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
        />
      )}
    </div>
  )
}
