import type { DefaultSession } from "next-auth";
import type { AdminRole } from "./admin";

declare module "next-auth" {
  interface Session {
    user: {
      role: AdminRole;
      adminId: string;
    } & DefaultSession["user"];
    accessToken?: string;
  }

  interface User {
    role: AdminRole;
    adminId: string;
    accessToken?: string;
  }
}

declare module "next-auth/jwt" {
  interface JWT {
    role: AdminRole;
    adminId: string;
    accessToken?: string;
  }
}
