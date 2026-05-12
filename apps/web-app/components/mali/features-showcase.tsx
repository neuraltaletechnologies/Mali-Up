"use client"

import { useRef } from "react"
import NextImage from "next/image"
import { motion, useInView } from "framer-motion"

const topScreens = [
  {
    src: "/app-dashboard.jpg",
    label: "Financial Overview",
    tag: "Track",
    color: "#7CB798",
    className: "lg:col-span-2 lg:row-span-2",
  },
  {
    src: "/app-inventory.jpg",
    label: "Asset Registry",
    tag: "Register",
    color: "#D4A574",
    className: "lg:col-span-1 lg:row-span-1",
  },
  {
    src: "/app-invoice.jpg",
    label: "Business Tools",
    tag: "Manage",
    color: "#C8847B",
    className: "lg:col-span-1 lg:row-span-1",
  },
]

export function FeaturesShowcase() {
  const ref = useRef(null)
  const isInView = useInView(ref, { once: true, margin: "-80px" })

  return (
    <section
      ref={ref}
      className="py-28 bg-secondary/30"
      aria-labelledby="features-heading"
    >
      <div className="max-w-6xl mx-auto px-6">
        {/* Header */}
        <motion.div
          className="mb-14"
          initial={{ opacity: 0, y: 24 }}
          animate={isInView ? { opacity: 1, y: 0 } : {}}
          transition={{ duration: 0.6 }}
        >
          <span className="text-muted-foreground text-[11px] font-medium tracking-[0.22em] uppercase block mb-4">
            Inside the App
          </span>
          <h2
            id="features-heading"
            className="font-heading font-bold text-foreground"
            style={{
              fontSize: "clamp(2rem, 5vw, 3.5rem)",
              lineHeight: 1.05,
              letterSpacing: "-0.02em",
            }}
          >
            Everything in one place
          </h2>
        </motion.div>

        {/* Bento grid: col1+col2 = dashboard (rows 1–2), col3 = inventory (row1) + invoice (row2) */}
        <div
          className="grid lg:grid-cols-3 lg:grid-rows-2 gap-4"
          style={{ height: "clamp(420px, 55vw, 600px)" }}
        >
          {topScreens.map((screen, i) => (
            <ScreenCard
              key={screen.src}
              {...screen}
              delay={i * 0.1}
              isInView={isInView}
            />
          ))}
        </div>

        {/* Full-width analytics card */}
        <motion.div
          className="relative overflow-hidden rounded-2xl mt-4 group cursor-default"
          style={{ height: "clamp(160px, 22vw, 240px)" }}
          initial={{ opacity: 0, y: 24 }}
          animate={isInView ? { opacity: 1, y: 0 } : {}}
          transition={{ duration: 0.6, delay: 0.3 }}
        >
          <NextImage
            src="/app-analytics.jpg"
            alt="Growth Analytics"
            fill
            className="object-cover object-top transition-transform duration-700 group-hover:scale-105"
            sizes="100vw"
          />
          <div className="absolute inset-0 bg-gradient-to-t from-black/60 via-black/10 to-transparent" />
          <div className="absolute bottom-5 left-5 flex items-center gap-2.5">
            <span
              className="text-[10px] font-semibold tracking-widest uppercase px-2 py-1 rounded-full text-white"
              style={{ backgroundColor: "#8B7355" }}
            >
              Grow
            </span>
            <span className="text-white text-sm font-medium">Growth Analytics</span>
          </div>
        </motion.div>
      </div>
    </section>
  )
}

function ScreenCard({
  src,
  label,
  tag,
  color,
  className,
  delay,
  isInView,
}: {
  src: string
  label: string
  tag: string
  color: string
  className: string
  delay: number
  isInView: boolean
}) {
  return (
    <motion.div
      className={`relative overflow-hidden rounded-2xl group cursor-default h-52 lg:h-auto ${className}`}
      initial={{ opacity: 0, y: 24 }}
      animate={isInView ? { opacity: 1, y: 0 } : {}}
      transition={{ duration: 0.6, delay }}
    >
      <NextImage
        src={src}
        alt={label}
        fill
        className="object-cover object-top transition-transform duration-700 group-hover:scale-105"
        sizes="(max-width: 1024px) 100vw, 50vw"
      />
      <div className="absolute inset-0 bg-gradient-to-t from-black/60 via-black/10 to-transparent" />
      <div className="absolute bottom-5 left-5 flex items-center gap-2.5">
        <span
          className="text-[10px] font-semibold tracking-widest uppercase px-2 py-1 rounded-full text-white"
          style={{ backgroundColor: color }}
        >
          {tag}
        </span>
        <span className="text-white text-sm font-medium">{label}</span>
      </div>
    </motion.div>
  )
}
