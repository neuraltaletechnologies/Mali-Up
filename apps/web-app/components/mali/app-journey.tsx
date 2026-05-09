"use client"

import { useRef } from "react"
import { motion, useScroll, useTransform } from "framer-motion"
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
  progress,
}: {
  step: (typeof journeySteps)[0]
  index: number
  progress: ReturnType<typeof useTransform>
}) {
  const Icon = step.icon
  const stepStart = index / journeySteps.length
  const stepEnd = (index + 1) / journeySteps.length
  
  const opacity = useTransform(
    progress,
    [stepStart - 0.1, stepStart, stepEnd - 0.1, stepEnd],
    [0, 1, 1, 0]
  )
  
  const y = useTransform(
    progress,
    [stepStart - 0.1, stepStart, stepEnd - 0.1, stepEnd],
    [50, 0, 0, -50]
  )

  return (
    <motion.div
      className="absolute inset-0 flex items-center justify-center"
      style={{ opacity, y }}
    >
      <div className="grid lg:grid-cols-2 gap-12 lg:gap-24 items-center max-w-6xl mx-auto px-6 w-full">
        {/* Text Content */}
        <div className="flex flex-col gap-6 text-center lg:text-left order-2 lg:order-1">
          <div
            className="w-16 h-16 rounded-2xl flex items-center justify-center mx-auto lg:mx-0"
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
              className="absolute inset-0 blur-3xl opacity-30 rounded-full"
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
    </motion.div>
  )
}

export function AppJourney() {
  const containerRef = useRef<HTMLDivElement>(null)
  const { scrollYProgress } = useScroll({
    target: containerRef,
    offset: ["start start", "end end"],
  })

  return (
    <section
      ref={containerRef}
      className="relative bg-background"
      style={{ height: `${(journeySteps.length + 1) * 100}vh`, position: "relative" }}
      aria-label="App features journey"
    >
      {/* Section Header - Sticky */}
      <div className="sticky top-0 h-screen flex flex-col">
        {/* Progress bar */}
        <motion.div
          className="absolute top-0 left-0 h-1 bg-accent z-50"
          style={{ scaleX: scrollYProgress, transformOrigin: "left" }}
        />

        {/* Step indicators */}
        <div className="hidden lg:flex absolute right-8 top-1/2 -translate-y-1/2 flex-col gap-4 z-40">
          {journeySteps.map((step, i) => {
            const stepProgress = useTransform(
              scrollYProgress,
              [i / journeySteps.length, (i + 0.5) / journeySteps.length],
              [0, 1]
            )
            return (
              <motion.div
                key={step.id}
                className="flex items-center gap-3"
              >
                <motion.div
                  className="w-2 h-2 rounded-full"
                  style={{
                    backgroundColor: step.color,
                    scale: useTransform(stepProgress, [0, 1], [0.6, 1.2]),
                    opacity: useTransform(stepProgress, [0, 0.5, 1], [0.3, 1, 1]),
                  }}
                />
                <motion.span
                  className="text-xs font-medium"
                  style={{
                    color: step.color,
                    opacity: useTransform(stepProgress, [0, 0.5, 1], [0, 1, 1]),
                  }}
                >
                  {step.title}
                </motion.span>
              </motion.div>
            )
          })}
        </div>

        {/* Content area */}
        <div className="flex-1 relative overflow-hidden">
          {journeySteps.map((step, i) => (
            <JourneyStep
              key={step.id}
              step={step}
              index={i}
              progress={scrollYProgress}
            />
          ))}
        </div>
      </div>
    </section>
  )
}
