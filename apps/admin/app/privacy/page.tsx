import type { Metadata } from 'next'
import { LegalPage, LegalSection } from '@/components/mali/legal-shell'

const BASE_URL = process.env.NEXT_PUBLIC_BASE_URL ?? 'https://maliup.neuraltale.com'

export const metadata: Metadata = {
  title: 'Privacy Policy',
  description:
    'How Mali Up collects, uses, stores, and protects account and business data, and how users can exercise their privacy rights.',
  alternates: { canonical: `${BASE_URL}/privacy` },
}

export default function PrivacyPolicyPage() {
  return (
    <LegalPage title="Privacy Policy" updated="July 17, 2026">
      <LegalSection title="1. Introduction">
        <p>
          Mali Up (&ldquo;we,&rdquo; &ldquo;us,&rdquo; or &ldquo;our&rdquo;) is operated by
          Neuraltale Technology and provides the Mali Up business-management application. This
          policy explains what data we handle, why we handle it, and the choices available to you.
        </p>
      </LegalSection>

      <LegalSection title="2. Information We Collect">
        <ul className="list-disc pl-5 space-y-1">
          <li>Account data: name, phone number, email address, language, role, and account settings</li>
          <li>Business data: business details, financial records, inventory, sales, customer data, debts, and reports</li>
          <li>Files and images you choose: receipt photos and business logos</li>
          <li>Contacts you choose to import as customers, including names and phone numbers</li>
          <li>Device and usage data: device type, operating system, app diagnostics, security verdicts, and feature events</li>
        </ul>
      </LegalSection>

      <LegalSection title="3. How We Use Your Data">
        <p>
          We use this data to authenticate users, sync and back up business records, generate
          reports, enforce team permissions, protect accounts, diagnose failures, provide support,
          and improve Mali Up. We do not sell personal or sensitive data.
        </p>
      </LegalSection>

      <LegalSection title="4. Device Permissions">
        <p>
          Camera access is used only when you scan a barcode or capture a receipt or logo. Contacts
          access is requested only when you choose to import customers. Mali Up does not request
          precise or approximate location, SMS, or call-log permissions.
        </p>
      </LegalSection>

      <LegalSection title="5. Storage &amp; Security">
        <p>
          Data is transmitted over encrypted HTTPS connections and stored using Google Cloud and
          Firebase security controls. Access is restricted by authenticated user and business role.
          Service providers may process data in countries where they operate, subject to contractual
          and legal safeguards.
        </p>
      </LegalSection>

      <LegalSection title="6. Your Rights">
        <ul className="list-disc pl-5 space-y-1">
          <li>Access and review data associated with your account</li>
          <li>Correct inaccurate account and business information</li>
          <li>Export supported records from the app</li>
          <li>Withdraw optional permissions through device or app settings</li>
          <li>Delete your account and associated data</li>
        </ul>
      </LegalSection>

      <LegalSection title="7. Service Providers">
        <p>
          Firebase and Google Cloud provide authentication, database, file storage, Cloud Functions,
          and Play Integrity security services. Sentry receives limited crash, performance, and
          non-financial feature diagnostics when configured. Cloudflare hosts this public website.
          These providers process data only to deliver their services. Mali Up does not currently
          integrate a third-party AI service.
        </p>
      </LegalSection>

      <LegalSection title="8. Financial Data">
        <p>
          Financial records are used to provide the business features you request. Financial amounts
          are not sent to Sentry, used for advertising or profiling, shared with marketers, or sold.
        </p>
      </LegalSection>

      <LegalSection title="9. Children&rsquo;s Privacy">
        <p>
          Mali Up is a business-management service intended for adults aged 18 and over. It does not
          provide anonymous or random chat and is not directed to children.
        </p>
      </LegalSection>

      <LegalSection title="10. Data Retention &amp; Deletion">
        <p>
          We retain data while your account is active and as needed to provide the service. You can
          permanently delete a signed-in account from Settings, or request deletion at{' '}
          <a href="/delete-account" className="text-[#F5A623] hover:underline">
            our account deletion page
          </a>
          . Limited records may be retained when required for security, fraud prevention, dispute
          resolution, bookkeeping, or legal compliance, and only for those purposes.
        </p>
      </LegalSection>

      <LegalSection title="11. Changes to This Policy">
        <p>
          We may update this Privacy Policy from time to time. The &ldquo;Last updated&rdquo; date
          above will reflect the latest revision, and material changes will be communicated through
          an appropriate in-app or account channel.
        </p>
      </LegalSection>

      <LegalSection title="12. Contact Us">
        <p>
          Questions or privacy requests can be sent to{' '}
          <a href="mailto:support@neuraltale.com" className="text-[#F5A623] hover:underline">
            support@neuraltale.com
          </a>
          .
        </p>
      </LegalSection>
    </LegalPage>
  )
}
