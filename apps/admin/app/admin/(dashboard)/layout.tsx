import type { Metadata } from 'next'
import { redirect } from 'next/navigation'
import { auth } from '@/lib/auth'
import { Sidebar } from '@/components/layout/sidebar'
import { TopBar } from '@/components/layout/topbar'

export const metadata: Metadata = {
  robots: { index: false, follow: false },
}

export default async function DashboardLayout({ children }: { children: React.ReactNode }) {
  const session = await auth()
  if (!session?.user?.isAdmin) {
    redirect('/admin/login')
  }

  return (
    <div className="min-h-screen bg-[var(--canvas)] text-[var(--ink)] text-[13px]">
      <Sidebar />
      <TopBar />
      <main className="pt-12 lg:pl-[240px]">
        <div className="max-w-[1400px] mx-auto px-4 py-6 sm:px-8 sm:py-8">
          {children}
        </div>
      </main>
    </div>
  )
}
