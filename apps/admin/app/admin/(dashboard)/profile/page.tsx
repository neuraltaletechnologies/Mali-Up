'use client'

import { useState, useEffect, useCallback } from 'react'
import { useSession, signOut } from 'next-auth/react'
import {
  EmailAuthProvider,
  reauthenticateWithCredential,
  updatePassword,
  verifyBeforeUpdateEmail,
  onAuthStateChanged,
  TotpMultiFactorGenerator,
  multiFactor,
  type User as FirebaseUser,
  type TotpSecret,
} from 'firebase/auth'
import { getFirebaseAuth } from '@/lib/firebase-client'
import { PageHeader } from '@/components/ui/page-header'
import {
  LogOut, ShieldCheck, Eye, EyeOff, Check, AlertCircle,
  Loader2, Copy, CheckCheck, KeyRound, X,
} from 'lucide-react'

// ── shared UI helpers ─────────────────────────────────────────────────────────

function PasswordInput({
  value,
  onChange,
  placeholder = '••••••••',
  autoComplete,
  disabled,
}: {
  value: string
  onChange: (v: string) => void
  placeholder?: string
  autoComplete?: string
  disabled?: boolean
}) {
  const [show, setShow] = useState(false)
  return (
    <div className="relative">
      <input
        type={show ? 'text' : 'password'}
        value={value}
        onChange={(e) => onChange(e.target.value)}
        placeholder={placeholder}
        autoComplete={autoComplete}
        disabled={disabled}
        className="w-full rounded-md border border-[var(--line)] bg-[var(--canvas)] px-3 py-2 pr-9 text-[13px] text-[var(--ink)] focus:outline-none focus:ring-1 focus:ring-[var(--accent)] disabled:opacity-50"
      />
      <button
        type="button"
        onClick={() => setShow((s) => !s)}
        tabIndex={-1}
        className="absolute right-2.5 top-1/2 -translate-y-1/2 text-[var(--ink-muted)] hover:text-[var(--ink)]"
      >
        {show ? <EyeOff className="h-3.5 w-3.5" /> : <Eye className="h-3.5 w-3.5" />}
      </button>
    </div>
  )
}

function Toast({ ok, text }: { ok: boolean; text: string }) {
  if (!text) return null
  return (
    <div
      className={`flex items-start gap-2 rounded-md px-3 py-2 text-[12px] ${
        ok
          ? 'bg-[var(--status-ok-bg,#e6f9f0)] text-[var(--status-ok,#16a34a)]'
          : 'bg-[var(--status-bad-bg,#fef2f2)] text-[var(--status-bad,#dc2626)]'
      }`}
    >
      {ok ? (
        <Check className="h-3.5 w-3.5 shrink-0 mt-0.5" />
      ) : (
        <AlertCircle className="h-3.5 w-3.5 shrink-0 mt-0.5" />
      )}
      <span>{text}</span>
    </div>
  )
}

function Card({ children, className = '' }: { children: React.ReactNode; className?: string }) {
  return (
    <div className={`rounded-lg border border-[var(--line)] bg-[var(--surface)] p-5 ${className}`}>
      {children}
    </div>
  )
}

function CardTitle({ children }: { children: React.ReactNode }) {
  return <h2 className="text-[14px] font-semibold text-[var(--ink)] mb-4">{children}</h2>
}

function Label({ children }: { children: React.ReactNode }) {
  return <label className="text-[12px] font-medium text-[var(--ink-muted)]">{children}</label>
}

function SubmitBtn({
  loading,
  disabled,
  children,
}: {
  loading?: boolean
  disabled?: boolean
  children: React.ReactNode
}) {
  return (
    <button
      type="submit"
      disabled={loading || disabled}
      className="self-start inline-flex items-center gap-2 rounded-md bg-[var(--navy)] px-4 py-2 text-[12px] font-medium text-white hover:bg-[var(--navy-soft)] transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
    >
      {loading && <Loader2 className="h-3.5 w-3.5 animate-spin" />}
      {children}
    </button>
  )
}

// ── TOTP helpers ───────────────────────────────────────────────────────────────

const TOTP_FACTOR_ID = 'totp'

