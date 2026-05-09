"use client"

import { useRef } from "react"
import { motion, useInView } from "framer-motion"
import { 
  Wallet, PiggyBank, Receipt, Target,
  Building2, Car, BarChart2, Layers,
  ShoppingCart, FileText, Users, TrendingUp
} from "lucide-react"

const featureGroups = [
  {
    title: "Money Flow",
    color: "#7CB798",
    features: [
      { icon: Wallet, label: "Income" },
      { icon: Receipt, label: "Expenses" },
      { icon: PiggyBank, label: "Savings" },
      { icon: Target, label: "Goals" },
    ],
  },
  {
    title: "Assets",
    color: "#D4A574",
    features: [
      { icon: Building2, label: "Property" },
      { icon: Car, label: "Vehicles" },
      { icon: BarChart2, label: "Stocks" },
      { icon: Layers, label: "Net Worth" },
    ],
  },
  {
    title: "Business",
    color: "#C8847B",
    features: [
      { icon: ShoppingCart, label: "Sales" },
      { icon: FileText, label: "Invoices" },
      { icon: Users, label: "Customers" },
      { icon: TrendingUp, label: "Analytics" },
    ],
  },
]

function FeatureGroup({ 
  group, 
  index 
}: { 
  group: typeof featureGroups[0]
  index: number 
}) {
  const ref = useRef(null)
  const isInView = useInView(ref, { once: true, margin: "-100px" })

  return (
    <motion.div
      ref={ref}
      className="flex flex-col items-center gap-8"
      initial={{ opacity: 0, y: 40 }}
      animate={isInView ? { opacity: 1, y: 0 } : {}}
      transition={{ duration: 0.6, delay: index * 0.2 }}
    >
      <h3
        className="text-2xl font-heading font-medium"
        style={{ color: group.color }}
      >
        {group.title}
      </h3>
      
      <div className="grid grid-cols-2 gap-4">
        {group.features.map((feature, i) => {
          const Icon = feature.icon
          return (
            <motion.div
              key={feature.label}
              className="feature-card p-6 rounded-2xl flex flex-col items-center gap-3 min-w-[120px]"
              initial={{ opacity: 0, scale: 0.9 }}
              animate={isInView ? { opacity: 1, scale: 1 } : {}}
              transition={{ duration: 0.4, delay: index * 0.2 + i * 0.1 }}
              whileHover={{ scale: 1.05 }}
            >
              <div
                className="w-12 h-12 rounded-xl flex items-center justify-center"
                style={{ backgroundColor: `${group.color}15` }}
              >
                <Icon className="w-6 h-6" style={{ color: group.color }} />
              </div>
              <span className="text-sm font-medium text-foreground">
                {feature.label}
              </span>
            </motion.div>
          )
        })}
      </div>
    </motion.div>
  )
}

export function FeaturesShowcase() {
  const headerRef = useRef(null)
  const isHeaderInView = useInView(headerRef, { once: true, margin: "-50px" })

  return (
    <section
      className="py-32 bg-secondary/30"
      aria-labelledby="features-heading"
    >
      <div className="max-w-6xl mx-auto px-6">
        {/* Header */}
        <motion.div
          ref={headerRef}
          className="text-center mb-20"
          initial={{ opacity: 0, y: 30 }}
          animate={isHeaderInView ? { opacity: 1, y: 0 } : {}}
          transition={{ duration: 0.6 }}
        >
          <span className="text-muted-foreground text-sm font-medium tracking-widest uppercase mb-4 block">
            Everything You Need
          </span>
          <h2
            id="features-heading"
            className="font-heading text-4xl lg:text-5xl font-medium text-foreground text-balance"
          >
            One app for your
            <br />
            complete financial life
          </h2>
        </motion.div>

        {/* Feature Groups */}
        <div className="grid md:grid-cols-3 gap-12 lg:gap-16">
          {featureGroups.map((group, i) => (
            <FeatureGroup key={group.title} group={group} index={i} />
          ))}
        </div>
      </div>
    </section>
  )
}
