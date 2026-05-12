"use client"

import { useState } from "react"
import NextImage from "next/image"
import { REGEXP_ONLY_DIGITS } from "input-otp"
import { Dialog, DialogContent, DialogTitle } from "@/components/ui/dialog"
import { InputOTP, InputOTPGroup, InputOTPSlot } from "@/components/ui/input-otp"

interface LoginModalProps {
  open: boolean
  onClose: () => void
}

type Step = "method" | "otp"

export function LoginModal({ open, onClose }: LoginModalProps) {
  const [step, setStep] = useState<Step>("method")
  const [countryCode, setCountryCode] = useState("+254")
  const [phone, setPhone] = useState("")
  const [otp, setOtp] = useState("")
  const [loading, setLoading] = useState(false)

  function reset() {
    setStep("method")
    setPhone("")
    setOtp("")
    setLoading(false)
  }

  function handleOpenChange(isOpen: boolean) {
    if (!isOpen) {
      reset()
      onClose()
    }
  }

  function handleSendOtp(e: React.FormEvent) {
    e.preventDefault()
    if (!phone.trim()) return
    setLoading(true)
    // TODO: call OTP send API
    setTimeout(() => {
      setLoading(false)
      setStep("otp")
    }, 900)
  }

  function handleVerifyOtp(e: React.FormEvent) {
    e.preventDefault()
    if (otp.length < 6) return
    setLoading(true)
    // TODO: verify OTP and redirect to dashboard
    setTimeout(() => {
      setLoading(false)
    }, 900)
  }

  function handleGoogleSignIn() {
    // TODO: trigger Google OAuth flow
  }

  return (
    <Dialog open={open} onOpenChange={handleOpenChange}>
      <DialogContent
        className="sm:max-w-sm p-8 rounded-2xl"
        showCloseButton
      >
        {/* Brand header */}
        <div className="flex flex-col items-center gap-3 mb-2">
          <NextImage
            src="/maliup-logo.png"
            alt="Mali Up"
            width={48}
            height={48}
            className="rounded-2xl shadow-md"
          />
          <div className="text-center">
            <DialogTitle className="font-heading text-xl font-bold text-foreground">
              Sign in to Mali<span className="text-accent">Up</span>
            </DialogTitle>
            <p className="text-muted-foreground text-xs mt-1 leading-relaxed">
              Business management · Financial tools
            </p>
          </div>
        </div>

        {/* ── Step 1: choose method ── */}
        {step === "method" && (
          <div className="flex flex-col gap-4 mt-4">
            {/* Google */}
            <button
              type="button"
              onClick={handleGoogleSignIn}
              className="w-full flex items-center justify-center gap-3 px-4 py-3 border border-border rounded-xl text-sm font-medium text-foreground bg-background hover:bg-secondary transition-colors"
            >
              <GoogleIcon />
              Continue with Google
            </button>

            {/* Divider */}
            <div className="flex items-center gap-3">
              <div className="flex-1 h-px bg-border" />
              <span className="text-muted-foreground text-[11px] tracking-wide">or</span>
              <div className="flex-1 h-px bg-border" />
            </div>

            {/* Phone form */}
            <form onSubmit={handleSendOtp} className="flex flex-col gap-3">
              <label className="text-[11px] font-semibold text-muted-foreground uppercase tracking-widest">
                Phone number
              </label>

              <div className="flex gap-2">
                <input
                  type="text"
                  value={countryCode}
                  onChange={(e) => setCountryCode(e.target.value)}
                  className="w-20 px-3 py-3 border border-border rounded-xl text-sm text-center font-medium bg-secondary/60 focus:outline-none focus:ring-2 focus:ring-ring"
                  aria-label="Country code"
                />
                <input
                  type="tel"
                  value={phone}
                  onChange={(e) => setPhone(e.target.value)}
                  placeholder="712 345 678"
                  required
                  className="flex-1 px-4 py-3 border border-border rounded-xl text-sm bg-background focus:outline-none focus:ring-2 focus:ring-ring"
                />
              </div>

              <button
                type="submit"
                disabled={loading || !phone.trim()}
                className="w-full py-3 rounded-xl text-sm font-semibold bg-foreground text-primary-foreground transition-all hover:opacity-90 active:scale-95 disabled:opacity-40 disabled:cursor-not-allowed"
              >
                {loading ? "Sending…" : "Send verification code"}
              </button>
            </form>
          </div>
        )}

        {/* ── Step 2: OTP verify ── */}
        {step === "otp" && (
          <form
            onSubmit={handleVerifyOtp}
            className="flex flex-col items-center gap-5 mt-4"
          >
            <div className="text-center">
              <p className="text-sm font-medium text-foreground">
                Code sent to {countryCode} {phone}
              </p>
              <p className="text-muted-foreground text-xs mt-1">
                Enter the 6-digit verification code
              </p>
            </div>

            <InputOTP
              maxLength={6}
              pattern={REGEXP_ONLY_DIGITS}
              value={otp}
              onChange={setOtp}
              autoFocus
            >
              <InputOTPGroup>
                {[0, 1, 2, 3, 4, 5].map((i) => (
                  <InputOTPSlot
                    key={i}
                    index={i}
                    className="w-11 h-12 text-base"
                  />
                ))}
              </InputOTPGroup>
            </InputOTP>

            <button
              type="submit"
              disabled={loading || otp.length < 6}
              className="w-full py-3 rounded-xl text-sm font-semibold bg-foreground text-primary-foreground transition-all hover:opacity-90 active:scale-95 disabled:opacity-40 disabled:cursor-not-allowed"
            >
              {loading ? "Verifying…" : "Verify & Sign In"}
            </button>

            <button
              type="button"
              onClick={() => {
                setStep("method")
                setOtp("")
              }}
              className="text-xs text-muted-foreground hover:text-foreground transition-colors"
            >
              ← Change number
            </button>
          </form>
        )}

        {/* Footer */}
        <p className="text-center text-[10px] text-muted-foreground/50 mt-3">
          By signing in you agree to our{" "}
          <a href="#" className="underline hover:text-foreground transition-colors">
            Terms
          </a>{" "}
          &{" "}
          <a href="#" className="underline hover:text-foreground transition-colors">
            Privacy Policy
          </a>
        </p>
      </DialogContent>
    </Dialog>
  )
}

function GoogleIcon() {
  return (
    <svg className="w-4 h-4 shrink-0" viewBox="0 0 24 24" aria-hidden>
      <path
        fill="#4285F4"
        d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"
      />
      <path
        fill="#34A853"
        d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"
      />
      <path
        fill="#FBBC05"
        d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z"
      />
      <path
        fill="#EA4335"
        d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"
      />
    </svg>
  )
}
