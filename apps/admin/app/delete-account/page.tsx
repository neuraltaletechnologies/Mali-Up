import type { Metadata } from 'next'
import { LegalPage, LegalSection } from '@/components/mali/legal-shell'

const BASE_URL = process.env.NEXT_PUBLIC_BASE_URL ?? 'https://maliup.neuraltale.com'

export const metadata: Metadata = {
  title: 'Delete Your Account',
  description:
    'How to request deletion of your Mali Up account and data — what gets deleted, what is retained, and how long it takes.',
  alternates: { canonical: `${BASE_URL}/delete-account` },
}

export default function DeleteAccountPage() {
  return (
    <LegalPage title="Delete Your Account" updated="July 2, 2026">
      <LegalSection title="How to Request Deletion">
        <p>
          Mali Up (published by Neuraltale Technology) lets you request deletion of your account and
          data directly from the app:
        </p>
        <ol className="list-decimal pl-5 space-y-1 mt-2">
          <li>Open the Mali Up app and sign in</li>
          <li>Go to <strong>Settings → Legal &amp; Compliance → Delete Account</strong></li>
          <li>Review what will be deleted, check the confirmation box, and tap <strong>Delete My Account</strong></li>
        </ol>
        <p className="mt-2">
          If you can no longer sign in to the app, email{' '}
          <a href="mailto:privacy@maliup.co.tz" className="text-[#F5A623] hover:underline">
            privacy@maliup.co.tz
          </a>{' '}
          from the address or phone number associated with your account and request deletion. We
          respond within 30 days.
        </p>
      </LegalSection>

      <LegalSection title="What Gets Deleted">
        <ul className="list-disc pl-5 space-y-1">
          <li>All invoices and payment records</li>
          <li>All customer information</li>
          <li>All expense records</li>
          <li>Inventory and stock data</li>
          <li>Account settings and preferences</li>
          <li>Your Mali Up login account (phone number, email, name)</li>
        </ul>
      </LegalSection>

      <LegalSection title="What Is Retained">
        <p>
          Audit logs of account activity may be retained after deletion where required for fraud
          prevention, dispute resolution, or compliance with Tanzanian law (e.g. tax record
          obligations). These logs do not include your business&apos;s financial transaction details
          and are not used for any other purpose.
        </p>
      </LegalSection>

      <LegalSection title="Timing">
        <p>
          Deletion requests are scheduled with a 30-day grace period, during which you can cancel the
          request from Settings. After 30 days, your account and all associated data are permanently
          deleted and cannot be recovered.
        </p>
      </LegalSection>

      <LegalSection title="Your Rights (PDPA)">
        <p>
          This implements your Right to Deletion under Article 19 of Tanzania&apos;s Personal Data
          Protection Act. See our{' '}
          <a href="/privacy" className="text-[#F5A623] hover:underline">
            Privacy Policy
          </a>{' '}
          for the full list of data rights.
        </p>
      </LegalSection>
    </LegalPage>
  )
}
