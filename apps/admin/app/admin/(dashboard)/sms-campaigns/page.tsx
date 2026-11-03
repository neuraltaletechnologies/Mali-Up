'use client'

import { PageHeader } from '@/components/ui/page-header'
import { BeemCampaignsSection } from '@/components/beem/beem-campaigns-section'
import { BeemAutoCampaigns } from '@/components/beem/beem-auto-campaigns'

export default function SmsCampaignsPage() {
  return (
    <div>
      <PageHeader
        title="Beem SMS Campaigns"
        description="Send or schedule SMS campaigns to Mali Up users through Beem Africa, and set up holiday greetings that go out automatically every year."
      />
      <BeemCampaignsSection afterStatus={<BeemAutoCampaigns />} />
    </div>
  )
}
