# Mali Up Website

Mali Up is a Next.js landing page for an Africa-first pocket ERP product. The site is built with React 19, Tailwind CSS 4, shadcn-style UI primitives, and Vercel Analytics.

## What’s In The App

- A landing-page experience with a hero section, feature grid, onboarding flow, app showcase, stats, waitlist form, and footer.
- A light UI theme with brand accents for Mali Up.
- A PNG-based iPhone mockup frame using the asset in [components/ui/phone_035.png](components/ui/phone_035.png).

## Getting Started

Install dependencies and run the dev server:

```bash
pnpm install
pnpm dev
```

Open [http://localhost:3000](http://localhost:3000) in your browser.

## Available Scripts

- `pnpm dev` starts the Next.js development server.
- `pnpm build` creates a production build.
- `pnpm start` runs the production build.
- `pnpm lint` runs ESLint across the repo.

## Project Structure

- [app/page.tsx](app/page.tsx) renders the home page sections.
- [app/layout.tsx](app/layout.tsx) defines metadata and global layout.
- [app/globals.css](app/globals.css) contains the shared theme and utility styles.
- [components/mali/](components/mali) contains the Mali Up sections and page blocks.
- [components/mali/iphone-mockup.tsx](components/mali/iphone-mockup.tsx) renders the new PNG-based phone frame.
- [components/ui/](components/ui) contains reusable UI primitives and the phone frame asset.

## Deployment

The site is optimized for deployment on [Vercel](https://vercel.com).

1. Push your changes to a Git remote (GitHub, GitLab, etc.).
2. Connect the repository to Vercel at [vercel.com](https://vercel.com).
3. Vercel will auto-detect Next.js and deploy with one click.
4. Every push to `main` will automatically trigger a production deployment.

For custom domains or environment variables, configure them in your Vercel project dashboard.

## Notes

- The current homepage is designed as a marketing landing page rather than an authenticated app shell.
- The phone mockup uses the PNG asset directly so screenshots render inside the frame cleanly.
- If you replace assets in [components/ui/](components/ui), keep the frame dimensions consistent with the existing mockup layout.
