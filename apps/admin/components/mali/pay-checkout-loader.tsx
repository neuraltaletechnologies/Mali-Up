"use client"

import dynamic from "next/dynamic"
import { Loader2 } from "lucide-react"

// The checkout pulls in the Firebase client SDK (firebase/firestore,
// firebase/functions). Server-rendering it on Cloudflare Workers loads
// Firestore's Node build, whose gRPC/protobufjs layer can't run there (same
// reason lib/firestore-rest.ts exists) and turned GET /pay into a 500. It
// only ever does anything in the browser anyway, so render it client-only.
export const PayCheckoutLoader = dynamic(
  () => import("./pay-checkout").then((m) => m.PayCheckout),
  {
    ssr: false,
    loading: () => (
      <div className="max-w-lg mx-auto px-5 py-24 flex justify-center text-[#0C1B2E]/40">
        <Loader2 size={24} className="animate-spin" />
      </div>
    ),
  },
)
