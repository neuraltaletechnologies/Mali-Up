"use client"

import { useEffect, useRef } from "react"
import { IPhoneMockup } from "@/components/mali/iphone-mockup"
import NextImage from "next/image"

const screens = [
  {
    src: "/app-dashboard.jpg",
    alt: "Mali Up main dashboard with revenue chart and business overview",
    label: "Dashboard",
    color: "#F5A623",
    angle: "-8deg",
    zIndex: 4,
    offsetY: "20px",
  },
  {
    src: "/app-invoice.jpg",
    alt: "Mali Up invoicing screen with paid and pending invoice list",
    label: "Invoicing",
    color: "#22C55E",
    angle: "-3deg",
    zIndex: 5,
    offsetY: "0px",
  },
  {
    src: "/app-analytics.jpg",
    alt: "Mali Up analytics screen with revenue chart and product performance",
    label: "Analytics",
    color: "#3B82F6",
    angle: "3deg",
    zIndex: 5,
    offsetY: "0px",
  },
  {
    src: "/app-inventory.jpg",
    alt: "Mali Up inventory management screen with product stock levels",
    label: "Inventory",
    color: "#EF4444",
    angle: "8deg",
    zIndex: 4,
    offsetY: "20px",
  },
]

export function AppGallery() {
  const sectionRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    const observer = new IntersectionObserver(
      (entries) =>
        entries.forEach((e) => e.isIntersecting && e.target.classList.add("visible")),
      { threshold: 0.1 }
    )
    sectionRef.current?.querySelectorAll(".reveal").forEach((el) => observer.observe(el))
    return () => observer.disconnect()
  }, [])

  return (
    <section
      id="gallery"
      ref={sectionRef}
      className="py-24 relative overflow-hidden"
      style={{ backgroundColor: "#FFFFFF" }}
      aria-labelledby="gallery-heading"
    >
      {/* Radial amber glow center */}
      <div
        className="absolute left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2 rounded-full blur-3xl opacity-10 pointer-events-none"
        style={{ width: "600px", height: "400px", background: "radial-gradient(ellipse, #F5A623 0%, transparent 70%)" }}
        aria-hidden="true"
      />

      <div className="max-w-6xl mx-auto px-6">
        {/* Header */}
        <div className="text-center mb-16 flex flex-col gap-4">
          <div className="reveal inline-flex justify-center">
            <span className="glass-amber text-[#F5A623] text-xs font-bold px-4 py-1.5 rounded-full tracking-wider uppercase">
              App Screens
            </span>
          </div>
          <h2
            id="gallery-heading"
            className="reveal font-heading font-bold text-[#0C1B2E] text-balance"
            style={{ fontSize: "clamp(1.9rem, 4vw, 3rem)" }}
          >
            Every Tool at Your Fingertips
          </h2>
          <p className="reveal text-[#0C1B2E]/65 max-w-lg mx-auto leading-relaxed">
            Beautifully designed for clarity and speed. Each module is a tap away, built for the realities of African business on the move.
          </p>
        </div>

        {/* Phone gallery — fanned/overlapping on desktop, stacked on mobile */}
        <div
          className="reveal flex flex-wrap justify-center gap-6 md:gap-0 md:flex-nowrap md:items-end md:justify-center"
          style={{ minHeight: "520px" }}
        >
          {screens.map((s, i) => (
            <div
              key={s.label}
              className="flex flex-col items-center gap-4 transition-transform duration-300 hover:scale-105 hover:z-20"
              style={{
                transform: `rotate(${s.angle}) translateY(${s.offsetY})`,
                zIndex: s.zIndex,
                marginLeft: i > 0 ? "-32px" : "0",
                transitionDelay: `${i * 0.08}s`,
              }}
            >
              {/* Glow under each phone */}
              <div className="relative">
                <div
                  className="absolute bottom-0 left-1/2 -translate-x-1/2 w-28 h-12 rounded-full blur-2xl opacity-40 pointer-events-none"
                  style={{ backgroundColor: s.color }}
                  aria-hidden="true"
                />
                <IPhoneMockup
                  src={s.src}
                  alt={s.alt}
                  width={200}
                  accentColor={s.color}
                />
              </div>
              {/* Label pill */}
              <span
                className="text-xs font-bold px-3 py-1 rounded-full"
                style={{ backgroundColor: `${s.color}18`, color: s.color, border: `1px solid ${s.color}30` }}
              >
                {s.label}
              </span>
            </div>
          ))}
        </div>

        {/* Download nudge */}
        <div className="reveal text-center mt-16 flex flex-col items-center gap-5">
          <div className="flex items-center gap-3 justify-center mb-1">
            <NextImage
              src="/maliup-logo.png"
              alt="Mali Up logo"
              width={32}
              height={32}
              className="rounded-xl"
            />
            <p className="text-[#0C1B2E]/45 text-sm uppercase tracking-widest font-semibold">
              Coming to
            </p>
          </div>
          <div className="flex gap-4 flex-wrap justify-center">
            {[
              { name: "Google Play", badge: "Android · Primary" },
              { name: "App Store", badge: "iOS · Secondary" },
            ].map((store) => (
              <div
                key={store.name}
                className="glass flex items-center gap-3 px-5 py-3.5 rounded-2xl hover:border-white/20 transition-all duration-200 cursor-default"
              >
                <div className="flex flex-col">
                  <span className="text-[#0C1B2E]/35 text-[10px] uppercase tracking-widest">{store.badge}</span>
                  <span className="text-[#0C1B2E] font-bold text-sm">{store.name}</span>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </section>
  )
}
