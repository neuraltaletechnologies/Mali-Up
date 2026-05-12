"use client"

import { useRef, useEffect, useState } from "react"
import { IPhoneMockup } from "@/components/mali/iphone-mockup"

const steps = [
  {
    id: "track",
    number: "01",
    title: "Track",
    subtitle: "Every shilling, accounted for",
    color: "#7CB798",
    screen: "/app-dashboard.jpg",
  },
  {
    id: "register",
    number: "02",
    title: "Register",
    subtitle: "Your assets, your wealth",
    color: "#D4A574",
    screen: "/app-inventory.jpg",
  },
  {
    id: "manage",
    number: "03",
    title: "Manage",
    subtitle: "Your business, simplified",
    color: "#C8847B",
    screen: "/app-invoice.jpg",
  },
  {
    id: "grow",
    number: "04",
    title: "Grow",
    subtitle: "See the complete picture",
    color: "#8B7355",
    screen: "/app-analytics.jpg",
  },
]

export function AppJourney() {
  const containerRef = useRef<HTMLDivElement>(null)
  const [activeStep, setActiveStep] = useState(0)
  const [progress, setProgress] = useState(0)

  useEffect(() => {
    const handleScroll = () => {
      if (!containerRef.current) return
      const rect = containerRef.current.getBoundingClientRect()
      const scrolled = -rect.top
      const scrollable = rect.height - window.innerHeight
      const p = Math.max(0, Math.min(1, scrolled / scrollable))
      setProgress(p)
      setActiveStep(Math.min(Math.floor(p * steps.length), steps.length - 1))
    }
    window.addEventListener("scroll", handleScroll, { passive: true })
    handleScroll()
    return () => window.removeEventListener("scroll", handleScroll)
  }, [])

  const step = steps[activeStep]

  return (
    <section
      ref={containerRef}
      className="relative bg-background"
      style={{ height: `${(steps.length + 1) * 100}vh` }}
      aria-label="How Mali Up works"
    >
      <div className="sticky top-0 h-screen overflow-hidden">
        {/* Progress line */}
        <div className="absolute top-0 left-0 right-0 h-0.5 bg-muted z-50">
          <div
            className="h-full origin-left transition-transform duration-200"
            style={{
              transform: `scaleX(${progress})`,
              backgroundColor: step.color,
            }}
          />
        </div>

        {/* Step dots — right side */}
        <div className="hidden lg:flex absolute right-8 top-1/2 -translate-y-1/2 flex-col gap-5 z-40">
          {steps.map((s, i) => (
            <div key={s.id} className="flex items-center gap-3 justify-end">
              <span
                className="text-xs font-medium transition-all duration-300"
                style={{
                  color: s.color,
                  opacity: i === activeStep ? 1 : 0,
                }}
              >
                {s.title}
              </span>
              <div
                className="rounded-full transition-all duration-300"
                style={{
                  width: i === activeStep ? 10 : 6,
                  height: i === activeStep ? 10 : 6,
                  backgroundColor:
                    i === activeStep ? s.color : "rgba(26,26,26,0.15)",
                }}
              />
            </div>
          ))}
        </div>

        {/* Main content */}
        <div className="h-full flex items-center px-6">
          <div className="w-full max-w-5xl mx-auto">
            <div className="grid lg:grid-cols-2 gap-12 lg:gap-24 items-center">

              {/* Text — left */}
              <div className="relative order-2 lg:order-1 text-center lg:text-left">
                {steps.map((s, i) => (
                  <div
                    key={s.id}
                    className="transition-all duration-700 ease-out"
                    style={{
                      opacity: i === activeStep ? 1 : 0,
                      transform:
                        i === activeStep
                          ? "translateY(0)"
                          : i < activeStep
                          ? "translateY(-36px)"
                          : "translateY(36px)",
                      position: i === activeStep ? "relative" : "absolute",
                      inset: i === activeStep ? "auto" : 0,
                      pointerEvents: i === activeStep ? "auto" : "none",
                    }}
                  >
                    {/* Big faded number */}
                    <span
                      className="font-heading font-bold block leading-none select-none"
                      style={{
                        fontSize: "clamp(5rem, 15vw, 11rem)",
                        color: s.color,
                        opacity: 0.08,
                      }}
                    >
                      {s.number}
                    </span>
                    {/* Title */}
                    <h2
                      className="font-heading font-bold leading-none -mt-[0.45em]"
                      style={{
                        fontSize: "clamp(3rem, 8vw, 6rem)",
                        color: s.color,
                      }}
                    >
                      {s.title}
                    </h2>
                    {/* One-line subtitle */}
                    <p className="text-foreground text-xl font-medium mt-5">
                      {s.subtitle}
                    </p>
                  </div>
                ))}
              </div>

              {/* Phone — right */}
              <div className="flex justify-center order-1 lg:order-2">
                <div className="relative">
                  {/* Colour glow */}
                  <div
                    className="absolute inset-0 rounded-full blur-[70px] opacity-25 pointer-events-none transition-all duration-700"
                    style={{
                      background: `radial-gradient(circle, ${step.color}55 0%, transparent 65%)`,
                      transform: "scale(1.6)",
                    }}
                  />

                  {steps.map((s, i) => (
                    <div
                      key={s.id}
                      className="transition-all duration-500 ease-out"
                      style={{
                        opacity: i === activeStep ? 1 : 0,
                        transform: i === activeStep ? "scale(1)" : "scale(0.94)",
                        position: i === activeStep ? "relative" : "absolute",
                        inset: i === activeStep ? "auto" : 0,
                        pointerEvents: i === activeStep ? "auto" : "none",
                      }}
                    >
                      <IPhoneMockup
                        src={s.screen}
                        alt={`Mali Up — ${s.title}`}
                        width={300}
                        accentColor={s.color}
                        animate
                      />
                    </div>
                  ))}
                </div>
              </div>

            </div>
          </div>
        </div>
      </div>
    </section>
  )
}
