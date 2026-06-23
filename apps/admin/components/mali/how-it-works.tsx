"use client"

import { useEffect, useRef, useState } from "react"
import { Download, Store, TrendingUp } from "lucide-react"
import { IPhoneMockup } from "@/components/mali/iphone-mockup"

const steps = [
  {
    number: "01",
    icon: Download,
    color: "#F5A623",
    img: "/app-dashboard.jpg",
    title: "Download & Sign Up",
    desc: "Install Mali Up on Android or iOS. Create your tenant account in under 2 minutes — no paperwork, no delays.",
  },
  {
    number: "02",
    icon: Store,
    color: "#22C55E",
    img: "/app-inventory.jpg",
    title: "Set Up Your Business",
    desc: "Add your products, pricing, staff, and customers. Import existing data or start fresh — Mali Up adapts to you.",
  },
  {
    number: "03",
    icon: TrendingUp,
    color: "#3B82F6",
    img: "/app-analytics.jpg",
    title: "Grow with Data",
    desc: "Sell, invoice, and track in real time. Let the analytics surface insights that help you make smarter decisions every day.",
  },
]

function StepCard({ step, index }: { step: typeof steps[0]; index: number }) {
  const [hovered, setHovered] = useState(false)
  const Icon = step.icon

  return (
    <div
      className="reveal relative flex flex-col items-center text-center gap-5 cursor-default"
      style={{ transitionDelay: `${index * 0.15}s` }}
      onMouseEnter={() => setHovered(true)}
      onMouseLeave={() => setHovered(false)}
    >
      {/* iPhone mockup */}
      <div className="relative">
        {/* Glow that intensifies on hover */}
        <div
          className="absolute inset-0 rounded-[36px] blur-2xl pointer-events-none transition-all duration-500"
          style={{
            backgroundColor: step.color,
            opacity: hovered ? 0.35 : 0.15,
            transform: hovered ? "scale(0.85)" : "scale(0.7)",
          }}
          aria-hidden="true"
        />
        <div
          style={{
            transform: hovered ? "translateY(-6px) scale(1.03)" : "translateY(0) scale(1)",
            transition: "transform 0.4s cubic-bezier(0.22,1,0.36,1)",
          }}
        >
          <IPhoneMockup
            src={step.img}
            alt={`Mali Up — ${step.title}`}
            width={150}
            accentColor={step.color}
          />
        </div>

        {/* Step badge */}
        <span
          className="absolute -top-3 -right-3 w-8 h-8 rounded-full flex items-center justify-center font-heading font-bold text-sm text-[#0C1B2E] z-20 shadow-lg transition-transform duration-300"
          style={{
            backgroundColor: step.color,
            transform: hovered ? "scale(1.15) rotate(-6deg)" : "scale(1) rotate(0deg)",
          }}
        >
          {index + 1}
        </span>
      </div>

      {/* Icon chip */}
      <div
        className="w-14 h-14 rounded-2xl flex items-center justify-center shadow-xl transition-all duration-300"
        style={{
          backgroundColor: `${step.color}18`,
          border: `1px solid ${step.color}${hovered ? "55" : "28"}`,
          boxShadow: hovered ? `0 8px 24px ${step.color}25` : "none",
        }}
      >
        <Icon
          size={26}
          style={{
            color: step.color,
            transform: hovered ? "scale(1.15)" : "scale(1)",
            transition: "transform 0.3s ease",
          }}
        />
      </div>

      <div className="flex flex-col gap-2">
        <h3 className="font-heading font-bold text-[#0C1B2E] text-lg">{step.title}</h3>
        <p className="text-[#0C1B2E]/65 leading-relaxed text-sm max-w-xs">{step.desc}</p>
      </div>
    </div>
  )
}

export function HowItWorks() {
  const sectionRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    const observer = new IntersectionObserver(
      (entries) => entries.forEach((e) => e.isIntersecting && e.target.classList.add("visible")),
      { threshold: 0.1 }
    )
    sectionRef.current?.querySelectorAll(".reveal,.reveal-left,.reveal-right")
      .forEach((el) => observer.observe(el))
    return () => observer.disconnect()
  }, [])

  return (
    <section
      id="how-it-works"
      ref={sectionRef}
      className="py-24 relative overflow-hidden"
      style={{ backgroundColor: "#FFFFFF" }}
      aria-labelledby="hiw-heading"
    >
      {/* Grid texture */}
      <div
        className="absolute inset-0 opacity-[0.03]"
        style={{
          backgroundImage: "linear-gradient(#F5A623 1px,transparent 1px),linear-gradient(90deg,#F5A623 1px,transparent 1px)",
          backgroundSize: "72px 72px",
        }}
        aria-hidden="true"
      />

      <div className="max-w-6xl mx-auto px-6 relative z-10">
        {/* Header */}
        <div className="text-center mb-20 flex flex-col gap-4">
          <div className="reveal inline-flex justify-center">
            <span className="glass-amber text-[#F5A623] text-xs font-bold px-4 py-1.5 rounded-full tracking-wider uppercase">
              Simple Onboarding
            </span>
          </div>
          <h2
            id="hiw-heading"
            className="reveal font-heading font-bold text-[#0C1B2E] text-balance"
            style={{ fontSize: "clamp(1.9rem,4vw,3rem)" }}
          >
            Up &amp; Running in Minutes
          </h2>
          <p className="reveal text-[#0C1B2E]/65 max-w-lg mx-auto leading-relaxed">
            No IT team required. No steep learning curve. Just three steps from download to your first sale.
          </p>
        </div>

        {/* Steps */}
        <div className="relative grid md:grid-cols-3 gap-10">
          {/* Gradient connector line */}
          <div
            className="absolute top-[88px] left-[22%] right-[22%] h-px hidden md:block"
            style={{ background: "linear-gradient(90deg,#F5A623 0%,#22C55E 50%,#3B82F6 100%)", opacity: 0.2 }}
            aria-hidden="true"
          />

          {steps.map((step, i) => (
            <StepCard key={step.number} step={step} index={i} />
          ))}
        </div>

        {/* CTA */}
        <div className="mt-16 flex justify-center reveal">
          <a
            href="#waitlist"
            className="relative overflow-hidden shimmer-btn text-[#0C1B2E] font-bold px-8 py-4 rounded-2xl text-base shadow-2xl hover:scale-105 hover:shadow-[0_8px_32px_rgba(245,166,35,0.45)] active:scale-[0.97] transition-all duration-200 inline-flex items-center gap-2 group"
          >
            Start Your Free Account
            <span className="group-hover:translate-x-1 transition-transform duration-200" aria-hidden="true">→</span>
          </a>
        </div>
      </div>
    </section>
  )
}
