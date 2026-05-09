import { Nav } from "@/components/mali/nav"
import { Hero } from "@/components/mali/hero"
import { AppJourney } from "@/components/mali/app-journey"
import { FeaturesShowcase } from "@/components/mali/features-showcase"
import { DownloadCTA } from "@/components/mali/download-cta"
import { Footer } from "@/components/mali/footer"

export default function MaliUpPage() {
  return (
    <main className="bg-background">
      <Nav />
      <Hero />
      <section id="journey">
        <AppJourney />
      </section>
      <section id="features">
        <FeaturesShowcase />
      </section>
      <DownloadCTA />
      <Footer />
    </main>
  )
}
