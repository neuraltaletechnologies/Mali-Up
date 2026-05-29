import { auth } from "@/auth";
import { NextResponse } from "next/server";

export default auth((req) => {
  const isLoginPage = req.nextUrl.pathname === "/admin/login";

  if (!isLoginPage && !req.auth) {
    const loginUrl = new URL("/admin/login", req.url);
    loginUrl.searchParams.set("callbackUrl", req.nextUrl.pathname);
    return NextResponse.redirect(loginUrl);
  }

  if (isLoginPage && req.auth) {
    return NextResponse.redirect(new URL("/admin", req.url));
  }

  return NextResponse.next();
});

export const config = {
  matcher: ["/admin/:path*"],
};
