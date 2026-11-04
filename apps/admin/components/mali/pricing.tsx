"use client"

import { useState, useRef, useEffect } from "react"
import { Check, ArrowRight, Smartphone } from "lucide-react"
import {
  DEFAULT_PUBLIC_PRICES,
  PLAN_COPY,
  formatTZS,
  priceFor,
  yearlySaving,
  type BillingCycle,
  type PublicPlanPrices,
  type PublicTier,
} from "@/lib/public-plans"

interface PlanStyle {
  tier: PublicTier
  badge?: string
  popular?: boolean
  ctaText: string
}

// Copy and prices live in lib/public-plans.ts (prices are fetched live from
// /api/plans — the same platform_config/plans doc ClickPesa charges from).
const plans: PlanStyle[] = [
  { tier: "starter",  badge: "Bure Kabisa", ctaText: "Anza Bure" },
  { tier: "growth",   badge: "Inayopendwa Zaidi", popular: true, ctaText: "Lipia Growth" },
  { tier: "business", ctaText: "Lipia Business" },
]

export function Pricing() {
  const [cycle, setCycle] = useState<BillingCycle>("yearly")
  const [prices, setPrices] = useState<PublicPlanPrices>(DEFAULT_PUBLIC_PRICES)
  const sectionRef = useRef<HTMLDivElement>(null)
  const isAnnual = cycle === "yearly"

  useEffect(() => {
    fetch("/api/plans")
      .then((r) => r.json())
      .then((d: { prices?: PublicPlanPrices }) => d.prices && setPrices(d.prices))
      .catch(() => { /* defaults stay */ })
  }, [])

  useEffect(() => {
    const observer = new IntersectionObserver(
      (entries) => entries.forEach((e) => e.isIntersecting && e.target.classList.add("visible")),
      { threshold: 0.1 }
    )
    sectionRef.current?.querySelectorAll(".reveal").forEach((el) => observer.observe(el))
    return () => observer.disconnect()
  }, [])

  // Whole months saved by paying yearly on Growth (the default pick) — with
  // the default 6,000/mo vs 60,000/yr that's "2 months free".
  const monthsFree = prices.growth.priceMonthly > 0
    ? Math.floor(yearlySaving(prices, "growth") / prices.growth.priceMonthly)
    : 0
  // Yearly discount vs. paying monthly for 12 months — "Okoa 17%" on the toggle.
  const discountPct = prices.growth.priceMonthly > 0
    ? Math.round((yearlySaving(prices, "growth") / (prices.growth.priceMonthly * 12)) * 100)
    : 0

  return (
    <section
      id="pricing"
      ref={sectionRef}
      className="py-24 relative overflow-hidden"
      style={{ backgroundColor: "#FFFFFF" }}
      aria-labelledby="pricing-heading"
      itemScope
      itemType="https://schema.org/OfferCatalog"
    >
      <meta itemProp="name" content="Mali Up Subscription Plans & Pricing Catalog" />

      {/* Decorative background glows */}
      <div
        className="absolute top-1/3 left-1/2 -translate-x-1/2 w-[600px] h-[300px] pointer-events-none rounded-full blur-3xl opacity-30"
        style={{ background: "radial-gradient(circle, rgba(245,166,35,0.15) 0%, transparent 70%)" }}
        aria-hidden="true"
      />

      <div className="max-w-5xl mx-auto px-6 relative z-10">
        {/* Header */}
        <div className="text-center mb-16 flex flex-col gap-4">
          <div className="reveal inline-flex justify-center">
            <span className="glass-amber text-[#F5A623] text-xs font-bold px-4 py-1.5 rounded-full tracking-wider uppercase">
              Vifurushi & Bei / Plans & Pricing
            </span>
          </div>

          <h2
            id="pricing-heading"
            className="reveal font-heading font-bold text-[#0C1B2E] text-balance"
            style={{ fontSize: "clamp(1.9rem,4vw,3rem)" }}
          >
            Chagua Kifurushi Kinachofaa Biashara Yako
          </h2>

          <p className="reveal text-[#0C1B2E]/65 max-w-2xl mx-auto leading-relaxed text-base">
            Bei wazi, bila ada zilizofichika. Lipa hapa hapa kwa M-Pesa, Tigo Pesa, Airtel Money au HaloPesa —
            huhitaji kupakua programu kwanza.
          </p>

          {/* Billing Cycle Toggle — one switch, both words inside the track */}
          <div className="reveal flex justify-center mt-4">
            <button
              type="button"
              role="switch"
              aria-checked={isAnnual}
              aria-label="Badilisha malipo: mwezi au mwaka"
              onClick={() => setCycle(isAnnual ? "monthly" : "yearly")}
              className="relative grid grid-cols-2 w-52 h-12 rounded-full bg-[#0C1B2E] p-1 shadow-lg focus:outline-none focus-visible:ring-2 focus-visible:ring-[#F5A623]"
            >
              {/* Sliding knob */}
              <span
                aria-hidden="true"
                className="absolute top-1 bottom-1 left-1 w-[calc(50%-4px)] rounded-full bg-[#F5A623] shadow-md transition-transform duration-300 ease-out"
                style={{ transform: isAnnual ? "translateX(100%)" : "translateX(0)" }}
              />
              <span
                className={`relative z-10 flex items-center justify-center text-sm font-bold transition-colors duration-300 ${
                  !isAnnual ? "text-[#0C1B2E]" : "text-white/60"
                }`}
              >
                Mwezi
              </span>
              <span
                className={`relative z-10 flex items-center justify-center text-sm font-bold transition-colors duration-300 ${
                  isAnnual ? "text-[#0C1B2E]" : "text-white/60"
                }`}
              >
                Mwaka
              </span>
            </button>
          </div>
          {monthsFree > 0 && (
            <p className="reveal text-xs font-semibold text-[#16A34A] -mt-1">
              Lipa kwa mwaka upate {monthsFree === 1 ? "mwezi 1" : `miezi ${monthsFree}`} bure
              {discountPct > 0 && <> (okoa {discountPct}%)</>}
            </p>
          )}
        </div>

        {/* Pricing Cards Grid */}
        <div className="grid md:grid-cols-3 gap-6 items-stretch">
          {plans.map((plan, i) => {
            const copy = PLAN_COPY[plan.tier]
            const price = plan.tier === "starter" ? 0 : priceFor(prices, plan.tier, cycle)
            const saving = yearlySaving(prices, plan.tier)
            // Headline is always a per-month figure (yearly ÷ 12 when billed
            // yearly), with what's actually charged on the line beneath it.
            const perMonth = isAnnual ? Math.round(price / 12) : price
            const href = `/pay?plan=${plan.tier}&cycle=${cycle}`

            return (
              <div
                key={plan.tier}
                itemProp="itemListElement"
                itemScope
                itemType="https://schema.org/Offer"
                className={`reveal relative rounded-3xl p-7 flex flex-col justify-between transition-all duration-300 ${
                  plan.popular
                    ? "bg-[#0C1B2E] text-white shadow-2xl shadow-[#0C1B2E]/25 ring-2 ring-[#F5A623] md:scale-[1.03]"
                    : "bg-white text-[#0C1B2E] border border-[#0C1B2E]/10 shadow-sm hover:shadow-xl hover:border-[#0C1B2E]/20"
                }`}
                style={{ transitionDelay: `${i * 0.08}s` }}
              >
                {plan.badge && (
                  <div className="absolute -top-3.5 left-1/2 -translate-x-1/2">
                    <span
                      className={`text-xs font-bold px-3 py-1 rounded-full uppercase tracking-wider shadow-md whitespace-nowrap ${
                        plan.popular ? "bg-[#F5A623] text-[#0C1B2E]" : "bg-[#0C1B2E] text-white"
                      }`}
                    >
                      {plan.badge}
                    </span>
                  </div>
                )}

                <div>
                  <h3 itemProp="name" className="font-heading font-bold text-xl mb-2">
                    {copy.name}
                  </h3>

                  <p
                    itemProp="description"
                    className={`text-sm leading-relaxed mb-6 ${plan.popular ? "text-white/70" : "text-[#0C1B2E]/60"}`}
                  >
                    {copy.tagline}
                  </p>

                  {/* Price — per-month headline, billed total underneath */}
                  <div className="mb-6 pb-6 border-b border-current/10">
                    <meta itemProp="price" content={price.toString()} />
                    <meta itemProp="priceCurrency" content="TZS" />
                    <meta itemProp="availability" content="https://schema.org/InStock" />
                    <div className="flex items-baseline gap-1.5">
                      <span className="font-heading font-black text-4xl tracking-tight">
                        {price === 0 ? "Bure" : formatTZS(perMonth)}
                      </span>
                      {price > 0 && (
                        <span className={`text-sm ${plan.popular ? "text-white/60" : "text-[#0C1B2E]/50"}`}>
                          / mwezi
                        </span>
                      )}
                    </div>
                    <div className={`text-xs mt-2 min-h-[34px] leading-relaxed ${plan.popular ? "text-white/60" : "text-[#0C1B2E]/55"}`}>
                      {price === 0 ? (
                        "Milele — hakuna malipo"
                      ) : isAnnual ? (
                        <>
                          {formatTZS(price)} kwa mwaka, unalipa mara moja
                          {saving > 0 && (
                            <span className="block font-semibold text-[#22C55E]">Unaokoa {formatTZS(saving)}</span>
                          )}
                        </>
                      ) : (
                        <>
                          Inalipwa kila mwezi
                          <span className="block">{formatTZS(price * 12)} kwa mwaka</span>
                        </>
                      )}
                    </div>
                  </div>

                  {/* Features */}
                  <ul className="space-y-2.5 mb-8">
                    {copy.features.map((feat) => (
                      <li key={feat} className="flex items-start gap-2.5 text-sm leading-snug">
                        <Check
                          size={16}
                          className={`shrink-0 mt-0.5 ${plan.popular ? "text-[#F5A623]" : "text-[#22C55E]"}`}
                        />
                        <span className={plan.popular ? "text-white/90" : "text-[#0C1B2E]/80"}>{feat}</span>
                      </li>
                    ))}
                  </ul>
                </div>

                <a
                  href={href}
                  className={`w-full py-3.5 px-4 rounded-xl font-bold text-sm flex items-center justify-center gap-2 transition-all duration-200 active:scale-[0.98] ${
                    plan.popular
                      ? "shimmer-btn text-[#0C1B2E] shadow-lg hover:scale-[1.02]"
                      : "bg-[#0C1B2E] text-white hover:bg-[#142038]"
                  }`}
                >
                  <span>{plan.ctaText}</span>
                  <ArrowRight size={15} />
                </a>
              </div>
            )
          })}
        </div>

        {/* How paying works — written for first-time visitors */}
        <div className="reveal mt-12 grid sm:grid-cols-3 gap-4 text-center sm:text-left">
          {[
            { n: "1", t: "Weka namba yako", d: "Una akaunti? Weka PIN. Mpya? Tutakutumia msimbo kwa SMS." },
            { n: "2", t: "Chagua mwezi au mwaka", d: monthsFree > 0 ? `Lipa kila mwezi, au kwa mwaka upate ${monthsFree === 1 ? "mwezi 1" : `miezi ${monthsFree}`} bure.` : "Lipa kila mwezi au kwa mwaka mzima." },
            { n: "3", t: "Thibitisha kwenye simu", d: "Weka PIN ya M-Pesa/Tigo/Airtel. Kifurushi kinawaka papo hapo." },
          ].map((s) => (
            <div key={s.n} className="rounded-2xl p-5 bg-[#F8FAFC] border border-[#0C1B2E]/[0.08] flex sm:flex-col items-start gap-3">
              <span className="w-8 h-8 rounded-full bg-[#F5A623] text-[#0C1B2E] font-black text-sm flex items-center justify-center shrink-0">
                {s.n}
              </span>
              <div>
                <h4 className="font-bold text-[#0C1B2E] text-sm">{s.t}</h4>
                <p className="text-[#0C1B2E]/60 text-xs mt-1 leading-relaxed">{s.d}</p>
              </div>
            </div>
          ))}
        </div>

        {/* Enterprise / help bar */}
        <div className="reveal mt-6 rounded-2xl p-6 bg-[#F8FAFC] border border-[#0C1B2E]/[0.08] flex flex-col md:flex-row items-center justify-between gap-4 text-center md:text-left">
          <div className="flex items-start gap-3">
            <Smartphone size={20} className="text-[#0C1B2E]/40 shrink-0 mt-0.5 hidden md:block" />
            <div>
              <h4 className="font-bold text-[#0C1B2E] text-sm">
                Kampuni kubwa au unahitaji ushauri?
              </h4>
              <p className="text-[#0C1B2E]/60 text-xs mt-0.5">
                Kwa matawi na watumiaji bila kikomo (Enterprise), au msaada wa kuchagua kifurushi — timu yetu ipo tayari.
              </p>
            </div>
          </div>
          <a
            href="https://neuraltale.com/#contact"
            target="_blank"
            rel="noreferrer"
            className="shrink-0 px-5 py-2.5 rounded-xl border border-[#0C1B2E]/15 text-[#0C1B2E] font-semibold text-xs hover:bg-[#0C1B2E]/5 transition-colors"
          >
            Wasiliana Nasi
          </a>
        </div>
      </div>
    </section>
  )
}
