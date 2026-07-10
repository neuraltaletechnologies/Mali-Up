'use client'

import { useState, useEffect } from 'react'
import { signIn } from 'next-auth/react'
import { useRouter } from 'next/navigation'
import {
  signInWithEmailAndPassword,
  getIdToken,
  AuthError,
} from 'firebase/auth'
import { getFirebaseAuth } from '@/lib/firebase-client'
import NextImage from 'next/image'
import { Eye, EyeOff, AlertCircle, ArrowRight, ChevronDown, ShieldCheck } from 'lucide-react'
import { IPhoneMockup } from '@/components/mali/iphone-mockup'

/* ─────────────────── Firebase error map ─────────────────── */
const FB_ERRORS: Record<string, string> = {
  'auth/invalid-credential':      'Incorrect email or password.',
  'auth/user-not-found':          'No admin account found for this email.',
  'auth/wrong-password':          'Incorrect password.',
  'auth/too-many-requests':       'Too many failed attempts. Try again later.',
  'auth/user-disabled':           'This account has been disabled.',
  'auth/network-request-failed':  'Network error. Check your connection.',
  'auth/unauthorized-domain':     'This domain is not authorized for Firebase Auth.',
  'auth/invalid-api-key':         'Invalid Firebase API key.',
  'auth/configuration-not-found': 'Firebase project configuration not found.',
  'auth/operation-not-allowed':   'Email/password sign-in is not enabled.',
}
function fbMsg(err: unknown) {
  if (err && typeof err === 'object' && 'code' in err)
    return FB_ERRORS[(err as AuthError).code] ?? 'Sign-in failed. Please try again.'
  return 'Sign-in failed. Please try again.'
}

