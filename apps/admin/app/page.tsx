import type { Metadata } from 'next'
import Script from 'next/script'
import { Nav } from "@/components/mali/nav"
import { Hero } from "@/components/mali/hero"
import { Features } from "@/components/mali/features"
import { HowItWorks } from "@/components/mali/how-it-works"
import { PhoneShowcase } from "@/components/mali/phone-showcase"
import { Pricing } from "@/components/mali/pricing"
import { AppGallery } from "@/components/mali/app-gallery"
import { Stats } from "@/components/mali/stats"
import { Download } from "@/components/mali/download"
import { Footer } from "@/components/mali/footer"

const BASE_URL = process.env.NEXT_PUBLIC_BASE_URL ?? 'https://maliup.neuraltale.com'
const PLAY_STORE_URL = 'https://play.google.com/store/apps/details?id=com.neuraltale.maliup'

export const metadata: Metadata = {
  title: 'Mali Up — Programu ya Biashara Tanzania | Mauzo, Ankara, Bidhaa na Bei',
  description:
    'Simamia biashara yako yote kutoka simu moja. Mali Up ni mfumo wa ERP wa simu Tanzania — mauzo na POS, ankara, stoo ya bidhaa, fedha, wateja na ripoti. Inafanya kazi 3G na offline. Imetengenezwa Dar es Salaam na Neuraltale Technology.',
  alternates: { canonical: BASE_URL },
}

