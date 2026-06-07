import { SmoothScrollProvider } from "@/components/mali/scroll-provider"
import { Nav } from "@/components/mali/nav"
import { Hero } from "@/components/mali/hero"
import { ProblemSection } from "@/components/mali/problem-section"
import { TransformationSection } from "@/components/mali/transformation-section"
import { ProductJourney } from "@/components/mali/product-journey"
import { IndustryShowcase } from "@/components/mali/industry-showcase"
import { TeamSection } from "@/components/mali/team-section"
import { MobileShowcase } from "@/components/mali/mobile-showcase"
import { WebServices } from "@/components/mali/web-services"
import { TrustSection } from "@/components/mali/trust-section"
import { FinalCTA } from "@/components/mali/final-cta"
import { Footer } from "@/components/mali/footer"

export default function MaliUpPage() {
  return (
    <SmoothScrollProvider>
      <main
        style={{
          background: "var(--mali-navy-950)",
          overflowX: "hidden",
        }}
      >
        <Nav />

        {/* 1 — Cinematic Hero */}
        <Hero />

        {/* 2 — The Problem: scrollytelling chaos */}
        <ProblemSection />

        {/* 3 — The Transformation: chaos → clarity */}
        <TransformationSection />

        {/* 4 — Product Journey: 4-step story */}
        <section id="features">
          <ProductJourney />
        </section>

        {/* 5 — Industry Adaptation */}
        <IndustryShowcase />

        {/* 6 — Team Management */}
        <TeamSection />

        {/* 7 — Mobile Experience */}
        <MobileShowcase />

        {/* 8 — Web Services Cross-sell */}
        <WebServices />

        {/* 9 — Trust & Security */}
        <TrustSection />

        {/* 10 — Final CTA */}
        <FinalCTA />

        <Footer />
      </main>
    </SmoothScrollProvider>
  )
}
