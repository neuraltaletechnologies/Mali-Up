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
import { Eye, EyeOff, AlertCircle, ArrowRight, ChevronDown, ShieldCheck } from 'lucide-react'

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

/* ─────────────────── Phone screen data ─────────────────── */
const BARS = [28, 48, 34, 72, 44, 88, 56]
const DAYS = ['M', 'T', 'W', 'T', 'F', 'S', 'S']

function PhoneMockup() {
  return (
    /* Outer frame */
    <div style={{
      width: 228,
      height: 448,
      background: '#1C1C1E',
      borderRadius: 46,
      border: '9px solid #2A2A2C',
      boxShadow: `
        0 48px 120px rgba(0,0,0,0.65),
        0 16px 40px rgba(0,0,0,0.4),
        inset 0 1px 0 rgba(255,255,255,0.06)
      `,
      position: 'relative',
      overflow: 'hidden',
      flexShrink: 0,
    }}>
      {/* Dynamic island */}
      <div style={{
        position: 'absolute', top: 10, left: '50%',
        transform: 'translateX(-50%)',
        width: 84, height: 24,
        background: '#1C1C1E', borderRadius: 13, zIndex: 10,
      }} />

      {/* Screen */}
      <div style={{
        position: 'absolute', inset: 0,
        background: 'linear-gradient(165deg, #0D0A20 0%, #14102E 40%, #1A1035 100%)',
        borderRadius: 37,
        display: 'flex', flexDirection: 'column',
        overflow: 'hidden',
      }}>
        {/* Status bar */}
        <div style={{ height: 44, display: 'flex', alignItems: 'flex-end', padding: '0 20px 6px', justifyContent: 'space-between' }}>
          <span style={{ fontSize: 9, fontWeight: 700, color: 'rgba(255,255,255,0.6)' }}>9:41</span>
          <div style={{ display: 'flex', gap: 4, alignItems: 'center' }}>
            {[3,4,5].map(h => <div key={h} style={{ width: 3, height: h, background: 'rgba(255,255,255,0.6)', borderRadius: 1 }} />)}
            <div style={{ width: 14, height: 7, border: '1px solid rgba(255,255,255,0.5)', borderRadius: 2, marginLeft: 2, position: 'relative' }}>
              <div style={{ position: 'absolute', left: 1, top: 1, bottom: 1, width: '70%', background: 'rgba(255,255,255,0.6)', borderRadius: 1 }} />
            </div>
          </div>
        </div>

        <div style={{ flex: 1, padding: '0 18px', overflow: 'hidden', display: 'flex', flexDirection: 'column' }}>

          {/* Greeting */}
          <div style={{ marginBottom: 10 }}>
            <p style={{ fontSize: 9, color: 'rgba(255,255,255,0.4)', fontWeight: 500 }}>Welcome back</p>
            <p style={{ fontSize: 15, color: '#fff', fontWeight: 800, letterSpacing: '-0.01em' }}>Julius ✦</p>
          </div>

          {/* Balance card */}
          <div style={{
            background: 'linear-gradient(135deg, #FF5A00 0%, #FF3B73 100%)',
            borderRadius: 18, padding: '14px 16px', marginBottom: 10,
            boxShadow: '0 8px 24px rgba(255,59,115,0.35)',
            position: 'relative', overflow: 'hidden',
          }}>
            {/* Shine overlay */}
            <div style={{
              position: 'absolute', top: -20, right: -20,
              width: 80, height: 80, borderRadius: '50%',
              background: 'rgba(255,255,255,0.08)',
            }} />
            <p style={{ fontSize: 8, color: 'rgba(255,255,255,0.75)', marginBottom: 2, fontWeight: 600, letterSpacing: '0.05em', textTransform: 'uppercase' }}>Total Balance</p>
            <div style={{ display: 'flex', alignItems: 'baseline', gap: 4 }}>
              <span style={{ fontSize: 22, fontWeight: 900, color: '#fff', lineHeight: 1, letterSpacing: '-0.02em' }}>4,200,000</span>
              <span style={{ fontSize: 9, color: 'rgba(255,255,255,0.65)', fontWeight: 600 }}>TZS</span>
            </div>
            {/* Mini sparkline */}
            <svg width="100%" height="20" viewBox="0 0 160 20" style={{ marginTop: 8 }} preserveAspectRatio="none">
              <polyline
                points="0,16 23,12 46,15 69,6 92,10 115,3 138,6 160,1"
                fill="none"
                stroke="rgba(255,255,255,0.45)"
                strokeWidth="1.5"
                strokeLinecap="round"
                strokeLinejoin="round"
              />
              <circle cx="160" cy="1" r="2" fill="rgba(255,255,255,0.7)" />
            </svg>
          </div>

          {/* Quick stats */}
          <div style={{ display: 'flex', gap: 8, marginBottom: 10 }}>
            {[
              { label: 'Income', value: '2.1M', color: '#30D158', bg: 'rgba(48,209,88,0.12)' },
              { label: 'Expenses', value: '890K', color: '#FF453A', bg: 'rgba(255,69,58,0.12)' },
            ].map(({ label, value, color, bg }) => (
              <div key={label} style={{
                flex: 1, background: bg,
                borderRadius: 12, padding: '8px 10px',
                border: `1px solid ${color}22`,
              }}>
                <p style={{ fontSize: 8, color: 'rgba(255,255,255,0.4)', marginBottom: 3, fontWeight: 500 }}>{label}</p>
                <p style={{ fontSize: 14, fontWeight: 800, color, letterSpacing: '-0.01em' }}>{value}</p>
              </div>
            ))}
          </div>

          {/* Bar chart */}
          <div>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 6 }}>
              <p style={{ fontSize: 8, color: 'rgba(255,255,255,0.4)', fontWeight: 500 }}>Weekly overview</p>
              <p style={{ fontSize: 8, color: '#FF5A00', fontWeight: 600 }}>Jun 23–29</p>
            </div>
            <div style={{ display: 'flex', alignItems: 'flex-end', gap: 4, height: 44 }}>
              {BARS.map((h, i) => (
                <div key={i} style={{
                  flex: 1, height: `${h}%`, borderRadius: 3,
                  background: i === 5
                    ? 'linear-gradient(to top, #FF5A00, #FF3B73)'
                    : 'rgba(255,255,255,0.10)',
                }} />
              ))}
            </div>
            <div style={{ display: 'flex', marginTop: 4 }}>
              {DAYS.map((d, i) => (
                <span key={i} style={{
                  flex: 1, textAlign: 'center', fontSize: 7, fontWeight: 600,
                  color: i === 5 ? '#FF5A00' : 'rgba(255,255,255,0.22)',
                }}>{d}</span>
              ))}
            </div>
          </div>
        </div>

        {/* Bottom nav */}
        <div style={{
          display: 'flex', justifyContent: 'space-around', alignItems: 'center',
          padding: '8px 12px 12px',
          borderTop: '1px solid rgba(255,255,255,0.06)',
          background: 'rgba(0,0,0,0.35)',
          backdropFilter: 'blur(10px)',
        }}>
          {[true, false, false, false].map((active, i) => (
            <div key={i} style={{
              width: 36, height: 36, borderRadius: 10,
              background: active ? 'linear-gradient(135deg, #FF5A00, #FF3B73)' : 'transparent',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
            }}>
              <div style={{
                width: active ? 12 : 14,
                height: active ? 12 : 14,
                borderRadius: active ? 3 : 7,
                background: active ? 'rgba(255,255,255,0.95)' : 'rgba(255,255,255,0.22)',
              }} />
            </div>
          ))}
        </div>
      </div>
    </div>
  )
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
    border: `1.5px solid ${focused === field ? '#FF5A00' : '#ECECEC'}`,
    padding: '0 24px',
    fontSize: 15,
    color: '#111111',
    background: '#FFFFFF',
    outline: 'none',
    transition: 'border-color 0.2s ease, box-shadow 0.2s ease',
    boxShadow: focused === field
      ? '0 0 0 4px rgba(255,90,0,0.10), 0 2px 12px rgba(0,0,0,0.06)'
      : '0 2px 8px rgba(0,0,0,0.04)',
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
          0%,100% { opacity: 0.07; transform: translate(-50%,-50%) scale(1);    }
          50%      { opacity: 0.14; transform: translate(-50%,-50%) scale(1.03); }
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
        .d6 { animation-delay: 0.55s; }
        .d7 { animation-delay: 0.65s; }
        .dr1 { animation-delay: 0s;    }
        .dr2 { animation-delay: 1.5s;  }
        .dr3 { animation-delay: 3s;    }

        .lu-input::placeholder { color: #AAAAAA; font-size: 15px; }
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
            background: '#1F1A19',
            position: 'relative',
            overflow: 'hidden',
          }}
        >
          {/* ── Concentric pulsing rings ── */}
          {[530, 400, 270].map((sz, i) => (
            <div
              key={sz}
              className={`lu-ring dr${i + 1}`}
              style={{
                position: 'absolute',
                width: sz, height: sz,
                borderRadius: '50%',
                border: '1px solid rgba(255,255,255,0.12)',
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
            background: 'radial-gradient(circle, rgba(255,90,0,0.07) 0%, transparent 70%)',
            top: '18%', left: '30%',
            transform: 'translate(-50%,-50%)',
            pointerEvents: 'none',
          }} />
          <div style={{
            position: 'absolute',
            width: 360, height: 360,
            borderRadius: '50%',
            background: 'radial-gradient(circle, rgba(255,59,115,0.05) 0%, transparent 70%)',
            top: '70%', left: '70%',
            transform: 'translate(-50%,-50%)',
            pointerEvents: 'none',
          }} />

          {/* ── Text content ── */}
          <div style={{ padding: '44px 52px 0', position: 'relative', zIndex: 1 }}>

            {/* Subtitle / tagline */}
            <p
              className={mounted ? 'lu-fade-left d1' : ''}
              style={{
                fontSize: 13, fontWeight: 500,
                color: 'rgba(255,255,255,0.38)',
                letterSpacing: '0.01em',
                marginBottom: 20,
              }}
            >
              Secure digital payments and financial management.
            </p>

            {/* Main headline */}
            <h1
              className={mounted ? 'lu-fade-left d2' : ''}
              style={{
                fontSize: 58,
                fontWeight: 800,
                color: '#FFFFFF',
                lineHeight: 1.07,
                letterSpacing: '-0.035em',
                margin: 0,
              }}
            >
              Manage<br />your{' '}
              <span style={{
                background: 'linear-gradient(135deg, #FF5A00 30%, #FF3B73 100%)',
                WebkitBackgroundClip: 'text',
                WebkitTextFillColor: 'transparent',
                backgroundClip: 'text',
              }}>
                finances
              </span>
              <br />effortlessly.
            </h1>
          </div>

          {/* ── Phone mockup — bottom-left, slightly cut off ── */}
          <div
            className={mounted ? 'lu-phone' : ''}
            style={{
              position: 'absolute',
              bottom: -42,
              left: 52,
              zIndex: 2,
            }}
          >
            <PhoneMockup />
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
              <img
                src="/mali_up_wordmark.png"
                alt="Mali Up"
                style={{ width: 38, height: 38, borderRadius: '50%' }}
              />
              <span style={{ fontSize: 16, fontWeight: 700, color: '#111111', letterSpacing: '-0.01em' }}>
                Mali Up
              </span>
            </div>
            <button
              className={mounted ? 'lu-fade-up d1' : ''}
              type="button"
              style={{
                display: 'flex', alignItems: 'center', gap: 6,
                fontSize: 13, fontWeight: 600,
                color: '#444444',
                background: 'transparent',
                border: '1.5px solid #ECECEC',
                borderRadius: 999,
                padding: '8px 18px',
                cursor: 'pointer',
                transition: 'all 0.2s ease',
              }}
            >
              <ShieldCheck size={14} />
              Admin only
            </button>
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
                  color: '#111111',
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
                      color: '#AAAAAA', background: 'none', border: 'none',
                      cursor: 'pointer', display: 'flex',
                      transition: 'color 0.15s',
                      padding: 0,
                    }}
                    tabIndex={-1}
                  >
                    {showPassword ? <EyeOff size={18} /> : <Eye size={18} />}
                  </button>
                </div>

                {/* Forgot password */}
                <div className={mounted ? 'lu-fade-up d4' : ''}>
                  <button
                    type="button"
                    style={{
                      fontSize: 13, fontWeight: 600,
                      color: '#FF5A00',
                      background: 'none', border: 'none',
                      cursor: 'pointer', padding: 0,
                      transition: 'opacity 0.15s',
                    }}
                  >
                    Forgot password?
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
                    style={{
                      width: '100%',
                      height: 56,
                      borderRadius: 999,
                      border: 'none',
                      background: disabled
                        ? '#E8E8E8'
                        : btnHov
                        ? 'linear-gradient(to right, #FF3B73, #FF5A00)'
                        : 'linear-gradient(to right, #FF5A00, #FF3B73)',
                      color: disabled ? '#AAAAAA' : '#FFFFFF',
                      fontSize: 15,
                      fontWeight: 700,
                      cursor: disabled ? 'not-allowed' : 'pointer',
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                      gap: 8,
                      letterSpacing: '0.005em',
                      transition: 'all 0.28s cubic-bezier(0.22,1,0.36,1)',
                      boxShadow: disabled
                        ? 'none'
                        : btnHov
                        ? '0 14px 48px rgba(255,59,115,0.42)'
                        : '0 8px 28px rgba(255,90,0,0.32)',
                      transform: btnHov && !disabled ? 'translateY(-2px)' : 'translateY(0)',
                      marginTop: 4,
                      fontFamily: 'inherit',
                    }}
                  >
                    <ArrowRight size={18} />
                    {loading ? 'Signing in…' : 'Sign In'}
                  </button>
                </div>

                {/* Sign up */}
                <div
                  className={mounted ? 'lu-fade-up d6' : ''}
                  style={{ textAlign: 'center', marginTop: 2 }}
                >
                  <span style={{ fontSize: 13, color: '#777777' }}>
                    {'Don\'t have an account? '}
                    <button
                      type="button"
                      style={{
                        fontSize: 13, fontWeight: 600,
                        color: '#111111',
                        background: 'none', border: 'none',
                        cursor: 'pointer',
                        textDecoration: 'underline',
                        textUnderlineOffset: 3,
                        fontFamily: 'inherit',
                        padding: 0,
                      }}
                    >
                      Sign Up
                    </button>
                  </span>
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
            borderTop: '1px solid #F3F3F3',
          }}>
            <span style={{ fontSize: 12, color: '#BBBBBB' }}>
              © 2005–2025 Neuraltale Technology
            </span>
            <div style={{ display: 'flex', alignItems: 'center', gap: 24 }}>
              <button
                type="button"
                style={{ fontSize: 12, color: '#888888', background: 'none', border: 'none', cursor: 'pointer', fontFamily: 'inherit' }}
              >
                Contact Us
              </button>
              <button
                type="button"
                style={{
                  display: 'flex', alignItems: 'center', gap: 4,
                  fontSize: 12, color: '#888888',
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
