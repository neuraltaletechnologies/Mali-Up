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
      const auth = getFirebaseAuth()
      const userCredential = await signInWithEmailAndPassword(auth, email.trim(), password)
      const idToken = await getIdToken(userCredential.user, true)
      const result = await signIn('firebase', { idToken, redirect: false })

      if (result?.error) {
        await getFirebaseAuth().signOut()
        setError('Your account does not have admin access. Contact the platform owner.')
      } else {
        router.push('/admin')
      }
    } catch (err) {
      setError(getFirebaseErrorMessage(err))
    } finally {
      setLoading(false)
    }
  }

  return (
    <div
      className="min-h-screen flex items-center justify-center"
      style={{
        background: 'radial-gradient(ellipse at 20% 50%, rgba(30,144,170,0.08) 0%, transparent 60%), #040C18',
      }}
    >
      {/* Ambient glow orb */}
      <div
        className="pointer-events-none fixed left-[10%] top-[20%] h-80 w-80 rounded-full opacity-15 blur-3xl"
        style={{ background: 'radial-gradient(circle, #FFC107 0%, transparent 70%)' }}
      />

      <div className="relative w-full max-w-sm px-4">
        {/* Brand */}
        <div className="mb-8 text-center">
          <img
            src="/mali_up_wordmark.png"
            alt="Mali Up"
            className="h-20 w-20 rounded-full mx-auto mb-4"
            style={{ boxShadow: '0 0 32px rgba(255,193,7,0.35)' }}
          />
          <h1 className="text-[20px] font-semibold text-white tracking-tight">Mali Up Admin</h1>
          <p className="mt-1 text-[12px]" style={{ color: 'rgba(255,193,7,0.6)' }}>
            Internal operations console — Neuraltale Technology
          </p>
        </div>

        {/* Form card */}
        <div
          className="rounded-xl p-8"
          style={{
            background: 'rgba(9,20,34,0.8)',
            border: '1px solid rgba(255,255,255,0.09)',
            backdropFilter: 'blur(12px)',
          }}
        >
          <form onSubmit={handleSubmit} className="flex flex-col gap-4">
            <div className="flex flex-col gap-1.5">
              <label className="text-[12px] font-medium" style={{ color: '#7B8FBD' }}>Admin email</label>
              <input
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                required
                autoComplete="email"
                placeholder="you@neuraltale.com"
                className="w-full rounded-md px-3 py-2.5 text-[13px] focus:outline-none transition-colors"
                style={{
                  border: '1px solid rgba(255,255,255,0.09)',
                  backgroundColor: 'rgba(4,12,24,0.6)',
                  color: '#E2EAFF',
                }}
                onFocus={(e) => { e.target.style.borderColor = '#2AB0D5'; e.target.style.boxShadow = '0 0 0 1px #2AB0D5' }}
                onBlur={(e) => { e.target.style.borderColor = 'rgba(255,255,255,0.09)'; e.target.style.boxShadow = 'none' }}
              />
            </div>

            <div className="flex flex-col gap-1.5">
              <label className="text-[12px] font-medium" style={{ color: '#7B8FBD' }}>Password</label>
              <div className="relative">
                <input
                  type={showPassword ? 'text' : 'password'}
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  required
                  autoComplete="current-password"
                  placeholder="••••••••"
                  className="w-full rounded-md px-3 py-2.5 pr-10 text-[13px] focus:outline-none transition-colors"
                  style={{
                    border: '1px solid rgba(255,255,255,0.09)',
                    backgroundColor: 'rgba(4,12,24,0.6)',
                    color: '#E2EAFF',
                  }}
                  onFocus={(e) => { e.target.style.borderColor = '#2AB0D5'; e.target.style.boxShadow = '0 0 0 1px #2AB0D5' }}
                  onBlur={(e) => { e.target.style.borderColor = 'rgba(255,255,255,0.09)'; e.target.style.boxShadow = 'none' }}
                />
                <button
                  type="button"
                  onClick={() => setShowPassword(!showPassword)}
                  className="absolute right-2.5 top-1/2 -translate-y-1/2 hover:opacity-70 transition-opacity"
                  style={{ color: '#3A4E74' }}
                  tabIndex={-1}
                >
                  {showPassword ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
                </button>
              </div>
            </div>

            {error && (
              <div
                className="flex items-start gap-2 rounded-md px-3 py-2.5 text-[12px]"
                style={{ backgroundColor: 'rgba(248,113,113,0.10)', border: '1px solid rgba(248,113,113,0.25)', color: '#F87171' }}
              >
                <AlertCircle className="h-3.5 w-3.5 shrink-0 mt-0.5" />
                <span>{error}</span>
              </div>
            )}

            <button
              type="submit"
              disabled={loading || !email || !password}
              className="mt-1 w-full rounded-md px-4 py-2.5 text-[13px] font-semibold transition-all"
              style={{
                background: loading || !email || !password
                  ? 'rgba(255,193,7,0.2)'
                  : 'linear-gradient(135deg, #FFC107 0%, #E5AC00 100%)',
                color: loading || !email || !password ? 'rgba(255,193,7,0.4)' : '#040C18',
                cursor: loading || !email || !password ? 'not-allowed' : 'pointer',
                boxShadow: loading || !email || !password ? 'none' : '0 4px 20px rgba(255,193,7,0.25)',
              }}
            >
              {loading ? 'Verifying…' : 'Sign in'}
            </button>
          </form>
        </div>

        {/* Security indicator */}
        <div className="mt-4 flex items-center justify-center gap-1.5 text-[11px]" style={{ color: '#3A4E74' }}>
          <ShieldCheck className="h-3 w-3" />
          Secured by Firebase Authentication
        </div>

        <p className="mt-2 text-center text-[11px]" style={{ color: '#3A4E74' }}>
          Not for public access. Authorized personnel only.
        </p>
      </div>
    </div>
  )
}
