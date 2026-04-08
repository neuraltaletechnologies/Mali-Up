import { Nav } from "@/components/mali/nav"
import { Hero } from "@/components/mali/hero"
import { Features } from "@/components/mali/features"
import { HowItWorks } from "@/components/mali/how-it-works"
import { PhoneShowcase } from "@/components/mali/phone-showcase"
import { AppGallery } from "@/components/mali/app-gallery"
import { Stats } from "@/components/mali/stats"
import { Waitlist } from "@/components/mali/waitlist"
import { Footer } from "@/components/mali/footer"

export default function MaliUpPage() {
  return (
    <main style={{ backgroundColor: "#FFFFFF" }}>
      <Nav />
      <Hero />
      <Features />
      <HowItWorks />
      <PhoneShowcase />
      <AppGallery />
      <Stats />
      <Waitlist />
      <Footer />
    </main>
  )
}
