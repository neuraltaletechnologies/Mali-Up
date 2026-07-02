import type { Metadata } from 'next'
import { LegalPage, LegalSection } from '@/components/mali/legal-shell'

const BASE_URL = process.env.NEXT_PUBLIC_BASE_URL ?? 'https://maliup.neuraltale.com'

export const metadata: Metadata = {
  title: 'Privacy Policy',
  description:
    'How Mali Up collects, stores, and protects your business data — data residency, encryption, your rights under Tanzania\'s Personal Data Protection Act (PDPA), and how to contact us.',
  alternates: { canonical: `${BASE_URL}/privacy` },
}

export default function PrivacyPolicyPage() {
  return (
    <LegalPage title="Privacy Policy" updated="May 24, 2026">
      <LegalSection title="1. Introduction">
        <p>
          Mali Up (&ldquo;we,&rdquo; &ldquo;us,&rdquo; or &ldquo;our&rdquo;) is operated by Neuraltale
          Technology and provides the Mali Up mobile and web application. This page explains what
          data we collect, how we use it, and the choices you have — in line with Tanzania&apos;s
          Personal Data Protection Act (PDPA).
        </p>
      </LegalSection>

      <LegalSection title="2. Information We Collect">
        <ul className="list-disc pl-5 space-y-1">
          <li>Personal data: phone number, email address, name, account type (business or personal)</li>
          <li>Business data: business details, financial records, inventory, sales, and customer data</li>
          <li>Personal account data: personal wealth, debts, assets, and creditors (personal accounts)</li>
          <li>Device and usage data: device type, operating system, and how the app is used</li>
        </ul>
      </LegalSection>

      <LegalSection title="3. How We Use Your Data">
        <p>We use collected data to provide and improve Mali Up: powering app features, generating your reports, notifying you of important changes, and providing customer support. We never sell your data, and financial amounts are never sent to analytics or crash-reporting tools.</p>
      </LegalSection>

      <LegalSection title="4. Data Residency &amp; Security">
        <p>
          All data is stored in the Africa (Johannesburg) region on Google Cloud Platform and is not
          transferred outside Tanzania without your consent. Data is encrypted in transit (TLS 1.3) and
          at rest. Each business&apos;s data is isolated — no other tenant can access it.
        </p>
      </LegalSection>

      <LegalSection title="5. Your Rights (PDPA)">
        <ul className="list-disc pl-5 space-y-1">
          <li>Right to Access — view all data Mali Up holds about you</li>
          <li>Right to Export — download your data as JSON or CSV</li>
          <li>Right to Delete — permanently delete your account and data</li>
          <li>Right to Correct — update inaccurate information</li>
          <li>Right to Withdraw Consent — change your preferences at any time</li>
        </ul>
        <p>You can exercise these rights any time from Settings → Legal &amp; Compliance in the app.</p>
      </LegalSection>

      <LegalSection title="6. Third-Party Services">
        <p>
          We use Firebase and Google Cloud for authentication, database, and infrastructure hosting.
          These providers are contractually bound to use your data only to deliver services to us.
          With your consent, we also share data with BRELA (business registration verification) and
          M-Pesa Daraja (transaction import).
        </p>
      </LegalSection>

      <LegalSection title="7. Financial Data">
        <p>Your financial records are never logged to analytics services, shared with marketers, used for profiling, or sold to any party.</p>
      </LegalSection>

      <LegalSection title="8. Children&rsquo;s Privacy">
        <p>Mali Up is not intended for anyone under 13. We do not knowingly collect data from children under 13; if we become aware that we have, we delete it and terminate the associated account.</p>
      </LegalSection>

      <LegalSection title="9. Data Retention &amp; Breach Notification">
        <p>
          We retain your data for as long as your account is active or as needed to provide the
          service. If your data is ever compromised, we will notify you within 72 hours, as required
          by the PDPA.
        </p>
      </LegalSection>

      <LegalSection title="10. Changes to This Policy">
        <p>We may update this Privacy Policy from time to time. Significant changes will be communicated by email with at least 30 days&apos; notice, and the &ldquo;Last updated&rdquo; date above will reflect the latest revision.</p>
      </LegalSection>

      <LegalSection title="11. Contact Us">
        <p>
          Questions about this Privacy Policy? Contact us at{' '}
          <a href="mailto:privacy@maliup.co.tz" className="text-[#F5A623] hover:underline">
            privacy@maliup.co.tz
          </a>
          . We respond to requests within 30 days.
        </p>
      </LegalSection>
    </LegalPage>
  )
}