/* ─────────────────── Main page ─────────────────── */
export default function LoginPage() {
  const [mounted, setMounted] = useState(false)
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [showPassword, setShowPassword] = useState(false)
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(false)
  const [focused, setFocused] = useState<string | null>(null)
  const [btnHov, setBtnHov] = useState(false)
  const router = useRouter()

  useEffect(() => { const t = setTimeout(() => setMounted(true), 30); return () => clearTimeout(t) }, [])

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    setError('')
    setLoading(true)
    try {
      const auth = getFirebaseAuth()
      const cred = await signInWithEmailAndPassword(auth, email.trim(), password)
      const idToken = await getIdToken(cred.user, true)
      const result = await signIn('firebase', { idToken, redirect: false })
      if (result?.error) {
        await getFirebaseAuth().signOut()
        setError('Your account does not have admin access. Contact the platform owner.')
      } else {
        router.push('/admin')
      }
    } catch (err) {
      setError(fbMsg(err))
    } finally {
      setLoading(false)
    }
  }

  const disabled = loading || !email || !password

  /* input style helper */
  const inputStyle = (field: string): React.CSSProperties => ({
    width: '100%',
    height: 56,
    borderRadius: 999,
    border: `1.5px solid ${focused === field ? '#F5A623' : 'rgba(12,27,46,0.12)'}`,
    padding: '0 24px',
    fontSize: 15,
    color: '#0C1B2E',
    background: '#FFFFFF',
    outline: 'none',
    transition: 'border-color 0.2s ease, box-shadow 0.2s ease',
    boxShadow: focused === field
      ? '0 0 0 4px rgba(245,166,35,0.12), 0 2px 12px rgba(0,0,0,0.06)'
      : '0 2px 8px rgba(12,27,46,0.04)',
    fontFamily: 'inherit',
  })

  return (
    <>
      {/* ── Keyframes ── */}
      <style>{`
        @keyframes _fadeUp {
          from { opacity: 0; transform: translateY(22px); }
          to   { opacity: 1; transform: translateY(0);    }
        }
        @keyframes _fadeLeft {
          from { opacity: 0; transform: translateX(-22px); }
          to   { opacity: 1; transform: translateX(0);     }
        }
        @keyframes _slidePhone {
          from { opacity: 0; transform: translateY(56px); }
          to   { opacity: 1; transform: translateY(0);    }
        }
        @keyframes _ring {
          0%,100% { opacity: 0.10; transform: translate(-50%,-50%) scale(1);    }
          50%      { opacity: 0.20; transform: translate(-50%,-50%) scale(1.03); }
        }

        .lu-fade-up   { animation: _fadeUp   0.65s cubic-bezier(0.22,1,0.36,1) both; }
        .lu-fade-left { animation: _fadeLeft 0.75s cubic-bezier(0.22,1,0.36,1) both; }
        .lu-phone     { animation: _slidePhone 1s cubic-bezier(0.22,1,0.36,1) 0.25s both; }
        .lu-ring      { animation: _ring 5s ease-in-out infinite; }

        .d1 { animation-delay: 0.05s; }
        .d2 { animation-delay: 0.15s; }
        .d3 { animation-delay: 0.25s; }
        .d4 { animation-delay: 0.35s; }
        .d5 { animation-delay: 0.45s; }
        .dr1 { animation-delay: 0s;    }
        .dr2 { animation-delay: 1.5s;  }
        .dr3 { animation-delay: 3s;    }

        .lu-input::placeholder { color: rgba(12,27,46,0.38); font-size: 15px; }
      `}</style>

      <div style={{
        minHeight: '100vh',
        display: 'flex',
        fontFamily: 'Inter, -apple-system, BlinkMacSystemFont, sans-serif',
        WebkitFontSmoothing: 'antialiased',
        opacity: mounted ? 1 : 0,
        transition: 'opacity 0.35s ease',
      }}>

        {/* ══════════════════════════════════
            LEFT PANEL
        ══════════════════════════════════ */}
        <div
          className="hidden lg:flex flex-col"
          style={{
            width: '50%',
            background: 'linear-gradient(160deg, #0C1B2E 0%, #142038 100%)',
            position: 'relative',
            overflow: 'hidden',
          }}
        >
          {/* ── Subtle amber grid ── */}
          <div
            style={{
              position: 'absolute',
              inset: 0,
              opacity: 0.035,
              backgroundImage: 'linear-gradient(#F5A623 1px, transparent 1px), linear-gradient(90deg, #F5A623 1px, transparent 1px)',
              backgroundSize: '60px 60px',
              pointerEvents: 'none',
            }}
          />

          {/* ── Concentric pulsing rings ── */}
          {[530, 400, 270].map((sz, i) => (
            <div
              key={sz}
              className={`lu-ring dr${i + 1}`}
              style={{
                position: 'absolute',
                width: sz, height: sz,
                borderRadius: '50%',
                border: '1px solid rgba(245,166,35,0.22)',
                top: '46%', left: '50%',
                transform: 'translate(-50%,-50%)',
                pointerEvents: 'none',
              }}
            />
          ))}

          {/* ── Soft gradient glow ── */}
          <div style={{
            position: 'absolute',
            width: 560, height: 560,
            borderRadius: '50%',
            background: 'radial-gradient(circle, rgba(245,166,35,0.14) 0%, transparent 70%)',
            top: '18%', left: '30%',
            transform: 'translate(-50%,-50%)',
            pointerEvents: 'none',
          }} />
          <div style={{
            position: 'absolute',
            width: 360, height: 360,
            borderRadius: '50%',
            background: 'radial-gradient(circle, rgba(34,197,94,0.08) 0%, transparent 70%)',
            top: '70%', left: '70%',
            transform: 'translate(-50%,-50%)',
            pointerEvents: 'none',
          }} />

          {/* ── Text content ── */}
          <div style={{ padding: '44px 52px 0', position: 'relative', zIndex: 1 }}>

            {/* Badge */}
            <div
              className={`glass-amber ${mounted ? 'lu-fade-left d1' : ''}`}
              style={{
                display: 'inline-flex',
                alignItems: 'center',
                gap: 8,
                fontSize: 12,
                fontWeight: 700,
                color: '#F5A623',
                padding: '7px 16px',
                borderRadius: 999,
                letterSpacing: '0.04em',
                textTransform: 'uppercase',
                marginBottom: 22,
              }}
            >
              <ShieldCheck size={14} />
              Secure Admin Access
            </div>

            {/* Main headline */}
            <h1
              className={mounted ? 'lu-fade-left d2' : ''}
              style={{
                fontSize: 56,
                fontWeight: 800,
                color: '#FFFFFF',
                lineHeight: 1.07,
                letterSpacing: '-0.035em',
                margin: 0,
              }}
            >
              Manage<br />your{' '}
              <span
                className="shimmer-btn"
                style={{
                  WebkitBackgroundClip: 'text',
                  WebkitTextFillColor: 'transparent',
                  backgroundClip: 'text',
                }}
              >
                business
              </span>
              <br />effortlessly.
            </h1>

            <p
              className={mounted ? 'lu-fade-left d3' : ''}
              style={{
                fontSize: 14, fontWeight: 500,
                color: 'rgba(255,255,255,0.45)',
                letterSpacing: '0.01em',
                marginTop: 18,
                maxWidth: 360,
              }}
            >
              The control center for every business running on Mali Up — sales, invoices, inventory and finance, all in one place.
            </p>
          </div>

          {/* ── Floating iPhone mockup — bottom-left, slightly cut off ── */}
          <div
            className={mounted ? 'lu-phone' : ''}
            style={{
              position: 'absolute',
              bottom: -30,
              left: 52,
              zIndex: 2,
              filter: 'drop-shadow(0 48px 90px rgba(0,0,0,0.5))',
            }}
          >
            <IPhoneMockup
              src="/app-dashboard.jpg"
              alt="Mali Up dashboard"
              width={230}
              accentColor="#F5A623"
              animate
            />
          </div>
        </div>

        {/* ══════════════════════════════════
            RIGHT PANEL
        ══════════════════════════════════ */}
        <div
          className="flex-1 flex flex-col"
          style={{ background: '#FFFFFF' }}
        >
          {/* ── Top bar ── */}
          <div style={{
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'space-between',
            padding: '28px 52px',
          }}>
            <div
              className={mounted ? 'lu-fade-up d1' : ''}
              style={{ display: 'flex', alignItems: 'center', gap: 10 }}
            >
              <NextImage
                src="/maliup-logo.png"
                alt="Mali Up"
                width={38}
                height={38}
                className="rounded-xl shadow-lg"
                priority
              />
              <span style={{ fontSize: 17, fontWeight: 700, color: '#0C1B2E', letterSpacing: '-0.01em' }}>
                Mali<span style={{ color: '#F5A623' }}>Up</span>
              </span>
            </div>
            <div
              className={mounted ? 'lu-fade-up d1' : ''}
              style={{
                display: 'flex', alignItems: 'center', gap: 6,
                fontSize: 13, fontWeight: 600,
                color: '#0C1B2E',
                background: 'transparent',
                border: '1.5px solid rgba(12,27,46,0.12)',
                borderRadius: 999,
                padding: '8px 18px',
              }}
            >
              <ShieldCheck size={14} style={{ color: '#F5A623' }} />
              Admin only
            </div>
          </div>

          {/* ── Form — vertically centered ── */}
          <div style={{
            flex: 1,
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            padding: '0 52px',
          }}>
            <div style={{ width: '100%', maxWidth: 420 }}>

              {/* Heading */}
              <h2
                className={mounted ? 'lu-fade-up d2' : ''}
                style={{
                  fontSize: 44,
                  fontWeight: 700,
                  color: '#0C1B2E',
                  letterSpacing: '-0.03em',
                  lineHeight: 1.1,
                  marginBottom: 36,
                }}
              >
                Sign In
              </h2>

              <form
                onSubmit={handleSubmit}
                style={{ display: 'flex', flexDirection: 'column', gap: 14 }}
              >

                {/* Email */}
                <div className={mounted ? 'lu-fade-up d3' : ''}>
                  <input
                    type="email"
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    required
                    autoComplete="email"
                    placeholder="Email or Username"
                    className="lu-input"
                    style={inputStyle('email')}
                    onFocus={() => setFocused('email')}
                    onBlur={() => setFocused(null)}
                  />
                </div>

                {/* Password */}
                <div
                  className={mounted ? 'lu-fade-up d4' : ''}
                  style={{ position: 'relative' }}
                >
                  <input
                    type={showPassword ? 'text' : 'password'}
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    required
                    autoComplete="current-password"
                    placeholder="Password"
                    className="lu-input"
                    style={{ ...inputStyle('password'), paddingRight: 54 }}
                    onFocus={() => setFocused('password')}
                    onBlur={() => setFocused(null)}
                  />
                  <button
                    type="button"
                    onClick={() => setShowPassword(!showPassword)}
                    style={{
                      position: 'absolute', right: 20, top: '50%',
                      transform: 'translateY(-50%)',
                      color: 'rgba(12,27,46,0.4)', background: 'none', border: 'none',
                      cursor: 'pointer', display: 'flex',
                      transition: 'color 0.15s',
                      padding: 0,
                    }}
                    tabIndex={-1}
                  >
                    {showPassword ? <EyeOff size={18} /> : <Eye size={18} />}
                  </button>
                </div>

                {/* Error banner */}
                {error && (
                  <div style={{
                    display: 'flex', alignItems: 'flex-start', gap: 8,
                    padding: '13px 18px',
                    borderRadius: 18,
                    background: '#FFF1F0',
                    border: '1px solid #FFD6D0',
                    color: '#CC2222',
                    fontSize: 13,
                    fontWeight: 500,
                  }}>
                    <AlertCircle size={16} style={{ flexShrink: 0, marginTop: 1 }} />
                    <span>{error}</span>
                  </div>
                )}

                {/* Sign In button */}
                <div className={mounted ? 'lu-fade-up d5' : ''}>
                  <button
                    type="submit"
                    disabled={disabled}
                    onMouseEnter={() => setBtnHov(true)}
                    onMouseLeave={() => setBtnHov(false)}
                    className={disabled ? '' : 'shimmer-btn'}
                    style={{
                      width: '100%',
                      height: 56,
                      borderRadius: 999,
                      border: 'none',
                      background: disabled ? '#EDEDED' : undefined,
                      color: disabled ? '#AAAAAA' : '#0C1B2E',
                      fontSize: 15,
                      fontWeight: 800,
                      cursor: disabled ? 'not-allowed' : 'pointer',
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                      gap: 8,
                      letterSpacing: '0.005em',
                      transition: 'box-shadow 0.28s cubic-bezier(0.22,1,0.36,1), transform 0.28s cubic-bezier(0.22,1,0.36,1)',
                      boxShadow: disabled
                        ? 'none'
                        : btnHov
                        ? '0 14px 44px rgba(245,166,35,0.45)'
                        : '0 8px 26px rgba(245,166,35,0.32)',
                      transform: btnHov && !disabled ? 'translateY(-2px)' : 'translateY(0)',
                      marginTop: 4,
                      fontFamily: 'inherit',
                    }}
                  >
                    <ArrowRight size={18} />
                    {loading ? 'Signing in…' : 'Sign In'}
                  </button>
                </div>

              </form>
            </div>
          </div>

          {/* ── Footer ── */}
          <div style={{
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'space-between',
            padding: '20px 52px',
            borderTop: '1px solid rgba(12,27,46,0.08)',
          }}>
            <span style={{ fontSize: 12, color: 'rgba(12,27,46,0.35)' }}>
              © 2005–2025 Neuraltale Technology
            </span>
            <div style={{ display: 'flex', alignItems: 'center', gap: 24 }}>
              <button
                type="button"
                style={{ fontSize: 12, color: 'rgba(12,27,46,0.5)', background: 'none', border: 'none', cursor: 'pointer', fontFamily: 'inherit' }}
              >
                Contact Us
              </button>
              <button
                type="button"
                style={{
                  display: 'flex', alignItems: 'center', gap: 4,
                  fontSize: 12, color: 'rgba(12,27,46,0.5)',
                  background: 'none', border: 'none', cursor: 'pointer', fontFamily: 'inherit',
                }}
              >
                English <ChevronDown size={12} />
              </button>
            </div>
          </div>
        </div>

      </div>
    </>
  )
}
