"use client"

import { useState, useRef, useEffect } from "react"
import { Check, Zap, Sparkles, Building2, Crown, ArrowRight } from "lucide-react"

const PLAY_STORE_URL = "https://play.google.com/store/apps/details?id=com.neuraltale.maliup"

interface Plan {
  id: string
  name: string
  swName: string
  tagline: string
  priceMonthly: number
  priceAnnualMonthly: number
  badge?: string
  popular?: boolean
  icon: typeof Zap
  color: string
  target: string
  features: string[]
  ctaText: string
  ctaHref: string
}

const plans: Plan[] = [
  {
    id: "starter",
    name: "Starter",
    swName: "Bure (Starter)",
    tagline: "Kwa wajasiriamali na maduka madogo yanayoanza.",
    priceMonthly: 0,
    priceAnnualMonthly: 0,
    badge: "Bure Kabisa",
    icon: Sparkles,
    color: "#94A3B8",
    target: "Maduka madogo, wajasiriamali binafsi",
    features: [
      "Mauzo ya haraka na risiti za kidigitali",
      "Hadi bidhaa 50 kwenye stoo",
      "Usimamizi wa wateja na madeni ya msingi",
      "Kumbukumbu za mapato na matumizi",
      "Inafanya kazi bila intaneti (Offline)",
      "Mtumiaji 1 na biashara 1",
    ],
    ctaText: "Anza Bure Sasa",
    ctaHref: PLAY_STORE_URL,
  },
  {
    id: "growth",
    name: "Growth",
    swName: "Growth Plan",
    tagline: "Kwa biashara zinazokua zenye miamala mingi ya kila siku.",
    priceMonthly: 49000,
    priceAnnualMonthly: 39000,
    popular: true,
    badge: "Inayopendwa Zaidi",
    icon: Zap,
    color: "#F5A623",
    target: "Maduka ya jumla, mikahawa, maduka ya dawa",
    features: [
      "Kila kitu kilichopo kwenye Starter",
      "Bidhaa na mauzo bila kikomo",
      "Ankara za kitaalamu zenye jina na nembo yako",
      "Upatanisho wa malipo ya M-Pesa & benki",
      "Tahadhari za bidhaa kuisha (Low stock alerts)",
      "Hadi watumiaji 3 (Wafanyakazi & Cashier)",
      "Ripoti kamili za faida na hasara (P&L)",
    ],
    ctaText: "Pakua & Jaribu Leo",
    ctaHref: PLAY_STORE_URL,
  },
  {
    id: "business",
    name: "Business",
    swName: "Business Pro",
    tagline: "Kwa biashara zenye matawi mengi na wafanyakazi kadhaa.",
    priceMonthly: 120000,
    priceAnnualMonthly: 99000,
    icon: Crown,
    color: "#22C55E",
    target: "Supermarkets, minyororo ya maduka, viwanda vidogo",
    features: [
      "Kila kitu kilichopo kwenye Growth",
      "Usimamizi wa stoo kwenye matawi mengi (Multi-location)",
      "Uhamisho wa bidhaa kati ya stoo na maduka",
      "Hadi watumiaji 10 wenye majukumu maalum (RBAC)",
      "SMS za ukumbusho wa madeni kwa wateja",
      "Uchanganuzi wa kina wa biashara na mienendo",
      "Msaada wa kipaumbele masaa 24/7",
    ],
    ctaText: "Pata Mali Up Business",
    ctaHref: PLAY_STORE_URL,
  },
  {
    id: "enterprise",
    name: "Enterprise",
    swName: "Enterprise Custom",
    tagline: "Suluhisho maalum kwa kampuni kubwa na mashirika.",
    priceMonthly: 350000,
    priceAnnualMonthly: 290000,
    icon: Building2,
    color: "#3B82F6",
    target: "Kampuni kubwa, taasisi, wauzaji wa jumla wa kikanda",
    features: [
      "Kila kitu kilichopo kwenye Business",
      "Matawi na watumiaji bila kikomo",
      "Muunganisho maalum wa API na mifumo mingine",
      "Uingizaji wa data za awali na mafunzo kwa wafanyakazi",
      "Meneja wa akaunti aliyejitolea (Dedicated manager)",
      "Mkataba wa huduma na usalama wa daraja la juu (SLA)",
    ],
    ctaText: "Wasiliana Nasi",
    ctaHref: "https://neuraltale.com/#contact",
  },
]

