import NextAuth from "next-auth";
import Credentials from "next-auth/providers/credentials";
import type { AdminRole } from "@/types/admin";

export const { handlers, auth, signIn, signOut } = NextAuth({
  providers: [
    Credentials({
      credentials: {
        email: { label: "Email", type: "email" },
        password: { label: "Password", type: "password" },
      },
      authorize: async (credentials) => {
        if (!credentials?.email || !credentials?.password) return null;

        // In development with mock mode, accept any credentials
        if (process.env.NEXT_PUBLIC_USE_MOCK === "true") {
          const mockRoleMap: Record<string, AdminRole> = {
            "super@neuraltale.com": "super_admin",
            "ops@neuraltale.com": "ops_manager",
            "support@neuraltale.com": "support_agent",
            "dev@neuraltale.com": "developer",
          };
          const email = credentials.email as string;
          const role = mockRoleMap[email] ?? "support_agent";
          return {
            id: "mock-admin-001",
            adminId: "mock-admin-001",
            name: "Admin User",
            email,
            role,
          };
        }

        try {
          const res = await fetch(`${process.env.ADMIN_API_URL}/auth/login`, {
            method: "POST",
            body: JSON.stringify(credentials),
            headers: { "Content-Type": "application/json" },
          });
          if (!res.ok) return null;
          return res.json();
        } catch {
          return null;
        }
      },
    }),
  ],
  callbacks: {
    jwt({ token, user }) {
      if (user) {
        token.role = (user as { role: AdminRole }).role;
        token.adminId = (user as { adminId: string }).adminId ?? user.id ?? "";
        token.accessToken = (user as { accessToken?: string }).accessToken;
      }
      return token;
    },
    session({ session, token }) {
      session.user.role = token.role as AdminRole;
      session.user.adminId = token.adminId as string;
      session.accessToken = token.accessToken as string | undefined;
      return session;
    },
  },
  pages: { signIn: "/admin/login" },
  session: { strategy: "jwt" },
  trustHost: true,
});
