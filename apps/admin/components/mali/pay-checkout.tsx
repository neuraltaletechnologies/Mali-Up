"use client"

import { useEffect, useState } from "react"
import { ArrowLeft, CheckCircle2, Loader2, Phone, ShieldCheck, Smartphone, XCircle } from "lucide-react"
import {
  DEFAULT_PUBLIC_PRICES,
  PLAN_COPY,
  formatTZS,
  priceFor,
  type BillingCycle,
  type PublicPlanPrices,
  type PublicTier,
} from "@/lib/public-plans"
import { BUSINESS_TYPES } from "@/lib/business-types"
import {
  canonicalPhone,
  createAccount,
  findAccount,
  friendlyError,
  isTzMobile,
  listOwnedBusinesses,
  logout,
  sendOtp,
  startPayment,
  verifyOtp,
  waitForPayment,
  type FoundAccount,
  type OwnedBusiness,
} from "@/lib/pay-client"

const PLAY_STORE_URL = "https://play.google.com/store/apps/details?id=com.neuraltale.maliup"
const SUPPORT_URL = "https://neuraltale.com/#contact"

type Step =
  | "phone"     // 1. who are you?
  | "otp"       // 2b. new owner: SMS code
  | "details"   // 2b. new owner: name, business, PIN
  | "checkout"  // 3. plan + cycle + pay
  | "waiting"   // 3. USSD prompt sent
  | "done"      // paid (or free account created)
  | "failed"    // payment failed / timed out

// ─── Small building blocks ───────────────────────────────────────────────────

const inputCls =
  "w-full rounded-xl border border-[#0C1B2E]/15 bg-white px-4 py-3.5 text-[16px] text-[#0C1B2E] outline-none transition-colors focus:border-[#F5A623] focus:ring-2 focus:ring-[#F5A623]/25"

function PrimaryButton({
  children, loading, disabled, onClick, type = "button",
}: {
  children: React.ReactNode
  loading?: boolean
  disabled?: boolean
  onClick?: () => void
  type?: "button" | "submit"
}) {
  return (
    <button
      type={type}
      onClick={onClick}
      disabled={disabled || loading}
      className="w-full rounded-xl bg-[#0C1B2E] px-6 py-3.5 text-[15px] font-bold text-white transition-opacity hover:opacity-90 disabled:opacity-40 flex items-center justify-center gap-2"
    >
      {loading && <Loader2 size={16} className="animate-spin" />}
      {children}
    </button>
  )
}

function Field({ label, hint, children }: { label: string; hint?: string; children: React.ReactNode }) {
  return (
    <label className="flex flex-col gap-1.5">
      <span className="text-[13px] font-semibold text-[#0C1B2E]">{label}</span>
      {children}
      {hint && <span className="text-[12px] text-[#0C1B2E]/50">{hint}</span>}
    </label>
  )
}

function ErrorNote({ message }: { message: string }) {
  if (!message) return null
  return (
    <div role="alert" className="rounded-xl bg-red-50 border border-red-200 px-4 py-3 text-[13px] text-red-700">
      {message}
    </div>
  )
}

function Progress({ step }: { step: Step }) {
  const index = step === "phone" ? 0 : step === "otp" || step === "details" ? 1 : 2
  const labels = ["Namba ya simu", "Akaunti", "Lipa"]
  return (
    <ol className="flex items-center gap-2 mb-8" aria-label="Hatua">
      {labels.map((label, i) => (
        <li key={label} className="flex-1 flex flex-col gap-1.5">
          <div className={`h-1.5 rounded-full ${i <= index ? "bg-[#F5A623]" : "bg-[#0C1B2E]/10"}`} />
          <span className={`text-[11px] font-semibold ${i <= index ? "text-[#0C1B2E]" : "text-[#0C1B2E]/40"}`}>
            {i + 1}. {label}
          </span>
        </li>
      ))}
    </ol>
  )
}

// ─── Checkout ────────────────────────────────────────────────────────────────

