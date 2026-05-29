/** @type {import('next').NextConfig} */
const nextConfig = {
  // "output: export" removed — admin portal requires SSR (NextAuth API routes + dynamic server components)
  typescript: {
    ignoreBuildErrors: true,
  },
  images: {
    unoptimized: true,
  },
}

export default nextConfig
