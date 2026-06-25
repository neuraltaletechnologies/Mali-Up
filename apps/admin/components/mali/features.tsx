"use client"

import { useEffect, useRef, useState } from "react"
import {
  ShoppingCart, FileText, Package, TrendingUp,
  Users, BarChart3, Building2, Zap,
} from "lucide-react"

const modules = [
  { icon: ShoppingCart, color: "#F5A623", title: "Mauzo & POS",          desc: "Simamia mauzo papo hapo, dhibiti bidhaa, toa punguzo, na chapisha risiti — hata bila intaneti." },
  { icon: FileText,     color: "#22C55E", title: "Ankara za Haraka",     desc: "Tengeneza ankara za kitaalamu, fuatilia malipo, na tuma ukumbusho wa otometi kwa wateja wako." },
  { icon: Package,      color: "#3B82F6", title: "Udhibiti wa Bidhaa",   desc: "Hisa za wakati halisi, arifa za hisa ndogo, msaada wa maeneo mengi, na vichocheo vya kuagiza upya." },
  { icon: TrendingUp,   color: "#F5A623", title: "Fedha & Uhasibu",      desc: "Fuatilia mapato, matumizi, mtiririko wa pesa, na faida kwa chati za kuona zilizoundwa kwa biashara ndogo." },
  { icon: Users,        color: "#22C55E", title: "CRM ya Wateja",        desc: "Jenga maelezo ya wateja, fuatilia historia ya manunuzi, na dumisha uhusiano wa kudumu kila siku." },
  { icon: BarChart3,    color: "#3B82F6", title: "Takwimu za Biashara",  desc: "Dashibodi zinazoonyesha maarifa muhimu kuhusu mauzo, mapato, na mwelekeo wa ukuaji." },
  { icon: Building2,    color: "#F5A623", title: "Biashara Nyingi",      desc: "Jukwaa moja kwa biashara nyingi. Kila biashara inapata data yake, chapa yake, na ufikiaji wake mwenyewe." },
  { icon: Zap,          color: "#22C55E", title: "Inafanya kazi 3G",     desc: "Imeundwa kwa muunganisho wa Tanzania — nyepesi, pakia haraka, na inafanya kazi kwenye simu za bei nafuu." },
]

function FeatureCard({ mod, index }: { mod: typeof modules[0]; index: number }) {
  const [hovered, setHovered] = useState(false)
  const [mousePos, setMousePos] = useState({ x: 0.5, y: 0.5 })
  const cardRef = useRef<HTMLDivElement>(null)
  const Icon = mod.icon

  function onMouseMove(e: React.MouseEvent<HTMLDivElement>) {
    const rect = cardRef.current!.getBoundingClientRect()
    setMousePos({
      x: (e.clientX - rect.left) / rect.width,
      y: (e.clientY - rect.top) / rect.height,
    })
  }

  return (
    <div
      ref={cardRef}
      className="reveal group relative glass rounded-2xl p-6 flex flex-col gap-4 cursor-default overflow-hidden"
      style={{
        transitionDelay: `${(index % 4) * 0.08}s`,
        transitionProperty: "opacity, transform",
        transform: hovered
          ? `perspective(600px) rotateX(${(mousePos.y - 0.5) * -8}deg) rotateY(${(mousePos.x - 0.5) * 8}deg) translateY(-4px)`
          : "perspective(600px) rotateX(0) rotateY(0) translateY(0)",
        transition: hovered ? "transform 0.15s ease" : "transform 0.4s ease, opacity 0.75s ease",
        boxShadow: hovered ? `0 20px 50px -12px ${mod.color}30` : "none",
      }}
      onMouseEnter={() => setHovered(true)}
      onMouseLeave={() => { setHovered(false); setMousePos({ x: 0.5, y: 0.5 }) }}
      onMouseMove={onMouseMove}
    >
      {/* Spotlight follow */}
      {hovered && (
        <div
          className="absolute inset-0 pointer-events-none rounded-2xl"
          style={{
            background: `radial-gradient(circle 100px at ${mousePos.x * 100}% ${mousePos.y * 100}%, ${mod.color}14 0%, transparent 70%)`,
          }}
          aria-hidden="true"
        />
      )}

      <div
        className="w-11 h-11 rounded-xl flex items-center justify-center shrink-0 transition-transform duration-300 group-hover:scale-110"
        style={{ backgroundColor: `${mod.color}15` }}
      >
        <Icon size={20} style={{ color: mod.color }} />
      </div>

      <div className="flex flex-col gap-1.5">
        <h3 className="font-heading font-bold text-[#0C1B2E] text-base">{mod.title}</h3>
        <p className="text-[#0C1B2E]/65 text-sm leading-relaxed">{mod.desc}</p>
      </div>

      {/* Animated bottom accent */}
      <div
        className="h-0.5 rounded-full mt-auto transition-all duration-500"
        style={{
          width: hovered ? "100%" : "0%",
          backgroundColor: mod.color,
        }}
        aria-hidden="true"
      />
    </div>
  )
}

export function Features() {
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
      id="features"
      ref={sectionRef}
      className="py-24 relative overflow-hidden"
      style={{ backgroundColor: "#F8FAFC" }}
      aria-labelledby="features-heading"
    >
      <div className="absolute top-0 left-1/2 -translate-x-1/2 w-1/2 h-px" style={{ background: "linear-gradient(90deg,transparent,#F5A623,transparent)" }} aria-hidden="true" />

      <div className="max-w-6xl mx-auto px-6">
        <div className="text-center mb-16 flex flex-col gap-4">
          <div className="reveal inline-flex justify-center">
            <span className="glass-amber text-[#F5A623] text-xs font-bold px-4 py-1.5 rounded-full tracking-wider uppercase">Kila Unachohitaji</span>
          </div>
          <h2 id="features-heading" className="reveal font-heading font-bold text-[#0C1B2E] text-balance" style={{ fontSize: "clamp(1.9rem,4vw,3rem)" }}>
            Programu Moja. Moduli Nane Zenye Nguvu.
          </h2>
          <p className="reveal text-[#0C1B2E]/65 max-w-xl mx-auto leading-relaxed">
            Kutoka dukani hadi biashara inayokua — Mali Up inakua na biashara yako, ikiunganisha kila operesheni mahali pamoja.
          </p>
        </div>

        <div className="grid sm:grid-cols-2 lg:grid-cols-4 gap-4">
          {modules.map((mod, i) => <FeatureCard key={mod.title} mod={mod} index={i} />)}
        </div>
      </div>
    </section>
  )
}