export function PayCheckout({ initialTier, initialCycle }: { initialTier: PublicTier; initialCycle: BillingCycle }) {
  const [prices, setPrices] = useState<PublicPlanPrices>(DEFAULT_PUBLIC_PRICES)
  const [tier] = useState<PublicTier>(initialTier)
  const [cycle] = useState<BillingCycle>(initialCycle)

  const [step, setStep] = useState<Step>("phone")
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState("")

  const [phone, setPhone] = useState("")
  const [account, setAccount] = useState<FoundAccount | null>(null)

  const [pinId, setPinId] = useState("")
  const [code, setCode] = useState("")
  const [fullName, setFullName] = useState("")
  const [businessName, setBusinessName] = useState("")
  const [businessType, setBusinessType] = useState("retail")
  const [newPin, setNewPin] = useState("")
  const [newPinConfirm, setNewPinConfirm] = useState("")
  const [isNewAccount, setIsNewAccount] = useState(false)

  const [businesses, setBusinesses] = useState<OwnedBusiness[]>([])
  const [businessId, setBusinessId] = useState("")
  const [payPhone, setPayPhone] = useState("")
  const [planExpiresAt, setPlanExpiresAt] = useState<string | null>(null)

  useEffect(() => {
    fetch("/api/plans")
      .then((r) => r.json())
      .then((d: { prices?: PublicPlanPrices }) => d.prices && setPrices(d.prices))
      .catch(() => { /* defaults stay */ })
    // A previous visitor's session in this tab shouldn't carry over.
    void logout()
  }, [])

  const amount = tier === "starter" ? 0 : priceFor(prices, tier, cycle)
  const selectedBusiness = businesses.find((b) => b.id === businessId)
  const firstName = ((isNewAccount ? fullName : account?.name) ?? "").trim().split(/\s+/)[0] ?? ""

  function go(next: Step) {
    setError("")
    setStep(next)
  }

  async function run(fn: () => Promise<void>) {
    setBusy(true)
    setError("")
    try {
      await fn()
    } catch (e) {
      setError(friendlyError(e))
    } finally {
      setBusy(false)
    }
  }

  async function enterCheckout(uid: string) {
    const owned = await listOwnedBusinesses(uid)
    if (owned.length === 0) {
      setError("Hatukupata biashara iliyosajiliwa kwa namba hii. Mmiliki wa biashara pekee ndiye anaweza kulipia kifurushi.")
      return
    }
    setBusinesses(owned)
    setBusinessId(owned[0].id)
    setPayPhone(canonicalPhone(phone))
    go("checkout")
  }

  // Step 1 — phone
  const submitPhone = () =>
    run(async () => {
      if (canonicalPhone(phone).length < 12) {
        setError("Weka namba sahihi ya simu, mfano 0712 345 678.")
        return
      }
      const found = await findAccount(phone)
      if (found?.isTeamMember) {
        setError("Namba hii ni ya mfanyakazi. Mmiliki wa biashara pekee ndiye anaweza kulipia kifurushi.")
        return
      }
      setAccount(found)
      if (found) {
        // Existing owner: no PIN on the website — the phone number alone
        // identifies them, and the server re-checks it owns the business.
        setIsNewAccount(false)
        await enterCheckout(found.uid)
      } else {
        setIsNewAccount(true)
        setPinId(await sendOtp(phone))
        go("otp")
      }
    })

  // Step 2b — new owner OTP
  const submitOtp = () =>
    run(async () => {
      const ok = await verifyOtp(phone, pinId, code.trim())
      if (!ok) {
        setError("Msimbo si sahihi au umeisha muda. Jaribu tena au omba mpya.")
        return
      }
      go("details")
    })

  const resendOtp = () =>
    run(async () => {
      setPinId(await sendOtp(phone))
      setCode("")
    })

  // Step 2b — new owner details
  const submitDetails = () =>
    run(async () => {
      if (!fullName.trim() || !businessName.trim()) {
        setError("Jaza jina lako na jina la biashara.")
        return
      }
      if (!/^\d{4}$/.test(newPin)) {
        setError("PIN iwe tarakimu 4.")
        return
      }
      if (newPin !== newPinConfirm) {
        setError("PIN hazifanani. Ziandike tena.")
        return
      }
      const { uid } = await createAccount({ phone, pin: newPin, fullName, businessName, businessType })
      await enterCheckout(uid)
    })

  // Step 3 — pay
  const submitPayment = () =>
    run(async () => {
      if (tier === "starter") {
        go("done")
        return
      }
      if (!isTzMobile(payPhone)) {
        setError("Weka namba ya M-Pesa, Tigo Pesa, Airtel Money au HaloPesa (mfano 0712 345 678).")
        return
      }
      const ref = await startPayment({ ownerPhone: phone, tier, billingCycle: cycle, businessId, phoneNumber: payPhone })
      go("waiting")
      const outcome = await waitForPayment(ref)
      if (outcome.status === "completed") {
        setPlanExpiresAt(outcome.planExpiresAt)
        go("done")
      } else {
        go("failed")
      }
    })

  // ─── Render ────────────────────────────────────────────────────────────────

  const planChip = (
    <div className="mb-6 flex items-center justify-between gap-3 rounded-xl border border-[#0C1B2E]/10 bg-white px-4 py-3">
      <div className="text-[13px] text-[#0C1B2E]/70">
        Umechagua: <strong className="text-[#0C1B2E]">{PLAN_COPY[tier].name}</strong>
        {tier !== "starter" && <> · {formatTZS(amount)}/{cycle === "yearly" ? "mwaka" : "mwezi"}</>}
      </div>
      <span className="text-[12px] text-[#0C1B2E]/45">Unaweza kubadilisha baadaye</span>
    </div>
  )

  return (
    <div className="max-w-lg mx-auto px-5 py-10 md:py-14">
      <a href="/#pricing" className="text-sm text-[#0C1B2E]/50 hover:text-[#0C1B2E] inline-flex items-center gap-1.5 mb-6">
        <ArrowLeft size={14} /> Rudi kwenye vifurushi
      </a>

      <div className="rounded-3xl bg-white border border-[#0C1B2E]/[0.08] shadow-sm p-6 md:p-8">
        {step !== "done" && step !== "failed" && step !== "waiting" && <Progress step={step} />}

        {/* ── 1. Phone ───────────────────────────────────────────────── */}
        {step === "phone" && (
          <form className="flex flex-col gap-5" onSubmit={(e) => { e.preventDefault(); submitPhone() }}>
            <div>
              <h1 className="font-heading font-bold text-[#0C1B2E] text-2xl mb-1">Lipia kifurushi chako</h1>
              <p className="text-[14px] text-[#0C1B2E]/60 leading-relaxed">
                Huhitaji kupakua programu. Weka namba yako ya simu — kama una akaunti tutakutambua
                mara moja, kama ni mpya tutakufungulia akaunti sasa hivi.
              </p>
              <p className="text-[12px] text-[#0C1B2E]/40 mt-1">Pay without the app. New or existing users.</p>
            </div>
            {planChip}
            <Field label="Namba ya simu" hint="Ile unayotumia (au utakayotumia) kuingia Mali Up">
              <div className="relative">
                <Phone size={16} className="absolute left-4 top-1/2 -translate-y-1/2 text-[#0C1B2E]/40" />
                <input
                  className={`${inputCls} pl-11`}
                  type="tel"
                  inputMode="tel"
                  autoComplete="tel"
                  placeholder="0712 345 678"
                  value={phone}
                  onChange={(e) => setPhone(e.target.value)}
                  autoFocus
                />
              </div>
            </Field>
            <ErrorNote message={error} />
            <PrimaryButton type="submit" loading={busy}>Endelea</PrimaryButton>
          </form>
        )}

        {/* ── 2b. OTP ────────────────────────────────────────────────── */}
        {step === "otp" && (
          <form className="flex flex-col gap-5" onSubmit={(e) => { e.preventDefault(); submitOtp() }}>
            <div>
              <h1 className="font-heading font-bold text-[#0C1B2E] text-2xl mb-1">Karibu Mali Up! 👋</h1>
              <div className="rounded-xl bg-[#F5A623]/10 border border-[#F5A623]/30 px-4 py-3 text-[13px] text-[#0C1B2E]/80 mb-3">
                Hatukupata akaunti yenye namba <strong>+{canonicalPhone(phone)}</strong> — kwa hiyo
                tunakufungulia akaunti mpya sasa hivi. Ni bure na inachukua dakika moja.
              </div>
              <p className="text-[14px] text-[#0C1B2E]/60">
                Tumekutumia msimbo kwa SMS. Uweke hapa kuthibitisha kuwa namba ni yako.
              </p>
            </div>
            <Field label="Msimbo wa SMS">
              <input
                className={`${inputCls} tracking-[0.4em] text-center text-xl`}
                inputMode="numeric"
                autoComplete="one-time-code"
                maxLength={8}
                value={code}
                onChange={(e) => setCode(e.target.value.replace(/\D/g, "").slice(0, 8))}
                autoFocus
              />
            </Field>
            <ErrorNote message={error} />
            <PrimaryButton type="submit" loading={busy} disabled={code.length < 4}>Thibitisha</PrimaryButton>
            <div className="flex items-center justify-between text-[13px]">
              <button type="button" onClick={() => go("phone")} className="text-[#0C1B2E]/55 hover:text-[#0C1B2E]">
                Badilisha namba
              </button>
              <button type="button" onClick={resendOtp} disabled={busy} className="text-[#0C1B2E]/55 hover:text-[#0C1B2E]">
                Tuma msimbo upya
              </button>
            </div>
          </form>
        )}

        {/* ── 2b. New account details ────────────────────────────────── */}
        {step === "details" && (
          <form className="flex flex-col gap-4" onSubmit={(e) => { e.preventDefault(); submitDetails() }}>
            <div className="mb-1">
              <h1 className="font-heading font-bold text-[#0C1B2E] text-2xl mb-1">Fungua akaunti yako</h1>
              <p className="text-[14px] text-[#0C1B2E]/60">Inachukua chini ya dakika moja.</p>
            </div>
            <Field label="Jina lako kamili">
              <input className={inputCls} autoComplete="name" value={fullName} onChange={(e) => setFullName(e.target.value)} autoFocus />
            </Field>
            <Field label="Jina la biashara">
              <input className={inputCls} value={businessName} onChange={(e) => setBusinessName(e.target.value)} placeholder="mfano: Duka la Mama Neema" />
            </Field>
            <Field label="Aina ya biashara">
              <select className={inputCls} value={businessType} onChange={(e) => setBusinessType(e.target.value)}>
                {BUSINESS_TYPES.map((t) => <option key={t.key} value={t.key}>{t.label}</option>)}
              </select>
            </Field>
            <div className="grid grid-cols-2 gap-3">
              <Field label="PIN mpya ya Mali Up">
                <input
                  className={`${inputCls} tracking-[0.4em] text-center`}
                  type="password" inputMode="numeric" autoComplete="new-password" maxLength={4}
                  value={newPin} onChange={(e) => setNewPin(e.target.value.replace(/\D/g, "").slice(0, 4))}
                />
              </Field>
              <Field label="Rudia PIN">
                <input
                  className={`${inputCls} tracking-[0.4em] text-center`}
                  type="password" inputMode="numeric" autoComplete="new-password" maxLength={4}
                  value={newPinConfirm} onChange={(e) => setNewPinConfirm(e.target.value.replace(/\D/g, "").slice(0, 4))}
                />
              </Field>
            </div>
            <p className="text-[12px] text-[#0C1B2E]/50 -mt-1">
              Tarakimu 4 utakazotumia kuingia kwenye programu ya Mali Up. Usiweke PIN yako ya M-Pesa
              au benki hapa.
            </p>
            <ErrorNote message={error} />
            <PrimaryButton type="submit" loading={busy}>Fungua akaunti</PrimaryButton>
          </form>
        )}

        {/* ── 3. Checkout ────────────────────────────────────────────── */}
        {step === "checkout" && (
          <form className="flex flex-col gap-5" onSubmit={(e) => { e.preventDefault(); submitPayment() }}>
            <div>
              <h1 className="font-heading font-bold text-[#0C1B2E] text-2xl mb-1">
                {firstName
                  ? isNewAccount ? `Hongera ${firstName}! 🎉` : `Karibu tena, ${firstName}! 👋`
                  : isNewAccount ? "Hongera! 🎉" : "Karibu tena! 👋"}
              </h1>
              <p className="text-[14px] text-[#0C1B2E]/60">
                {isNewAccount
                  ? tier === "starter"
                    ? "Akaunti yako iko tayari."
                    : "Akaunti yako iko tayari. Weka namba ya kulipia, kisha bofya Lipa."
                  : tier === "starter"
                    ? "Uko tayari kuendelea na kifurushi cha Bure."
                    : "Tumekutambua. Weka namba ya kulipia, kisha bofya Lipa."}
              </p>
            </div>

            {/* What they picked on the pricing page — no re-choosing here */}
            <div className="rounded-2xl bg-[#0C1B2E] text-white px-5 py-4 flex items-center justify-between gap-4">
              <div>
                <div className="font-bold text-[16px]">{PLAN_COPY[tier].name}</div>
                <div className="text-[12px] text-white/60">
                  {tier === "starter" ? "Bure milele" : cycle === "yearly" ? "Kila mwaka · miezi 12" : "Kila mwezi · mwezi 1"}
                  {selectedBusiness && businesses.length === 1 && <> · {selectedBusiness.name}</>}
                </div>
              </div>
              <div className="text-right">
                <div className="font-black text-[20px] text-[#F5A623]">{tier === "starter" ? "Bure" : formatTZS(amount)}</div>
                <a href="/#pricing" className="text-[11px] text-white/50 underline hover:text-white">Badilisha</a>
              </div>
            </div>

            {businesses.length > 1 && (
              <Field label="Biashara ipi?">
                <select className={inputCls} value={businessId} onChange={(e) => setBusinessId(e.target.value)}>
                  {businesses.map((b) => <option key={b.id} value={b.id}>{b.name}</option>)}
                </select>
              </Field>
            )}
            {selectedBusiness && <CurrentPlanNote business={selectedBusiness} />}

            {tier !== "starter" && (
              <Field label="Namba ya kulipia" hint="M-Pesa, Tigo Pesa (Mixx), Airtel Money au HaloPesa">
                <div className="relative">
                  <Smartphone size={16} className="absolute left-4 top-1/2 -translate-y-1/2 text-[#0C1B2E]/40" />
                  <input
                    className={`${inputCls} pl-11`}
                    type="tel" inputMode="tel"
                    value={payPhone}
                    onChange={(e) => setPayPhone(e.target.value)}
                  />
                </div>
              </Field>
            )}

            <ErrorNote message={error} />
            <PrimaryButton type="submit" loading={busy}>
              {tier === "starter" ? "Endelea na Bure" : `Lipa ${formatTZS(amount)}`}
            </PrimaryButton>
            {tier !== "starter" && (
              <p className="flex items-center justify-center gap-1.5 text-[12px] text-[#0C1B2E]/45">
                <ShieldCheck size={13} /> Malipo salama kupitia ClickPesa. Kifurushi kinawaka papo hapo.
              </p>
            )}
          </form>
        )}

        {/* ── Waiting for USSD confirmation ──────────────────────────── */}
        {step === "waiting" && (
          <div className="flex flex-col items-center text-center gap-4 py-6">
            <div className="w-16 h-16 rounded-full bg-[#F5A623]/15 flex items-center justify-center">
              <Smartphone size={30} className="text-[#F5A623]" />
            </div>
            <h1 className="font-heading font-bold text-[#0C1B2E] text-2xl">Angalia simu yako</h1>
            <p className="text-[14px] text-[#0C1B2E]/65 leading-relaxed max-w-sm">
              Tumetuma ombi la malipo ya <strong>{formatTZS(amount)}</strong> kwenda <strong>+{canonicalPhone(payPhone)}</strong>.
              Weka PIN yako ya pesa ya simu kuthibitisha.
            </p>
            <div className="flex items-center gap-2 text-[13px] text-[#0C1B2E]/50">
              <Loader2 size={15} className="animate-spin" /> Tunasubiri uthibitisho…
            </div>
            <p className="text-[12px] text-[#0C1B2E]/40">Usifunge ukurasa huu.</p>
          </div>
        )}

        {/* ── Done ───────────────────────────────────────────────────── */}
        {step === "done" && (
          <div className="flex flex-col items-center text-center gap-4 py-4">
            <CheckCircle2 size={56} className="text-[#16A34A]" />
            <h1 className="font-heading font-bold text-[#0C1B2E] text-2xl">
              {tier === "starter" ? "Akaunti yako iko tayari!" : "Malipo yamekamilika!"}
            </h1>
            {tier !== "starter" ? (
              <p className="text-[14px] text-[#0C1B2E]/65 max-w-sm">
                Kifurushi cha <strong>{PLAN_COPY[tier].name}</strong> kimewashwa kwa{" "}
                <strong>{selectedBusiness?.name ?? "biashara yako"}</strong>
                {planExpiresAt && <> hadi <strong>{new Date(planExpiresAt).toLocaleDateString("sw-TZ", { day: "numeric", month: "long", year: "numeric" })}</strong></>}.
              </p>
            ) : (
              <p className="text-[14px] text-[#0C1B2E]/65 max-w-sm">
                {isNewAccount
                  ? "Umefungua akaunti ya Bure. Unaweza kupandisha kifurushi wakati wowote."
                  : "Uko kwenye kifurushi cha Bure. Unaweza kupandisha wakati wowote."}
              </p>
            )}
            <div className="w-full rounded-2xl bg-[#F8FAFC] border border-[#0C1B2E]/[0.08] p-4 text-left text-[13px] text-[#0C1B2E]/70">
              <strong className="text-[#0C1B2E]">Hatua inayofuata:</strong> fungua Mali Up, ingia kwa namba{" "}
              <strong>+{canonicalPhone(phone)}</strong> na PIN yako.
            </div>
            <a
              href={PLAY_STORE_URL}
              target="_blank"
              rel="noreferrer"
              className="w-full rounded-xl bg-[#0C1B2E] px-6 py-3.5 text-[15px] font-bold text-white hover:opacity-90"
            >
              Fungua / Pakua Mali Up
            </a>
            <a href="/" className="text-[13px] text-[#0C1B2E]/55 hover:text-[#0C1B2E]">Rudi mwanzo</a>
          </div>
        )}

        {/* ── Failed / timed out ─────────────────────────────────────── */}
        {step === "failed" && (
          <div className="flex flex-col items-center text-center gap-4 py-4">
            <XCircle size={56} className="text-red-500" />
            <h1 className="font-heading font-bold text-[#0C1B2E] text-2xl">Malipo hayakukamilika</h1>
            <p className="text-[14px] text-[#0C1B2E]/65 max-w-sm">
              Huenda ombi liliisha muda, PIN haikuwekwa, au salio halitoshi. Hakuna pesa iliyokatwa
              kama hukuthibitisha. Kama ulithibitisha na pesa imekatwa, kifurushi kitawaka ndani ya dakika chache —
              au tuandikie.
            </p>
            <PrimaryButton onClick={() => go("checkout")}>Jaribu tena</PrimaryButton>
            <a href={SUPPORT_URL} target="_blank" rel="noreferrer" className="text-[13px] text-[#0C1B2E]/55 hover:text-[#0C1B2E]">
              Wasiliana nasi
            </a>
          </div>
        )}
      </div>
    </div>
  )
}

function CurrentPlanNote({ business }: { business: OwnedBusiness }) {
  const paid = business.plan === "growth" || business.plan === "business"
  const active = paid && business.planExpiresAt && business.planExpiresAt > new Date()
  if (!active) return null
  return (
    <div className="rounded-xl bg-[#16A34A]/[0.08] border border-[#16A34A]/20 px-4 py-3 text-[13px] text-[#0C1B2E]/75">
      <strong className="text-[#0C1B2E]">{business.name}</strong> iko kwenye{" "}
      <strong>{business.plan === "growth" ? "Growth" : "Business"}</strong> hadi{" "}
      {business.planExpiresAt!.toLocaleDateString("sw-TZ", { day: "numeric", month: "long", year: "numeric" })}.
      Ukilipia kifurushi hicho hicho sasa, muda mpya unaongezwa juu ya uliobaki.
    </div>
  )
}
