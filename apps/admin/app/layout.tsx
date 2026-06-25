import type { Metadata } from 'next'
import { Providers } from './providers'
import './globals.css'

const BASE_URL = process.env.NEXT_PUBLIC_BASE_URL ?? 'https://maliup.neuraltale.com'

export const metadata: Metadata = {
  metadataBase: new URL(BASE_URL),
  title: {
    default: 'Mali Up — Programu ya Biashara Tanzania',
    template: '%s | Mali Up',
  },
  description:
    'Mali Up ni mfumo wa ERP wa simu kwa biashara ndogo za Tanzania. Simamia mauzo, ankara, bidhaa, fedha na wateja wako kutoka simu moja. Imeundwa na Neuraltale Technology, Dar es Salaam.',
  keywords: [
    'biashara Tanzania',
    'software biashara ndogo Tanzania',
    'ERP Tanzania',
    'mfumo wa biashara',
    'Mali Up',
    'Neuraltale',
    'accounting app Tanzania',
    'invoice Tanzania',
    'inventory Tanzania',
    'POS Tanzania',
    'business app Tanzania',
    'SME software Tanzania',
    'Dar es Salaam business app',
    'Swahili business app',
    'mauzo app Tanzania',
    'bidhaa app Tanzania',
    'fedha app Tanzania',
  ],
  authors: [{ name: 'Neuraltale Technology', url: 'https://neuraltale.com' }],
  creator: 'Neuraltale Technology',
  publisher: 'Neuraltale Technology',
  alternates: {
    canonical: BASE_URL,
    languages: {
      'sw-TZ': BASE_URL,
      'en-TZ': `${BASE_URL}/en`,
    },
  },
  openGraph: {
    type: 'website',
    locale: 'sw_TZ',
    url: BASE_URL,
    siteName: 'Mali Up',
    title: 'Mali Up — Programu ya Biashara Tanzania',
    description:
      'ERP ya simu kwa biashara ndogo za Tanzania. Mauzo, ankara, bidhaa, fedha — katika programu moja.',
    images: [
      {
        url: '/og-image.jpg',
        width: 1200,
        height: 630,
        alt: 'Mali Up — Tanzania Business App',
      },
    ],
  },
  twitter: {
    card: 'summary_large_image',
    title: 'Mali Up — Programu ya Biashara Tanzania',
    description:
      'ERP ya simu kwa biashara ndogo za Tanzania. Mauzo, ankara, bidhaa, fedha — katika programu moja.',
    images: ['/og-image.jpg'],
    creator: '@neuraltale',
  },
  icons: {
    icon: [
      { url: '/icon-dark-32x32.png', sizes: '32x32', type: 'image/png' },
      { url: '/icon.svg', type: 'image/svg+xml' },
    ],
    apple: '/apple-icon.png',
  },
  category: 'business',
}

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="sw" suppressHydrationWarning>
      <head>
        <link rel="preconnect" href="https://fonts.googleapis.com" />
        <link rel="preconnect" href="https://fonts.gstatic.com" crossOrigin="anonymous" />
        <link
          href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap"
          rel="stylesheet"
        />
      </head>
      <body>
        <Providers>{children}</Providers>
      </body>
    </html>
  )
}
