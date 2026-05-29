"use client";

import { Suspense, useState } from "react";
import { signIn } from "next-auth/react";
import { useRouter, useSearchParams } from "next/navigation";
import { ShieldCheck, Eye, EyeOff, Loader2 } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";

function LoginForm() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const callbackUrl = searchParams.get("callbackUrl") ?? "/admin";

  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [showPassword, setShowPassword] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setLoading(true);
    setError("");

    const result = await signIn("credentials", {
      email,
      password,
      redirect: false,
    });

    setLoading(false);

    if (result?.error) {
      setError("Invalid credentials. Check your email and password.");
    } else {
      router.push(callbackUrl);
      router.refresh();
    }
  }

  return (
    <div className="min-h-screen flex" style={{ backgroundColor: "#F8F9FC" }}>
      {/* Left panel */}
      <div
        className="hidden lg:flex lg:w-1/2 flex-col justify-between p-12"
        style={{ backgroundColor: "#0D1B3E" }}
      >
        <div className="flex items-center gap-3">
          <div className="h-9 w-9 rounded-lg bg-[#FFC107] flex items-center justify-center">
            <ShieldCheck className="h-5 w-5 text-[#0D1B3E]" />
          </div>
          <div>
            <p className="text-white font-bold text-lg leading-tight">Mali Up</p>
            <p className="text-[#1A6E8A] text-xs font-semibold uppercase tracking-widest">
              Admin Portal
            </p>
          </div>
        </div>

        <div className="space-y-4">
          <h2 className="text-4xl font-bold text-white leading-tight">
            Platform Operations<br />
            <span style={{ color: "#FFC107" }}>Command Center</span>
          </h2>
          <p className="text-white/60 text-base max-w-sm">
            Complete visibility and control over the Mali Up platform — users,
            businesses, billing, and system health in one place.
          </p>
        </div>

        <p className="text-white/30 text-xs">
          Neuraltale Technology — Internal use only
        </p>
      </div>

      {/* Right panel */}
      <div className="flex-1 flex items-center justify-center p-6">
        <div className="w-full max-w-sm space-y-8">
          <div className="lg:hidden flex items-center gap-3 mb-8">
            <div className="h-9 w-9 rounded-lg bg-[#0D1B3E] flex items-center justify-center">
              <ShieldCheck className="h-5 w-5 text-[#FFC107]" />
            </div>
            <div>
              <p className="font-bold text-slate-900">Mali Up Admin</p>
              <p className="text-slate-400 text-xs">Neuraltale Technology</p>
            </div>
          </div>

          <div>
            <h1 className="text-2xl font-bold text-slate-900">Sign in to Admin</h1>
            <p className="mt-1 text-sm text-slate-500">
              Authorized staff only. All access is logged.
            </p>
          </div>

          <form onSubmit={handleSubmit} className="space-y-4">
            <div className="space-y-2">
              <Label htmlFor="email">Email address</Label>
              <Input
                id="email"
                type="email"
                placeholder="you@neuraltale.com"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                required
                autoComplete="email"
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="password">Password</Label>
              <div className="relative">
                <Input
                  id="password"
                  type={showPassword ? "text" : "password"}
                  placeholder="••••••••"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  required
                  autoComplete="current-password"
                  className="pr-10"
                />
                <button
                  type="button"
                  onClick={() => setShowPassword(!showPassword)}
                  className="absolute right-3 top-1/2 -translate-y-1/2 text-slate-400 hover:text-slate-600"
                >
                  {showPassword ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
                </button>
              </div>
            </div>

            {error && (
              <div className="rounded-lg bg-red-50 border border-red-200 px-4 py-3 text-sm text-red-700">
                {error}
              </div>
            )}

            {process.env.NEXT_PUBLIC_USE_MOCK === "true" && (
              <div className="rounded-lg bg-amber-50 border border-amber-200 px-4 py-3 text-xs text-amber-700">
                <strong>Dev mode:</strong> Use super@neuraltale.com, ops@neuraltale.com,
                support@neuraltale.com, or dev@neuraltale.com with any password.
              </div>
            )}

            <Button
              type="submit"
              disabled={loading}
              className="w-full font-semibold"
              style={{ backgroundColor: "#0D1B3E" }}
            >
              {loading ? (
                <>
                  <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                  Signing in...
                </>
              ) : (
                "Sign in to Admin Portal"
              )}
            </Button>
          </form>

          <p className="text-center text-xs text-slate-400">
            Access restricted to Neuraltale Technology staff.<br />
            Unauthorized access attempts are logged and prosecuted.
          </p>
        </div>
      </div>
    </div>
  );
}

export default function AdminLoginPage() {
  return (
    <Suspense fallback={<div className="min-h-screen bg-[#F8F9FC]" />}>
      <LoginForm />
    </Suspense>
  );
}