function isTotpEnrolled(user: FirebaseUser): boolean {
  try {
    return multiFactor(user).enrolledFactors.some((f) => f.factorId === TOTP_FACTOR_ID)
  } catch {
    return false
  }
}

// ── main page ─────────────────────────────────────────────────────────────────

export default function ProfilePage() {
  const { data: session, update: updateSession } = useSession()
  const [firebaseUser, setFirebaseUser] = useState<FirebaseUser | null>(null)
  const [fbReady, setFbReady] = useState(false)

  // ── name ──────────────────────────────────────────────────────────────────
  const [name, setName] = useState('')
  const [savingName, setSavingName] = useState(false)
  const [nameMsg, setNameMsg] = useState({ ok: true, text: '' })

  // ── email ─────────────────────────────────────────────────────────────────
  const [newEmail, setNewEmail] = useState('')
  const [emailPwd, setEmailPwd] = useState('')
  const [changingEmail, setChangingEmail] = useState(false)
  const [emailMsg, setEmailMsg] = useState({ ok: true, text: '' })

  // ── password ──────────────────────────────────────────────────────────────
  const [currentPwd, setCurrentPwd] = useState('')
  const [newPwd, setNewPwd] = useState('')
  const [confirmPwd, setConfirmPwd] = useState('')
  const [changingPwd, setChangingPwd] = useState(false)
  const [pwdMsg, setPwdMsg] = useState({ ok: true, text: '' })

  // ── 2FA ───────────────────────────────────────────────────────────────────
  const [totpEnrolled, setTotpEnrolled] = useState(false)
  const [totpStep, setTotpStep] = useState<'idle' | 'show-secret' | 'verify'>('idle')
  const [totpSecret, setTotpSecret] = useState<TotpSecret | null>(null)
  const [totpCode, setTotpCode] = useState('')
  const [twoFALoading, setTwoFALoading] = useState(false)
  const [twoFAMsg, setTwoFAMsg] = useState({ ok: true, text: '' })
  const [copied, setCopied] = useState(false)

  // ── init Firebase Auth state ──────────────────────────────────────────────
  useEffect(() => {
    const unsub = onAuthStateChanged(getFirebaseAuth(), (user) => {
      setFirebaseUser(user)
      setFbReady(true)
      if (user) setTotpEnrolled(isTotpEnrolled(user))
    })
    return unsub
  }, [])

  useEffect(() => {
    if (session?.user?.name) setName(session.user.name)
  }, [session?.user?.name])

  // ── handlers ──────────────────────────────────────────────────────────────

  async function handleSaveName(e: React.FormEvent) {
    e.preventDefault()
    if (!name.trim()) return
    setSavingName(true)
    setNameMsg({ ok: true, text: '' })
    try {
      const res = await fetch('/api/admin/me', {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ name: name.trim() }),
      })
      const data = await res.json() as { ok?: boolean; error?: string }
      if (!res.ok) throw new Error(data.error ?? 'Failed')
      await updateSession({ user: { ...session?.user, name: name.trim() } })
      setNameMsg({ ok: true, text: 'Name updated successfully.' })
    } catch (err) {
      setNameMsg({ ok: false, text: err instanceof Error ? err.message : 'Failed to update name.' })
    } finally {
      setSavingName(false)
    }
  }

  async function handleChangeEmail(e: React.FormEvent) {
    e.preventDefault()
    if (!firebaseUser || !newEmail.trim() || !emailPwd) return
    setChangingEmail(true)
    setEmailMsg({ ok: true, text: '' })
    try {
      const credential = EmailAuthProvider.credential(firebaseUser.email!, emailPwd)
      await reauthenticateWithCredential(firebaseUser, credential)
      await verifyBeforeUpdateEmail(firebaseUser, newEmail.trim().toLowerCase())
      setEmailMsg({
        ok: true,
        text: `Verification email sent to ${newEmail.trim()}. Click the link in that email to confirm the change.`,
      })
      setNewEmail('')
      setEmailPwd('')
    } catch (err: unknown) {
      const code = (err as { code?: string }).code ?? ''
      const messages: Record<string, string> = {
        'auth/wrong-password':       'Incorrect current password.',
        'auth/invalid-credential':   'Incorrect current password.',
        'auth/email-already-in-use': 'That email is already in use.',
        'auth/invalid-email':        'Invalid email address.',
        'auth/requires-recent-login': 'Session expired. Sign out and sign in again, then retry.',
      }
      setEmailMsg({ ok: false, text: messages[code] ?? 'Failed to update email.' })
    } finally {
      setChangingEmail(false)
    }
  }

  async function handleChangePassword(e: React.FormEvent) {
    e.preventDefault()
    if (!firebaseUser || !currentPwd || !newPwd) return
    if (newPwd !== confirmPwd) {
      setPwdMsg({ ok: false, text: 'New passwords do not match.' })
      return
    }
    if (newPwd.length < 8) {
      setPwdMsg({ ok: false, text: 'New password must be at least 8 characters.' })
      return
    }
    setChangingPwd(true)
    setPwdMsg({ ok: true, text: '' })
    try {
      const credential = EmailAuthProvider.credential(firebaseUser.email!, currentPwd)
      await reauthenticateWithCredential(firebaseUser, credential)
      await updatePassword(firebaseUser, newPwd)
      setPwdMsg({ ok: true, text: 'Password updated successfully.' })
      setCurrentPwd('')
      setNewPwd('')
      setConfirmPwd('')
    } catch (err: unknown) {
      const code = (err as { code?: string }).code ?? ''
      const messages: Record<string, string> = {
        'auth/wrong-password':       'Incorrect current password.',
        'auth/invalid-credential':   'Incorrect current password.',
        'auth/weak-password':        'New password is too weak. Use at least 8 characters.',
        'auth/requires-recent-login': 'Session expired. Sign out and sign in again, then retry.',
      }
      setPwdMsg({ ok: false, text: messages[code] ?? 'Failed to update password.' })
    } finally {
      setChangingPwd(false)
    }
  }

  const handleStartTotpSetup = useCallback(async () => {
    if (!firebaseUser) return
    setTwoFALoading(true)
    setTwoFAMsg({ ok: true, text: '' })
    try {
      const mfaSession = await multiFactor(firebaseUser).getSession()
      const secret = await TotpMultiFactorGenerator.generateSecret(mfaSession)
      setTotpSecret(secret)
      setTotpStep('show-secret')
    } catch (err: unknown) {
      const code = (err as { code?: string }).code ?? ''
      if (code === 'auth/requires-recent-login') {
        setTwoFAMsg({ ok: false, text: 'Sign out and sign back in before enabling 2FA.' })
      } else if (code === 'auth/unsupported-first-factor' || code === 'auth/operation-not-supported-in-this-environment') {
        setTwoFAMsg({
          ok: false,
          text: 'TOTP 2FA requires Google Cloud Identity Platform. Upgrade your Firebase project to enable it.',
        })
      } else {
        setTwoFAMsg({ ok: false, text: 'Could not start 2FA setup. Try again.' })
        console.error('[2FA setup]', err)
      }
    } finally {
      setTwoFALoading(false)
    }
  }, [firebaseUser])

  async function handleVerifyTotp(e: React.FormEvent) {
    e.preventDefault()
    if (!firebaseUser || !totpSecret || !totpCode) return
    setTwoFALoading(true)
    setTwoFAMsg({ ok: true, text: '' })
    try {
      const assertion = TotpMultiFactorGenerator.assertionForEnrollment(totpSecret, totpCode)
      await multiFactor(firebaseUser).enroll(assertion, 'Authenticator App')
      setTotpEnrolled(true)
      setTotpStep('idle')
      setTotpSecret(null)
      setTotpCode('')
      setTwoFAMsg({ ok: true, text: '2FA enabled successfully. Your account is now protected.' })
    } catch (err: unknown) {
      const code = (err as { code?: string }).code ?? ''
      if (code === 'auth/invalid-verification-code') {
        setTwoFAMsg({ ok: false, text: 'Incorrect code. Check your authenticator app and try again.' })
      } else {
        setTwoFAMsg({ ok: false, text: 'Failed to verify code. Please try again.' })
        console.error('[2FA verify]', err)
      }
    } finally {
      setTwoFALoading(false)
    }
  }

  async function handleDisableTotp() {
    if (!firebaseUser) return
    setTwoFALoading(true)
    setTwoFAMsg({ ok: true, text: '' })
    try {
      const factors = multiFactor(firebaseUser).enrolledFactors
      const totpFactor = factors.find((f) => f.factorId === TOTP_FACTOR_ID)
      if (totpFactor) await multiFactor(firebaseUser).unenroll(totpFactor)
      setTotpEnrolled(false)
      setTwoFAMsg({ ok: true, text: '2FA disabled.' })
    } catch (err: unknown) {
      const code = (err as { code?: string }).code ?? ''
      if (code === 'auth/requires-recent-login') {
        setTwoFAMsg({ ok: false, text: 'Sign out and sign back in before disabling 2FA.' })
      } else {
        setTwoFAMsg({ ok: false, text: 'Failed to disable 2FA. Try again.' })
        console.error('[2FA disable]', err)
      }
    } finally {
      setTwoFALoading(false)
    }
  }

  function handleCopySecret() {
    if (!totpSecret) return
    const key = totpSecret.secretKey
    navigator.clipboard.writeText(key).then(() => {
      setCopied(true)
      setTimeout(() => setCopied(false), 2000)
    })
  }

  const notReady = !fbReady || !firebaseUser

  return (
    <div>
      <PageHeader title="Settings" description="Manage your admin account details and security" />

      <div className="max-w-xl flex flex-col gap-4">

        {/* ── Account Details ─────────────────────────────────────────────────── */}
        <Card>
          <CardTitle>Account Details</CardTitle>
          <form onSubmit={handleSaveName} className="flex flex-col gap-3">
            <div>
              <Label>Display name</Label>
              <input
                value={name}
                onChange={(e) => setName(e.target.value)}
                className="mt-1 w-full rounded-md border border-[var(--line)] bg-[var(--canvas)] px-3 py-2 text-[13px] text-[var(--ink)] focus:outline-none focus:ring-1 focus:ring-[var(--accent)]"
                placeholder="Your name"
              />
            </div>
            <div>
              <Label>Email</Label>
              <input
                value={session?.user?.email ?? ''}
                readOnly
                className="mt-1 w-full rounded-md border border-[var(--line)] bg-[var(--canvas)] px-3 py-2 text-[13px] text-[var(--ink-muted)] cursor-default select-none"
              />
              <p className="mt-1 text-[11px] text-[var(--ink-muted)]">Change your email in the section below.</p>
            </div>
            <Toast {...nameMsg} />
            <SubmitBtn loading={savingName} disabled={!name.trim()}>
              Save name
            </SubmitBtn>
          </form>
        </Card>

        {/* ── Change Email ────────────────────────────────────────────────────── */}
        <Card>
          <CardTitle>Change Email</CardTitle>
          <form onSubmit={handleChangeEmail} className="flex flex-col gap-3">
            <div>
              <Label>New email address</Label>
              <input
                type="email"
                value={newEmail}
                onChange={(e) => setNewEmail(e.target.value)}
                placeholder="new@neuraltale.com"
                disabled={notReady}
                className="mt-1 w-full rounded-md border border-[var(--line)] bg-[var(--canvas)] px-3 py-2 text-[13px] text-[var(--ink)] focus:outline-none focus:ring-1 focus:ring-[var(--accent)] disabled:opacity-50"
              />
            </div>
            <div>
              <Label>Current password (to confirm)</Label>
              <div className="mt-1">
                <PasswordInput
                  value={emailPwd}
                  onChange={setEmailPwd}
                  autoComplete="current-password"
                  disabled={notReady}
                />
              </div>
            </div>
            <Toast {...emailMsg} />
            <SubmitBtn loading={changingEmail} disabled={notReady || !newEmail.trim() || !emailPwd}>
              Send verification email
            </SubmitBtn>
          </form>
        </Card>

        {/* ── Change Password ─────────────────────────────────────────────────── */}
        <Card>
          <CardTitle>Change Password</CardTitle>
          <form onSubmit={handleChangePassword} className="flex flex-col gap-3">
            <div>
              <Label>Current password</Label>
              <div className="mt-1">
                <PasswordInput
                  value={currentPwd}
                  onChange={setCurrentPwd}
                  autoComplete="current-password"
                  disabled={notReady}
                />
              </div>
            </div>
            <div>
              <Label>New password</Label>
              <div className="mt-1">
                <PasswordInput
                  value={newPwd}
                  onChange={setNewPwd}
                  autoComplete="new-password"
                  disabled={notReady}
                />
              </div>
            </div>
            <div>
              <Label>Confirm new password</Label>
              <div className="mt-1">
                <PasswordInput
                  value={confirmPwd}
                  onChange={setConfirmPwd}
                  autoComplete="new-password"
                  disabled={notReady}
                />
              </div>
            </div>
            <Toast {...pwdMsg} />
            <SubmitBtn
              loading={changingPwd}
              disabled={notReady || !currentPwd || !newPwd || !confirmPwd}
            >
              Update password
            </SubmitBtn>
          </form>
        </Card>

        {/* ── Two-Factor Authentication ────────────────────────────────────────── */}
        <Card>
          <div className="flex items-center gap-3 mb-4">
            <ShieldCheck className="h-5 w-5 text-[var(--ink-muted)]" />
            <h2 className="text-[14px] font-semibold text-[var(--ink)]">Two-Factor Authentication</h2>
          </div>
          <p className="text-[12px] text-[var(--ink-muted)] mb-4">
            Protects your account with a time-based one-time password from an authenticator app (Google
            Authenticator, Authy, 1Password, etc.).
          </p>

          {/* Status badge */}
          <div className="flex items-center gap-2 mb-4">
            <span
              className={`inline-flex items-center gap-1.5 rounded-full px-2.5 py-0.5 text-[11px] font-medium ${
                totpEnrolled
                  ? 'bg-[var(--status-ok-bg,#e6f9f0)] text-[var(--status-ok,#16a34a)]'
                  : 'bg-[var(--status-warn-bg,#fff7ed)] text-[var(--status-warn,#b45309)]'
              }`}
            >
              {totpEnrolled ? (
                <><Check className="h-3 w-3" /> Enabled</>
              ) : (
                <><X className="h-3 w-3" /> Not enabled</>
              )}
            </span>
          </div>

          {/* Setup flow */}
          {!totpEnrolled && totpStep === 'idle' && (
            <button
              onClick={handleStartTotpSetup}
              disabled={twoFALoading || notReady}
              className="inline-flex items-center gap-2 rounded-md border border-[var(--line)] bg-[var(--canvas)] px-4 py-2 text-[12px] font-medium text-[var(--ink)] hover:bg-[var(--surface)] transition-colors disabled:opacity-50"
            >
              {twoFALoading ? <Loader2 className="h-3.5 w-3.5 animate-spin" /> : <KeyRound className="h-3.5 w-3.5" />}
              Set up 2FA
            </button>
          )}

          {!totpEnrolled && totpStep === 'show-secret' && totpSecret && (
            <div className="flex flex-col gap-3 border border-[var(--line)] rounded-md p-4 bg-[var(--canvas)]">
              <p className="text-[12px] text-[var(--ink)]">
                Open your authenticator app and add a new account. Choose <strong>Enter a setup key</strong> and
                fill in:
              </p>
              <div>
                <p className="text-[11px] text-[var(--ink-muted)] mb-1">Account name</p>
                <p className="text-[13px] font-mono text-[var(--ink)]">
                  Mali Up Admin ({session?.user?.email})
                </p>
              </div>
              <div>
                <p className="text-[11px] text-[var(--ink-muted)] mb-1">Secret key</p>
                <div className="flex items-center gap-2">
                  <code className="flex-1 rounded bg-[var(--surface)] px-3 py-2 text-[13px] font-mono tracking-widest text-[var(--ink)] break-all">
                    {totpSecret.secretKey}
                  </code>
                  <button
                    onClick={handleCopySecret}
                    className="shrink-0 rounded border border-[var(--line)] bg-[var(--surface)] p-2 hover:bg-[var(--canvas)] transition-colors"
                    title="Copy secret key"
                  >
                    {copied ? (
                      <CheckCheck className="h-3.5 w-3.5 text-[var(--status-ok,#16a34a)]" />
                    ) : (
                      <Copy className="h-3.5 w-3.5 text-[var(--ink-muted)]" />
                    )}
                  </button>
                </div>
              </div>
              <div>
                <p className="text-[11px] text-[var(--ink-muted)] mb-1">Type</p>
                <p className="text-[13px] text-[var(--ink)]">Time-based (TOTP)</p>
              </div>
              <p className="text-[12px] text-[var(--ink-muted)]">
                Once added, tap <strong>Continue</strong> to verify.
              </p>
              <div className="flex gap-2">
                <button
                  onClick={() => setTotpStep('verify')}
                  className="rounded-md bg-[var(--navy)] px-4 py-2 text-[12px] font-medium text-white hover:bg-[var(--navy-soft)] transition-colors"
                >
                  Continue →
                </button>
                <button
                  onClick={() => { setTotpStep('idle'); setTotpSecret(null) }}
                  className="rounded-md border border-[var(--line)] bg-[var(--canvas)] px-4 py-2 text-[12px] font-medium text-[var(--ink-muted)] hover:text-[var(--ink)] transition-colors"
                >
                  Cancel
                </button>
              </div>
            </div>
          )}

          {!totpEnrolled && totpStep === 'verify' && (
            <form onSubmit={handleVerifyTotp} className="flex flex-col gap-3 border border-[var(--line)] rounded-md p-4 bg-[var(--canvas)]">
              <p className="text-[12px] text-[var(--ink)]">
                Enter the 6-digit code from your authenticator app to confirm setup.
              </p>
              <div>
                <Label>Verification code</Label>
                <input
                  value={totpCode}
                  onChange={(e) => setTotpCode(e.target.value.replace(/\D/g, '').slice(0, 6))}
                  placeholder="000000"
                  inputMode="numeric"
                  maxLength={6}
                  className="mt-1 w-40 rounded-md border border-[var(--line)] bg-[var(--surface)] px-3 py-2 text-[18px] font-mono tracking-[0.3em] text-[var(--ink)] focus:outline-none focus:ring-1 focus:ring-[var(--accent)] text-center"
                />
              </div>
              <Toast {...twoFAMsg} />
              <div className="flex gap-2">
                <SubmitBtn loading={twoFALoading} disabled={totpCode.length !== 6}>
                  Verify &amp; enable
                </SubmitBtn>
                <button
                  type="button"
                  onClick={() => { setTotpStep('show-secret'); setTwoFAMsg({ ok: true, text: '' }); setTotpCode('') }}
                  className="rounded-md border border-[var(--line)] bg-[var(--canvas)] px-4 py-2 text-[12px] font-medium text-[var(--ink-muted)] hover:text-[var(--ink)] transition-colors"
                >
                  ← Back
                </button>
              </div>
            </form>
          )}

          {totpEnrolled && (
            <button
              onClick={handleDisableTotp}
              disabled={twoFALoading || notReady}
              className="inline-flex items-center gap-2 rounded-md border border-[var(--status-bad,#dc2626)] bg-[var(--status-bad-bg,#fef2f2)] px-4 py-2 text-[12px] font-medium text-[var(--status-bad,#dc2626)] hover:bg-[var(--status-bad,#dc2626)] hover:text-white transition-colors disabled:opacity-50"
            >
              {twoFALoading ? <Loader2 className="h-3.5 w-3.5 animate-spin" /> : <X className="h-3.5 w-3.5" />}
              Disable 2FA
            </button>
          )}

          {/* Top-level 2FA feedback (for idle state messages) */}
          {totpStep === 'idle' && twoFAMsg.text && (
            <div className="mt-3">
              <Toast {...twoFAMsg} />
            </div>
          )}
        </Card>

        {/* ── Session ─────────────────────────────────────────────────────────── */}
        <Card>
          <CardTitle>Session</CardTitle>
          <button
            onClick={() => signOut({ callbackUrl: '/admin/login' })}
            className="inline-flex items-center gap-2 rounded-md border border-[var(--status-bad,#dc2626)] bg-[var(--status-bad-bg,#fef2f2)] px-4 py-2 text-[12px] font-medium text-[var(--status-bad,#dc2626)] hover:bg-[var(--status-bad,#dc2626)] hover:text-white transition-colors"
          >
            <LogOut className="h-3.5 w-3.5" />
            Sign out
          </button>
        </Card>
      </div>
    </div>
  )
}
