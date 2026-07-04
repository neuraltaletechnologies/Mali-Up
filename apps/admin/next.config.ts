import type { NextConfig } from 'next'

const securityHeaders = [
  { key: 'X-Frame-Options',           value: 'DENY' },
  { key: 'X-Content-Type-Options',    value: 'nosniff' },
  { key: 'X-XSS-Protection',          value: '1; mode=block' },
  { key: 'Referrer-Policy',           value: 'strict-origin-when-cross-origin' },
  { key: 'Permissions-Policy',        value: 'camera=(), microphone=(), geolocation=()' },
  {
    key: 'Strict-Transport-Security',
    value: 'max-age=63072000; includeSubDomains; preload',
  },
  {
    key: 'Content-Security-Policy',
    value: [
      "default-src 'self'",
      "script-src 'self' 'unsafe-inline' 'unsafe-eval' https://apis.google.com https://static.cloudflareinsights.com",
      "style-src 'self' 'unsafe-inline' https://fonts.googleapis.com",
      "font-src 'self' data: https://fonts.gstatic.com",
      "img-src 'self' data: blob: https:",
      "connect-src 'self' https://*.firebaseio.com https://*.googleapis.com wss://*.firebaseio.com https://cloudflareinsights.com",
      "frame-ancestors 'none'",
    ].join('; '),
  },
]

const nextConfig: NextConfig = {
  typescript: {
    ignoreBuildErrors: true,
  },
  // Prevent Turbopack from bundling Node.js-only packages — doing so causes
  // a stack overflow during module-graph traversal (STATUS_STACK_OVERFLOW).
  serverExternalPackages: [
    'firebase-admin',
    '@google-cloud/firestore',
    '@google-cloud/storage',
    'google-auth-library',
    'googleapis',
  ],
  images: {
    remotePatterns: [],
    unoptimized: true,
  },
  async headers() {
    return [
      {
        // Applies to every route — public marketing pages and /api/admin/*
        // previously shipped with no CSP/X-Frame-Options/HSTS at all.
        source: '/:path*',
        headers: securityHeaders,
      },
    ]
  },
}

export default nextConfig