function formatTZS(amount: number) {
  if (amount === 0) return "TSh 0"
  return `TSh ${amount.toLocaleString("en-US")}`
}

export function Pricing() {
  const [isAnnual, setIsAnnual] = useState(false)
  const sectionRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    const observer = new IntersectionObserver(
      (entries) => entries.forEach((e) => e.isIntersecting && e.target.classList.add("visible")),
      { threshold: 0.1 }
    )
    sectionRef.current?.querySelectorAll(".reveal").forEach((el) => observer.observe(el))
    return () => observer.disconnect()
  }, [])

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

      <div className="max-w-6xl mx-auto px-6 relative z-10">
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
            Gharama nafuu na wazi bila ada zilizofichika. Anza bure leo au boresha kupata uwezo kamili wa ERP ya kisasa ya Tanzania.
          </p>

          {/* Billing Cycle Toggle */}
          <div className="reveal inline-flex items-center justify-center gap-3 mt-4">
            <span
              className={`text-sm font-semibold cursor-pointer transition-colors ${
                !isAnnual ? "text-[#0C1B2E]" : "text-[#0C1B2E]/50"
              }`}
              onClick={() => setIsAnnual(false)}
            >
              Mwezi kwa Mwezi (Monthly)
            </span>

            <button
              type="button"
              role="switch"
              aria-checked={isAnnual}
              aria-label="Badilisha malipo ya kila mwezi au mwaka"
              onClick={() => setIsAnnual(!isAnnual)}
              className="w-14 h-8 rounded-full p-1 transition-colors duration-300 relative focus:outline-none"
              style={{ backgroundColor: isAnnual ? "#F5A623" : "#0C1B2E" }}
            >
              <div
                className="w-6 h-6 rounded-full bg-white shadow-md transition-transform duration-300"
                style={{
                  transform: isAnnual ? "translateX(24px)" : "translateX(0px)",
                }}
              />
            </button>

            <span
              className={`text-sm font-semibold cursor-pointer transition-colors flex items-center gap-1.5 ${
                isAnnual ? "text-[#0C1B2E]" : "text-[#0C1B2E]/50"
              }`}
              onClick={() => setIsAnnual(true)}
            >
              Kila Mwaka (Annual)
              <span className="text-[11px] font-bold text-[#22C55E] bg-[#22C55E]/10 px-2 py-0.5 rounded-full">
                Punguzo la 20%
              </span>
            </span>
          </div>
        </div>

        {/* Pricing Cards Grid */}
        <div className="grid md:grid-cols-2 lg:grid-cols-4 gap-6 items-stretch">
          {plans.map((plan, i) => {
            const Icon = plan.icon
            const price = isAnnual ? plan.priceAnnualMonthly : plan.priceMonthly

            return (
              <div
                key={plan.id}
                itemProp="itemListElement"
                itemScope
                itemType="https://schema.org/Offer"
                className={`reveal relative rounded-3xl p-7 flex flex-col justify-between transition-all duration-300 ${
                  plan.popular
                    ? "bg-[#0C1B2E] text-white shadow-2xl shadow-[#0C1B2E]/25 ring-2 ring-[#F5A623] scale-[1.02]"
                    : "bg-white text-[#0C1B2E] border border-[#0C1B2E]/10 shadow-sm hover:shadow-xl hover:border-[#0C1B2E]/20"
                }`}
                style={{ transitionDelay: `${i * 0.08}s` }}
              >
                {/* Popular Badge */}
                {plan.badge && (
                  <div className="absolute -top-3.5 left-1/2 -translate-x-1/2">
                    <span
                      className={`text-xs font-bold px-3 py-1 rounded-full uppercase tracking-wider shadow-md ${
                        plan.popular
                          ? "bg-[#F5A623] text-[#0C1B2E]"
                          : "bg-[#0C1B2E] text-white"
                      }`}
                    >
                      {plan.badge}
                    </span>
                  </div>
                )}

                <div>
                  {/* Top Icon & Title */}
                  <div className="flex items-center justify-between mb-4">
                    <div
                      className="w-11 h-11 rounded-2xl flex items-center justify-center shrink-0"
                      style={{
                        backgroundColor: plan.popular ? "rgba(245,166,35,0.2)" : `${plan.color}15`,
                      }}
                    >
                      <Icon size={22} style={{ color: plan.popular ? "#F5A623" : plan.color }} />
                    </div>
                    <span
                      className="text-xs font-bold tracking-wider uppercase opacity-60"
                      itemProp="category"
                    >
                      {plan.target.split(",")[0]}
                    </span>
                  </div>

                  <h3
                    itemProp="name"
                    className="font-heading font-bold text-xl mb-1"
                  >
                    {plan.name}
                  </h3>

                  <p
                    itemProp="description"
                    className={`text-xs leading-relaxed mb-6 min-h-[36px] ${
                      plan.popular ? "text-white/70" : "text-[#0C1B2E]/60"
                    }`}
                  >
                    {plan.tagline}
                  </p>

                  {/* Pricing Display */}
                  <div className="mb-6 pb-6 border-b border-current/10">
                    <div className="flex items-baseline gap-1">
                      <span
                        className="font-heading font-black text-3xl tracking-tight"
                        itemProp="price"
                        content={price.toString()}
                      >
                        {formatTZS(price)}
                      </span>
                      <meta itemProp="priceCurrency" content="TZS" />
                      <meta itemProp="availability" content="https://schema.org/InStock" />
                      {price > 0 && (
                        <span className={`text-xs ${plan.popular ? "text-white/60" : "text-[#0C1B2E]/50"}`}>
                          /mwezi
                        </span>
                      )}
                    </div>
                    {isAnnual && price > 0 && (
                      <div className="text-[11px] text-[#22C55E] font-medium mt-1">
                        Inalipwa kwa mwaka (TSh {(price * 12).toLocaleString("en-US")}/mwaka)
                      </div>
                    )}
                  </div>

                  {/* Feature List */}
                  <div className="space-y-3 mb-8">
                    <p className={`text-xs font-bold uppercase tracking-wider ${
                      plan.popular ? "text-white/80" : "text-[#0C1B2E]/70"
                    }`}>
                      Vipengele Vilivyojumuishwa:
                    </p>
                    <ul className="space-y-2.5">
                      {plan.features.map((feat, idx) => (
                        <li key={idx} className="flex items-start gap-2.5 text-xs leading-snug">
                          <Check
                            size={15}
                            className={`shrink-0 mt-0.5 ${
                              plan.popular ? "text-[#F5A623]" : "text-[#22C55E]"
                            }`}
                          />
                          <span className={plan.popular ? "text-white/90" : "text-[#0C1B2E]/80"}>
                            {feat}
                          </span>
                        </li>
                      ))}
                    </ul>
                  </div>
                </div>

                {/* Action CTA Button */}
                <div>
                  <a
                    href={plan.ctaHref}
                    target={plan.ctaHref.startsWith("http") ? "_blank" : undefined}
                    rel="noreferrer"
                    className={`w-full py-3 px-4 rounded-xl font-bold text-xs flex items-center justify-center gap-2 transition-all duration-200 active:scale-[0.98] ${
                      plan.popular
                        ? "shimmer-btn text-[#0C1B2E] shadow-lg hover:scale-[1.02]"
                        : "bg-[#0C1B2E] text-white hover:bg-[#142038]"
                    }`}
                  >
                    <span>{plan.ctaText}</span>
                    <ArrowRight size={14} />
                  </a>
                </div>
              </div>
            )
          })}
        </div>

        {/* Bottom guarantee / help bar */}
        <div className="reveal mt-12 rounded-2xl p-6 bg-[#F8FAFC] border border-[#0C1B2E]/08 flex flex-col md:flex-row items-center justify-between gap-4 text-center md:text-left">
          <div>
            <h4 className="font-bold text-[#0C1B2E] text-sm">
              Je, unahitaji ushauri wa kuchagua kifurushi sahihi cha biashara yako?
            </h4>
            <p className="text-[#0C1B2E]/60 text-xs mt-0.5">
              Timu yetu ya Dar es Salaam ipo tayari kukusaidia kuweka mfumo kwenye duka au ofisi yako.
            </p>
          </div>
          <a
            href="https://neuraltale.com/#contact"
            target="_blank"
            rel="noreferrer"
            className="shrink-0 px-5 py-2.5 rounded-xl border border-[#0C1B2E]/15 text-[#0C1B2E] font-semibold text-xs hover:bg-[#0C1B2E]/05 transition-colors"
          >
            Wasiliana na Timu ya Mauzo
          </a>
        </div>
      </div>
    </section>
  )
}
