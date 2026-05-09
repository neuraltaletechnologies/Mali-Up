"use client"

import { useRef, useEffect, useState } from "react"
import { IPhoneMockup } from "@/components/mali/iphone-mockup"
import { Wallet, Building2, TrendingUp, PieChart } from "lucide-react"

const journeySteps = [
  {
    id: "track",
    title: "Track",
    subtitle: "Every shilling, accounted for",
    description: "Log income from any source. Categorize expenses automatically. Watch your savings grow.",
    icon: Wallet,
    color: "#7CB798",
    screen: "/app-dashboard.jpg",
  },
  {
    id: "register",
    title: "Register",
    subtitle: "Your assets, your wealth",
    description: "Land, property, vehicles, stocks. Everything you own in one secure place.",
    icon: Building2,
    color: "#D4A574",
    screen: "/app-inventory.jpg",
  },
  {
    id: "manage",
    title: "Manage",
    subtitle: "Your business, simplified",
    description: "Sales, invoicing, inventory, customers. Run your business from your pocket.",
    icon: TrendingUp,
    color: "#C8847B",
    screen: "/app-invoice.jpg",
  },
  {
    id: "grow",
    title: "Grow",
    subtitle: "See your full picture",
    description: "Net worth dashboard, insights, goals. Make smarter financial decisions.",
    icon: PieChart,
    color: "#8B7355",
    screen: "/app-analytics.jpg",
  },
]

function JourneyStep({
  step,
  index,
  isActive,
}: {
  step: (typeof journeySteps)[0]
  index: number
  isActive: boolean
}) {
  const Icon = step.icon

  return (
    <div
      className={`absolute inset-0 flex items-center justify-center transition-all duration-700 ease-out ${
        isActive ? "opacity-100 translate-y-0 scale-100" : "opacity-0 translate-y-12 scale-95 pointer-events-none"
      }`}
    >
      <div className="grid lg:grid-cols-2 gap-12 lg:gap-24 items-center max-w-6xl mx-auto px-6 w-full">
        {/* Text Content */}
        <div className="flex flex-col gap-6 text-center lg:text-left order-2 lg:order-1">
          <div
            className="w-16 h-16 rounded-2xl flex items-center justify-center mx-auto lg:mx-0 transition-transform duration-500"
            style={{ backgroundColor: `${step.color}20` }}
          >
            <Icon className="w-8 h-8" style={{ color: step.color }} />
          </div>
          
          <div>
            <span
              className="text-7xl lg:text-9xl font-heading font-bold opacity-10 block"
              style={{ color: step.color }}
            >
              {String(index + 1).padStart(2, "0")}
            </span>
            <h3
              className="font-heading text-5xl lg:text-7xl font-medium -mt-8 lg:-mt-14"
              style={{ color: step.color }}
            >
              {step.title}
            </h3>
          </div>
          
          <p className="text-foreground text-xl lg:text-2xl font-medium">
            {step.subtitle}
          </p>
          
          <p className="text-muted-foreground text-lg leading-relaxed max-w-md mx-auto lg:mx-0">
            {step.description}
          </p>
        </div>

        {/* Phone Mockup */}
        <div className="flex justify-center order-1 lg:order-2">
          <div className="relative">
            <div
              className="absolute inset-0 blur-3xl opacity-30 rounded-full transition-opacity duration-700"
              style={{
                background: `radial-gradient(circle, ${step.color}40 0%, transparent 60%)`,
                transform: "scale(1.5)",
              }}
            />
            <IPhoneMockup
              src={step.screen}
              alt={`Mali Up ${step.title} feature`}
              width={260}
              accentColor={step.color}
              animate
            />
          </div>
        </div>
      </div>
    </div>
  )
}

export function AppJourney() {
  const containerRef = useRef<HTMLDivElement>(null)
  const [activeStep, setActiveStep] = useState(0)
  const [progress, setProgress] = useState(0)

  useEffect(() => {
    const handleScroll = () => {
      if (!containerRef.current) return
      
      const rect = containerRef.current.getBoundingClientRect()
      const containerTop = rect.top
      const containerHeight = rect.height
      const windowHeight = window.innerHeight
      
      // Calculate scroll progress through the container
      const scrolled = -containerTop
      const scrollableHeight = containerHeight - windowHeight
      const scrollProgress = Math.max(0, Math.min(1, scrolled / scrollableHeight))
      
      setProgress(scrollProgress)
      
      // Determine active step based on scroll progress
      const stepIndex = Math.min(
        Math.floor(scrollProgress * journeySteps.length),
        journeySteps.length - 1
      )
      setActiveStep(stepIndex)
    }

    window.addEventListener("scroll", handleScroll, { passive: true })
    handleScroll() // Initial check
    
    return () => window.removeEventListener("scroll", handleScroll)
  }, [])

  return (
    <section
      ref={containerRef}
      className="relative bg-background"
      style={{ height: `${(journeySteps.length + 1) * 100}vh` }}
      aria-label="App features journey"
    >
      {/* Sticky container */}
      <div className="sticky top-0 h-screen flex flex-col overflow-hidden">
        {/* Progress bar */}
        <div className="absolute top-0 left-0 right-0 h-1 bg-muted z-50">
          <div
            className="h-full bg-accent transition-transform duration-150 origin-left"
            style={{ transform: `scaleX(${progress})` }}
          />
        </div>

        {/* Step indicators */}
        <div className="hidden lg:flex absolute right-8 top-1/2 -translate-y-1/2 flex-col gap-4 z-40">
          {journeySteps.map((step, i) => (
            <div key={step.id} className="flex items-center gap-3">
              <div
                className={`w-2 h-2 rounded-full transition-all duration-300 ${
                  i === activeStep ? "scale-150" : "scale-75 opacity-40"
                }`}
                style={{ backgroundColor: step.color }}
              />
              <span
                className={`text-xs font-medium transition-all duration-300 ${
                  i === activeStep ? "opacity-100" : "opacity-0"
                }`}
                style={{ color: step.color }}
              >
                {step.title}
              </span>
            </div>
          ))}
        </div>

        {/* Content area */}
        <div className="flex-1 relative">
          {journeySteps.map((step, i) => (
            <JourneyStep
              key={step.id}
              step={step}
              index={i}
              isActive={i === activeStep}
            />
          ))}
        </div>
      </div>
    </section>
  )
}
