import type { Metadata } from 'next'
import Script from 'next/script'
import { Nav } from "@/components/mali/nav"
import { Hero } from "@/components/mali/hero"
import { Features } from "@/components/mali/features"
import { HowItWorks } from "@/components/mali/how-it-works"
import { PhoneShowcase } from "@/components/mali/phone-showcase"
import { AppGallery } from "@/components/mali/app-gallery"
import { Stats } from "@/components/mali/stats"
import { Download } from "@/components/mali/download"
import { Footer } from "@/components/mali/footer"

const BASE_URL = process.env.NEXT_PUBLIC_BASE_URL ?? 'https://maliup.neuraltale.com'
const PLAY_STORE_URL = 'https://play.google.com/store/apps/details?id=com.neuraltale.maliup'

export const metadata: Metadata = {
  title: 'Mali Up — Programu ya Biashara Tanzania | Mauzo, Ankara, Bidhaa',
  description:
    'Simamia biashara yako yote kutoka simu moja. Mali Up ni ERP ya kwanza ya Tanzania — mauzo, ankara, bidhaa, fedha, wateja na takwimu. Inafanya kazi 3G. Imetengenezwa Dar es Salaam na Neuraltale Technology.',
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
      ],
      sameAs: [
        'https://twitter.com/neuraltale',
        'https://linkedin.com/company/neuraltale',
      ],
    },
    {
      '@type': 'MobileApplication',
      '@id': `${BASE_URL}/#app`,
      name: 'Mali Up',
      alternateName: 'MaliUp',
      description:
        'ERP ya simu kwa biashara ndogo za Tanzania — mauzo, ankara, bidhaa, fedha na wateja katika programu moja.',
      applicationCategory: 'BusinessApplication',
      operatingSystem: ['Android', 'iOS'],
      installUrl: PLAY_STORE_URL,
      downloadUrl: PLAY_STORE_URL,
      offers: {
        '@type': 'Offer',
        price: '0',
        priceCurrency: 'TZS',
        availability: 'https://schema.org/InStock',
      },
      creator: { '@id': `${BASE_URL}/#org` },
      inLanguage: ['sw', 'en'],
      countryOfOrigin: { '@type': 'Country', name: 'Tanzania' },
      url: BASE_URL,
      image: `${BASE_URL}/app-dashboard.jpg`,
      featureList: [
        'Mauzo na POS',
        'Ankara za Haraka',
        'Udhibiti wa Bidhaa',
        'Fedha na Uhasibu',
        'CRM ya Wateja',
        'Takwimu za Biashara',
        'Biashara Nyingi',
        'Inafanya kazi 3G',
      ],
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
      about: { '@id': `${BASE_URL}/#app` },
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
        <AppGallery />
        <Stats />
        <Download />
        <Footer />
      </main>
    </>
  )
}
