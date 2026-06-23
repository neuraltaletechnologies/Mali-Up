'use client'

import { useState } from 'react'
import { PageHeader } from '@/components/ui/page-header'
import { signOut } from 'next-auth/react'
import { LogOut, ShieldCheck } from 'lucide-react'

export default function ProfilePage() {
  const [currentPassword, setCurrentPassword] = useState('')
  const [newPassword, setNewPassword] = useState('')

  return (
    <div>
      <PageHeader
        title="My Profile"
        description="Admin account settings and 2FA"
      />

      <div className="max-w-xl flex flex-col gap-4">
        {/* Account info */}
        <div className="rounded-lg border border-[var(--line)] bg-[var(--surface)] p-5">
          <h2 className="text-[14px] font-semibold text-[var(--ink)] mb-4">Account</h2>
          <div className="flex flex-col gap-3">
            <div>
              <label className="text-[12px] font-medium text-[var(--ink-muted)]">Name</label>
              <input
                defaultValue="Julius Ntale"
                className="mt-1 w-full rounded-md border border-[var(--line)] bg-[var(--canvas)] px-3 py-2 text-[13px] text-[var(--ink)] focus:outline-none focus:ring-1 focus:ring-[var(--accent)]"
              />
            </div>
            <div>
              <label className="text-[12px] font-medium text-[var(--ink-muted)]">Email</label>
              <input
                defaultValue="admin@neuraltale.com"
                type="email"
                className="mt-1 w-full rounded-md border border-[var(--line)] bg-[var(--canvas)] px-3 py-2 text-[13px] text-[var(--ink)] focus:outline-none focus:ring-1 focus:ring-[var(--accent)]"
              />
            </div>
            <button className="self-start rounded-md bg-[var(--navy)] px-4 py-2 text-[12px] font-medium text-white hover:bg-[var(--navy-soft)] transition-colors">
              Save changes
            </button>
          </div>
        </div>

        {/* Change password */}
        <div className="rounded-lg border border-[var(--line)] bg-[var(--surface)] p-5">
          <h2 className="text-[14px] font-semibold text-[var(--ink)] mb-4">Change Password</h2>
          <div className="flex flex-col gap-3">
            <div>
              <label className="text-[12px] font-medium text-[var(--ink-muted)]">Current password</label>
              <input
                type="password"
                value={currentPassword}
                onChange={(e) => setCurrentPassword(e.target.value)}
                className="mt-1 w-full rounded-md border border-[var(--line)] bg-[var(--canvas)] px-3 py-2 text-[13px] focus:outline-none focus:ring-1 focus:ring-[var(--accent)]"
              />
            </div>
            <div>
              <label className="text-[12px] font-medium text-[var(--ink-muted)]">New password</label>
              <input
                type="password"
                value={newPassword}
                onChange={(e) => setNewPassword(e.target.value)}
                className="mt-1 w-full rounded-md border border-[var(--line)] bg-[var(--canvas)] px-3 py-2 text-[13px] focus:outline-none focus:ring-1 focus:ring-[var(--accent)]"
              />
            </div>
            <button className="self-start rounded-md bg-[var(--navy)] px-4 py-2 text-[12px] font-medium text-white hover:bg-[var(--navy-soft)] transition-colors">
              Update password
            </button>
          </div>
        </div>

        {/* 2FA */}
        <div className="rounded-lg border border-[var(--line)] bg-[var(--surface)] p-5">
          <div className="flex items-center gap-3 mb-3">
            <ShieldCheck className="h-5 w-5 text-[var(--ink-muted)]" />
            <h2 className="text-[14px] font-semibold text-[var(--ink)]">Two-Factor Authentication</h2>
          </div>
          <p className="text-[13px] text-[var(--ink-muted)] mb-4">
            2FA adds an extra layer of security. Set it up with an authenticator app like Google Authenticator or Authy.
          </p>
          <button className="rounded-md border border-[var(--line)] bg-[var(--canvas)] px-4 py-2 text-[12px] font-medium text-[var(--ink-muted)] hover:text-[var(--ink)] transition-colors">
            Set up 2FA →
          </button>
        </div>

        {/* Sign out */}
        <div className="rounded-lg border border-[var(--line)] bg-[var(--surface)] p-5">
          <h2 className="text-[14px] font-semibold text-[var(--ink)] mb-3">Session</h2>
          <button
            onClick={() => signOut({ callbackUrl: '/login' })}
            className="inline-flex items-center gap-2 rounded-md border border-[var(--status-bad)] bg-[var(--status-bad-bg)] px-4 py-2 text-[12px] font-medium text-[var(--status-bad)] hover:bg-[var(--status-bad)] hover:text-white transition-colors"
          >
            <LogOut className="h-3.5 w-3.5" />
            Sign out
          </button>
        </div>
      </div>
    </div>
  )
}
