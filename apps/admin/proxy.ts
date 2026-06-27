import type { NextRequest } from "next/server"
import { NextResponse } from "next/server"

// Runs on Cloudflare Edge — pure Web API, no Node.js dependencies.
// Full JWT verification happens in each protected route via NextAuth auth().
export function proxy(request: NextRequest) {
  const { pathname } = request.nextUrl

  if (!pathname.startsWith("/admin")) return NextResponse.next()
  if (pathname.startsWith("/admin/login")) return NextResponse.next()

  // NextAuth v5 session cookies (secure prefix in production, plain in dev)
  const sessionToken =
    request.cookies.get("__Secure-authjs.session-token")?.value ??
    request.cookies.get("authjs.session-token")?.value

  if (!sessionToken) {
    const url = new URL("/admin/login", request.url)
    url.searchParams.set("callbackUrl", encodeURIComponent(pathname))
    return NextResponse.redirect(url)
  }

  return NextResponse.next()
}

export const config = {
  matcher: ["/admin/:path*"],
}
