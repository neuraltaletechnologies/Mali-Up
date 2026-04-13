"use client"

import { useEffect, useRef } from "react"
import { Wallet, Landmark, TrendingUp, Users } from "lucide-react"

/* 
  These are not job titles — they are financial life situations.
  Anyone can be in any of these, regardless of employment type.
*/
const personas = [
  {
    icon: Wallet,
    color: "#22C55E",
    title: "You have money coming in",
    desc: "A salary, freelance work, a side hustle, sponsorship, part-time jobs, or seasonal income. No matter the source or stability — Mali Up tracks every shilling in and out.",
    tags: ["Any income source", "Expense tracking", "Savings goals", "Bill reminders"],
  },
  {
    icon: Landmark,
    color: "#F5A623",
    title: "You own something valuable",
    desc: "A plot of land, a house, a car, shares, livestock, or equipment. Most people have no idea what their assets are worth. Mali Up gives you that clarity.",
    tags: ["Land & property", "Vehicles", "Stocks & shares", "Net worth"],
  },
  {
    icon: TrendingUp,
    color: "#0EA5E9",
    title: "You run a business",
    desc: "A shop, a salon, an agency, a farm — big or small. Mali Up adds business tools on top of your personal financial life, so both stay in one place.",
    tags: ["Sales & invoicing", "Inventory", "Customer records", "Analytics"],
  },
  {
    icon: Users,
    color: "#F5A623",
    title: "You manage for a family",
    desc: "Household expenses, shared savings, family debts, school fees. Financial management isn't just for individuals — Mali Up works for the whole household.",
    tags: ["Shared budgets", "Family savings", "Debts & lending", "Bills"],
  },
]

function PersonaCard({ persona, index }: { persona: typeof personas[0]; index: number }) {
  const Icon = persona.icon

  return (
    <div
      className="reveal group relative glass rounded-3xl p-7 flex flex-col gap-5 transition-all duration-300 hover:-translate-y-1.5"
      style={{
        transitionDelay: `${index * 0.1}s`,
        boxShadow: "0 4px 20px rgba(12,27,46,0.04)",
      }}
      onMouseEnter={(e) => {
        e.currentTarget.style.boxShadow = `0 16px 48px -8px ${persona.color}25`
      }}
      onMouseLeave={(e) => {
        e.currentTarget.style.boxShadow = "0 4px 20px rgba(12,27,46,0.04)"
      }}
    >
      {/* Icon */}
      <div
        className="w-14 h-14 rounded-2xl flex items-center justify-center transition-transform duration-300 group-hover:scale-110"
        style={{ backgroundColor: `${persona.color}15`, border: `1px solid ${persona.color}25` }}
      >
        <Icon size={24} style={{ color: persona.color }} />
      </div>

      {/* Text */}
      <div className="flex flex-col gap-2">
        <h3 className="font-heading font-bold text-[#0C1B2E] text-lg">{persona.title}</h3>
        <p className="text-[#0C1B2E]/60 text-sm leading-relaxed">{persona.desc}</p>
      </div>

      {/* Tags */}
      <div className="flex flex-wrap gap-2 mt-auto">
        {persona.tags.map((tag) => (
          <span
            key={tag}
            className="text-[10px] font-bold px-2.5 py-1 rounded-full uppercase tracking-wide"
            style={{
              backgroundColor: `${persona.color}10`,
              color: persona.color,
              border: `1px solid ${persona.color}20`,
            }}
          >
            {tag}
          </span>
        ))}
      </div>

      {/* Bottom accent line */}
      <div
        className="absolute bottom-0 left-6 right-6 h-0.5 rounded-full opacity-0 group-hover:opacity-100 transition-opacity duration-400"
        style={{ backgroundColor: persona.color }}
        aria-hidden="true"
      />
    </div>
  )
}

export function Audience() {
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
      id="who-its-for"
      ref={sectionRef}
      className="py-24 relative overflow-hidden"
      style={{ backgroundColor: "#FFFFFF" }}
      aria-labelledby="audience-heading"
    >
      {/* Decorative top line */}
      <div
        className="absolute top-0 left-1/2 -translate-x-1/2 w-1/2 h-px"
        style={{ background: "linear-gradient(90deg,transparent,#22C55E,transparent)" }}
        aria-hidden="true"
      />

      {/* Soft center glow */}
      <div
        className="absolute left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2 w-[700px] h-[400px] rounded-full blur-3xl opacity-[0.05] pointer-events-none"
        style={{ background: "radial-gradient(ellipse, #22C55E 0%, transparent 70%)" }}
        aria-hidden="true"
      />

      <div className="max-w-6xl mx-auto px-6 relative z-10">
        {/* Header */}
        <div className="text-center mb-14 flex flex-col gap-4">
          <div className="reveal inline-flex justify-center">
            <span
              className="text-xs font-bold px-4 py-1.5 rounded-full tracking-wider uppercase"
              style={{ backgroundColor: "rgba(245,166,35,0.1)", color: "#F5A623", border: "1px solid rgba(245,166,35,0.25)" }}
            >
              Mali Up is for You
            </span>
          </div>
          <h2
            id="audience-heading"
            className="reveal font-heading font-bold text-[#0C1B2E] text-balance"
            style={{ fontSize: "clamp(1.9rem, 4vw, 3rem)" }}
          >
            It&apos;s not about what you do.{" "}
            <span
              className="shimmer-btn bg-clip-text"
              style={{ WebkitBackgroundClip: "text", WebkitTextFillColor: "transparent", backgroundClip: "text" }}
            >
              It&apos;s about your financial life.
            </span>
          </h2>
          <p className="reveal text-[#0C1B2E]/60 max-w-xl mx-auto leading-relaxed">
            You don&apos;t need to be a business owner to need financial management. If you have income of any kind, own anything of value, or want to build wealth — this app is for you.
          </p>
        </div>

        {/* Cards */}
        <div className="grid sm:grid-cols-2 lg:grid-cols-4 gap-5">
          {personas.map((p, i) => (
            <PersonaCard key={p.title} persona={p} index={i} />
          ))}
        </div>

        {/* Dual-mode callout */}
        <div
          className="reveal mt-14 rounded-3xl p-8 flex flex-col md:flex-row items-center justify-between gap-6"
          style={{ background: "linear-gradient(135deg, rgba(12,27,46,0.03) 0%, rgba(245,166,35,0.05) 100%)", border: "1px solid rgba(12,27,46,0.07)" }}
        >
          <div className="flex flex-col gap-2 text-center md:text-left">
            <p className="font-heading font-bold text-[#0C1B2E] text-xl">One app. No financial life is too simple — or too complex.</p>
            <p className="text-[#0C1B2E]/55 text-sm">
              Log your salary. Register your land. Track your shop sales. Mali Up scales with wherever you are in life.
            </p>
          </div>
          <a
            href="#waitlist"
            className="shrink-0 shimmer-btn text-[#0C1B2E] font-bold px-7 py-3.5 rounded-2xl text-sm shadow-xl transition-all duration-200 hover:scale-105 hover:shadow-[0_8px_32px_rgba(245,166,35,0.4)] active:scale-[0.97] whitespace-nowrap"
          >
            Join the Waitlist
          </a>
        </div>
      </div>
    </section>
  )
}
