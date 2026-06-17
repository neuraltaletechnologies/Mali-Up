'use client'

import { useState } from 'react'
import { signIn } from 'next-auth/react'
import { useRouter } from 'next/navigation'
import {
  signInWithEmailAndPassword,
  getIdToken,
  AuthError,
} from 'firebase/auth'
import { getFirebaseAuth } from '@/lib/firebase-client'
import { Eye, EyeOff, AlertCircle, ShieldCheck } from 'lucide-react'

const FIREBASE_ERROR_MESSAGES: Record<string, string> = {
  'auth/invalid-credential':     'Incorrect email or password.',
  'auth/user-not-found':         'No admin account found for this email.',
  'auth/wrong-password':         'Incorrect password.',
  'auth/too-many-requests':      'Too many failed attempts. Try again later or reset your password.',
  'auth/user-disabled':          'This account has been disabled.',
  'auth/network-request-failed': 'Network error. Check your connection and try again.',
}

function getFirebaseErrorMessage(err: unknown): string {
  if (err && typeof err === 'object' && 'code' in err) {
    const code = (err as AuthError).code
    return FIREBASE_ERROR_MESSAGES[code] ?? 'Sign-in failed. Please try again.'
  }
  return 'Sign-in failed. Please try again.'
}

export default function LoginPage() {
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [showPassword, setShowPassword] = useState(false)
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(false)
  const router = useRouter()

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    setError('')
    setLoading(true)

    try {
      // Step 1 — authenticate with Firebase (validates email + password)
      const auth = getFirebaseAuth()
      const userCredential = await signInWithEmailAndPassword(
        auth,
        email.trim(),
        password,
      )

      // Step 2 — get a fresh ID token (includes custom claims)
      const idToken = await getIdToken(userCredential.user, /* forceRefresh= */ true)

      // Step 3 — hand the ID token to NextAuth for server-side verification
      // (checks token signature + revocation + admin custom claim)
      const result = await signIn('firebase', {
        idToken,
        redirect: false,
      })

      if (result?.error) {
        // Token was valid Firebase but user lacks admin privileges
        await getFirebaseAuth().signOut()
        setError('Your account does not have admin access. Contact the platform owner.')
      } else {
        router.push('/')
      }
    } catch (err) {
      setError(getFirebaseErrorMessage(err))
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="min-h-screen bg-[var(--canvas)] flex items-center justify-center">
      <div className="w-full max-w-sm">
        {/* Brand */}
        <div className="mb-8 text-center">
          <div className="inline-flex items-center justify-center h-12 w-12 rounded-xl bg-gradient-to-br from-[var(--navy)] to-[var(--accent)] mb-4">
            <span className="text-white text-lg font-bold">M</span>
          </div>
          <h1 className="text-[18px] font-semibold text-[var(--ink)]">Mali Up Admin</h1>
          <p className="mt-1 text-[12px] text-[var(--ink-muted)]">
            Internal operations console — Neuraltale Technology
          </p>
        </div>

        {/* Form */}
        <div className="rounded-xl border border-[var(--line)] bg-[var(--surface)] p-8 shadow-sm">
          <form onSubmit={handleSubmit} className="flex flex-col gap-4">
            <div className="flex flex-col gap-1.5">
              <label className="text-[12px] font-medium text-[var(--ink-muted)]">Admin email</label>
              <input
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                required
                autoComplete="email"
                placeholder="you@neuraltale.com"
                className="w-full rounded-md border border-[var(--line)] bg-[var(--canvas)] px-3 py-2 text-[13px] text-[var(--ink)] placeholder:text-[var(--ink-faint)] focus:outline-none focus:ring-1 focus:ring-[var(--accent)]"
              />
            </div>

            <div className="flex flex-col gap-1.5">
              <label className="text-[12px] font-medium text-[var(--ink-muted)]">Password</label>
              <div className="relative">
                <input
                  type={showPassword ? 'text' : 'password'}
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  required
                  autoComplete="current-password"
                  placeholder="••••••••"
                  className="w-full rounded-md border border-[var(--line)] bg-[var(--canvas)] px-3 py-2 pr-10 text-[13px] text-[var(--ink)] placeholder:text-[var(--ink-faint)] focus:outline-none focus:ring-1 focus:ring-[var(--accent)]"
                />
                <button
                  type="button"
                  onClick={() => setShowPassword(!showPassword)}
                  className="absolute right-2.5 top-1/2 -translate-y-1/2 text-[var(--ink-faint)] hover:text-[var(--ink-muted)]"
                  tabIndex={-1}
                >
                  {showPassword ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
                </button>
              </div>
            </div>

            {error && (
              <div className="flex items-start gap-2 rounded-md bg-[var(--status-bad-bg)] border border-[var(--status-bad)]/20 px-3 py-2.5 text-[12px] text-[var(--status-bad)]">
                <AlertCircle className="h-3.5 w-3.5 shrink-0 mt-0.5" />
                <span>{error}</span>
              </div>
            )}

            <button
              type="submit"
              disabled={loading || !email || !password}
              className="mt-1 w-full rounded-md bg-[var(--navy)] px-4 py-2.5 text-[13px] font-medium text-white hover:bg-[var(--navy-soft)] transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
            >
              {loading ? 'Verifying…' : 'Sign in'}
            </button>
          </form>
        </div>

        {/* Security indicator */}
        <div className="mt-4 flex items-center justify-center gap-1.5 text-[11px] text-[var(--ink-faint)]">
          <ShieldCheck className="h-3 w-3" />
          Secured by Firebase Authentication
        </div>

        <p className="mt-3 text-center text-[11px] text-[var(--ink-faint)]">
          Not for public access. Authorized personnel only.
        </p>
      </div>
    </div>
  )
}
