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
    <div className="min-h-screen flex items-center justify-center" style={{ backgroundColor: '#FAFBFC' }}>
      <div className="w-full max-w-sm">
        {/* Brand */}
        <div className="mb-8 text-center">
          <div className="inline-flex items-center justify-center h-12 w-12 rounded-xl mb-4" style={{ background: 'linear-gradient(135deg, #1A6E8A, #0D1B3E)' }}>
            <span className="text-white text-lg font-bold">M</span>
          </div>
          <h1 className="text-[18px] font-semibold" style={{ color: '#0F172A' }}>Mali Up Admin</h1>
          <p className="mt-1 text-[12px]" style={{ color: '#64748B' }}>
            Internal operations console — Neuraltale Technology
          </p>
        </div>

        {/* Form */}
        <div className="rounded-xl p-8 shadow-sm" style={{ border: '1px solid #EBEEF2', backgroundColor: '#FFFFFF' }}>
          <form onSubmit={handleSubmit} className="flex flex-col gap-4">
            <div className="flex flex-col gap-1.5">
              <label className="text-[12px] font-medium" style={{ color: '#64748B' }}>Admin email</label>
              <input
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                required
                autoComplete="email"
                placeholder="you@neuraltale.com"
                className="w-full rounded-md px-3 py-2 text-[13px] focus:outline-none focus:ring-1"
                style={{ border: '1px solid #EBEEF2', backgroundColor: '#FAFBFC', color: '#0F172A', focusRingColor: '#1A6E8A' } as React.CSSProperties}
              />
            </div>

            <div className="flex flex-col gap-1.5">
              <label className="text-[12px] font-medium" style={{ color: '#64748B' }}>Password</label>
              <div className="relative">
                <input
                  type={showPassword ? 'text' : 'password'}
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  required
                  autoComplete="current-password"
                  placeholder="••••••••"
                  className="w-full rounded-md px-3 py-2 pr-10 text-[13px] focus:outline-none focus:ring-1"
                  style={{ border: '1px solid #EBEEF2', backgroundColor: '#FAFBFC', color: '#0F172A' }}
                />
                <button
                  type="button"
                  onClick={() => setShowPassword(!showPassword)}
                  className="absolute right-2.5 top-1/2 -translate-y-1/2 hover:opacity-70"
                  style={{ color: '#94A3B8' }}
                  tabIndex={-1}
                >
                  {showPassword ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
                </button>
              </div>
            </div>

            {error && (
              <div className="flex items-start gap-2 rounded-md px-3 py-2.5 text-[12px]" style={{ backgroundColor: '#FEF2F2', border: '1px solid rgba(220,38,38,0.2)', color: '#DC2626' }}>
                <AlertCircle className="h-3.5 w-3.5 shrink-0 mt-0.5" />
                <span>{error}</span>
              </div>
            )}

            <button
              type="submit"
              disabled={loading || !email || !password}
              className="mt-1 w-full rounded-md px-4 py-2.5 text-[13px] font-medium text-white transition-colors"
              style={{ backgroundColor: '#0D1B3E', opacity: (loading || !email || !password) ? 0.5 : 1, cursor: (loading || !email || !password) ? 'not-allowed' : 'pointer' }}
            >
              {loading ? 'Verifying…' : 'Sign in'}
            </button>
          </form>
        </div>

        {/* Security indicator */}
        <div className="mt-4 flex items-center justify-center gap-1.5 text-[11px]" style={{ color: '#94A3B8' }}>
          <ShieldCheck className="h-3 w-3" />
          Secured by Firebase Authentication
        </div>

        <p className="mt-3 text-center text-[11px]" style={{ color: '#94A3B8' }}>
          Not for public access. Authorized personnel only.
        </p>
      </div>
    </div>
  )
}