const jsonLd = {
  '@context': 'https://schema.org',
  '@graph': [
    {
      '@type': 'Organization',
      '@id': `${BASE_URL}/#org`,
      name: 'Neuraltale Technology',
      url: 'https://neuraltale.com',
      logo: {
        '@type': 'ImageObject',
        url: `${BASE_URL}/maliup-logo.png`,
      },
      address: {
        '@type': 'PostalAddress',
        addressLocality: 'Dar es Salaam',
        addressRegion: 'Dar es Salaam',
        addressCountry: 'TZ',
      },
      areaServed: [
        { '@type': 'Country', name: 'Tanzania' },
        { '@type': 'City', name: 'Dar es Salaam' },
        { '@type': 'City', name: 'Mwanza' },
        { '@type': 'City', name: 'Arusha' },
        { '@type': 'City', name: 'Dodoma' },
        { '@type': 'City', name: 'Mbeya' },
        { '@type': 'City', name: 'Zanzibar' },
      ],
      sameAs: [
        'https://twitter.com/neuraltale',
        'https://linkedin.com/company/neuraltale',
      ],
    },
    {
      '@type': ['Product', 'SoftwareApplication'],
      '@id': `${BASE_URL}/#product`,
      name: 'Mali Up Business Management App',
      alternateName: ['Mali Up ERP', 'Programu ya Biashara Mali Up'],
      description:
        'Mfumo kamili wa ERP na POS wa simu kwa biashara ndogo na za kati Tanzania. Simamia mauzo, ankara, udhibiti wa bidhaa, rekodi za fedha na wateja.',
      applicationCategory: 'BusinessApplication, FinanceApplication, PointOfSale',
      operatingSystem: ['Android', 'iOS', 'Web'],
      brand: { '@id': `${BASE_URL}/#org` },
      url: BASE_URL,
      image: `${BASE_URL}/app-dashboard.jpg`,
      installUrl: PLAY_STORE_URL,
      downloadUrl: PLAY_STORE_URL,
      countryOfOrigin: { '@type': 'Country', name: 'Tanzania' },
      inLanguage: ['sw', 'en'],
      hasOfferCatalog: {
        '@type': 'OfferCatalog',
        name: 'Mali Up Subscription Plans',
        itemListElement: [
          {
            '@type': 'Offer',
            name: 'Starter Plan (Bure)',
            description: 'Mpango wa bure milele kwa wanaoanza biashara. Mauzo ya msingi, risiti za kidigitali na inafanya kazi bila intaneti.',
            price: '0',
            priceCurrency: 'TZS',
            availability: 'https://schema.org/InStock',
            priceValidUntil: '2028-12-31',
            url: `${BASE_URL}/pay?plan=starter`,
          },
          {
            '@type': 'Offer',
            name: 'Growth Plan',
            description: 'Kwa biashara zinazokua. Mauzo bila kikomo, mapato na matumizi, ripoti kamili, M-Pesa na watumiaji 3. TSh 6,000 kwa mwezi au TSh 60,000 kwa mwaka.',
            price: '6000',
            priceCurrency: 'TZS',
            priceSpecification: [
              { '@type': 'UnitPriceSpecification', price: '6000', priceCurrency: 'TZS', billingDuration: 'P1M' },
              { '@type': 'UnitPriceSpecification', price: '60000', priceCurrency: 'TZS', billingDuration: 'P1Y' },
            ],
            availability: 'https://schema.org/InStock',
            priceValidUntil: '2028-12-31',
            url: `${BASE_URL}/pay?plan=growth`,
          },
          {
            '@type': 'Offer',
            name: 'Business Plan',
            description: 'Kwa biashara zenye matawi mengi na wafanyakazi hadi 10. Matawi mengi, ripoti zote na msaada wa kipaumbele. TSh 8,000 kwa mwezi au TSh 80,000 kwa mwaka.',
            price: '8000',
            priceCurrency: 'TZS',
            priceSpecification: [
              { '@type': 'UnitPriceSpecification', price: '8000', priceCurrency: 'TZS', billingDuration: 'P1M' },
              { '@type': 'UnitPriceSpecification', price: '80000', priceCurrency: 'TZS', billingDuration: 'P1Y' },
            ],
            availability: 'https://schema.org/InStock',
            priceValidUntil: '2028-12-31',
            url: `${BASE_URL}/pay?plan=business`,
          },
        ],
      },
      featureList: [
        'Mauzo na POS (Point of Sale)',
        'Ankara za Kitaalamu na Risiti za Kidigitali',
        'Udhibiti wa Bidhaa na Stoo (Inventory)',
        'Ripoti za Fedha na Uhasibu (P&L, Cash Flow)',
        'Usimamizi wa Wateja na Madeni (CRM)',
        'Upatanisho wa M-Pesa na Benki',
        'Usimamizi wa Matawi Mengi (Multi-Location)',
        'Inafanya kazi bila Intaneti (Offline 3G)',
      ],
    },
    {
      '@type': 'Service',
      '@id': `${BASE_URL}/#service-pos`,
      name: 'Mauzo & POS Service',
      provider: { '@id': `${BASE_URL}/#org` },
      description: 'Huduma ya mauzo ya haraka, kutoa risiti za kidigitali, na ufuatiliaji wa mauzo ya kila siku madukani.',
      areaServed: { '@type': 'Country', name: 'Tanzania' },
    },
    {
      '@type': 'Service',
      '@id': `${BASE_URL}/#service-invoicing`,
      name: 'Smart Invoicing & Billing',
      provider: { '@id': `${BASE_URL}/#org` },
      description: 'Kutengeneza na kutuma ankara za kitaalamu kwa wateja kwa shilingi ya Tanzania (TSh) na kufuatilia malipo.',
      areaServed: { '@type': 'Country', name: 'Tanzania' },
    },
    {
      '@type': 'Service',
      '@id': `${BASE_URL}/#service-inventory`,
      name: 'Inventory & Stock Control',
      provider: { '@id': `${BASE_URL}/#org` },
      description: 'Kusimamia stoo ya bidhaa, kupata taarifa za bidhaa zilizokaribia kuisha, na kuhamisha bidhaa kati ya maduka.',
      areaServed: { '@type': 'Country', name: 'Tanzania' },
    },
    {
      '@type': 'Service',
      '@id': `${BASE_URL}/#service-accounting`,
      name: 'Finance & SME Accounting',
      provider: { '@id': `${BASE_URL}/#org` },
      description: 'Ufuatiliaji wa mapato, matumizi, mtiririko wa fedha, na ripoti za faida na hasara kwa biashara za Tanzania.',
      areaServed: { '@type': 'Country', name: 'Tanzania' },
    },
    {
      '@type': 'WebSite',
      '@id': `${BASE_URL}/#website`,
      url: BASE_URL,
      name: 'Mali Up',
      description: 'Programu ya biashara ya Tanzania',
      publisher: { '@id': `${BASE_URL}/#org` },
      inLanguage: 'sw',
    },
    {
      '@type': 'WebPage',
      '@id': `${BASE_URL}/#webpage`,
      url: BASE_URL,
      name: 'Mali Up — Programu ya Biashara Tanzania',
      isPartOf: { '@id': `${BASE_URL}/#website` },
      about: { '@id': `${BASE_URL}/#product` },
      description:
        'Simamia biashara yako yote kutoka simu moja. Mauzo, ankara, bidhaa, fedha — katika programu moja.',
      inLanguage: 'sw',
      speakable: {
        '@type': 'SpeakableSpecification',
        cssSelector: ['h1', 'h2', '.hero-desc'],
      },
    },
  ],
}

export default function HomePage() {
  return (
    <>
      <Script
        id="ld-json"
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }}
        strategy="beforeInteractive"
      />
      <main style={{ backgroundColor: "#FFFFFF" }}>
        <Nav />
        <Hero />
        <Features />
        <HowItWorks />
        <PhoneShowcase />
        <Pricing />
        <AppGallery />
        <Stats />
        <Download />
        <Footer />
      </main>
    </>
  )
}
