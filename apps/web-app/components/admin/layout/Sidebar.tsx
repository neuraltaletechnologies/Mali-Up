"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { signOut, useSession } from "next-auth/react";
import {
  LayoutDashboard,
  Users,
  Building2,
  CreditCard,
  Headphones,
  TrendingUp,
  Flag,
  ScrollText,
  Activity,
  Settings,
  LogOut,
  ShieldCheck,
} from "lucide-react";
import type { AdminRole } from "@/types/admin";

interface NavItem {
  href: string;
  label: string;
  icon: React.ElementType;
  roles: AdminRole[] | ["all"];
}

const navItems: NavItem[] = [
  { href: "/admin",              label: "Dashboard",     icon: LayoutDashboard, roles: ["all"] },
  { href: "/admin/users",        label: "Users",         icon: Users,           roles: ["all"] },
  { href: "/admin/businesses",   label: "Businesses",    icon: Building2,       roles: ["all"] },
  { href: "/admin/subscriptions",label: "Subscriptions", icon: CreditCard,      roles: ["ops_manager", "super_admin"] },
  { href: "/admin/support",      label: "Support",       icon: Headphones,      roles: ["all"] },
  { href: "/admin/financial",    label: "Revenue",       icon: TrendingUp,      roles: ["ops_manager", "super_admin"] },
  { href: "/admin/features",     label: "Feature Flags", icon: Flag,            roles: ["developer", "super_admin"] },
  { href: "/admin/audit",        label: "Audit Log",     icon: ScrollText,      roles: ["all"] },
  { href: "/admin/system",       label: "System Health", icon: Activity,        roles: ["developer", "super_admin"] },
  { href: "/admin/config",       label: "Config",        icon: Settings,        roles: ["super_admin"] },
];

const roleLabel: Record<AdminRole, string> = {
  super_admin: "Super Admin",
  ops_manager: "Ops Manager",
  support_agent: "Support",
  developer: "Developer",
};

function canAccess(roles: AdminRole[] | ["all"], userRole: AdminRole): boolean {
  if (roles[0] === "all") return true;
  return (roles as AdminRole[]).includes(userRole);
}

export function Sidebar() {
  const pathname = usePathname();
  const { data: session } = useSession();
  const userRole = (session?.user?.role ?? "support_agent") as AdminRole;

  function isActive(href: string) {
    if (href === "/admin") return pathname === "/admin";
    return pathname.startsWith(href);
  }

  return (
    <aside
      className="fixed left-0 top-0 h-full w-60 flex flex-col z-30"
      style={{ backgroundColor: "#0D1B3E" }}
    >
      {/* Logo */}
      <div className="flex items-center gap-3 px-5 py-5 border-b border-white/10">
        <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-[#FFC107]">
          <ShieldCheck className="h-5 w-5 text-[#0D1B3E]" />
        </div>
        <div>
          <p className="text-white text-sm font-bold leading-tight">Mali Up</p>
          <span className="text-[10px] font-semibold uppercase tracking-widest text-[#1A6E8A] bg-[#1A6E8A]/20 px-1.5 py-0.5 rounded">
            Admin
          </span>
        </div>
      </div>

      {/* Navigation */}
      <nav className="flex-1 overflow-y-auto py-4 px-3 space-y-0.5">
        {navItems.map((item) => {
          if (!canAccess(item.roles, userRole)) return null;
          const active = isActive(item.href);
          const Icon = item.icon;
          return (
            <Link
              key={item.href}
              href={item.href}
              className={`flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm font-medium transition-all ${
                active
                  ? "bg-[#1A6E8A]/20 text-[#1A6E8A] border-l-2 border-[#1A6E8A] pl-[10px]"
                  : "text-white/70 hover:text-white hover:bg-white/5"
              }`}
            >
              <Icon className={`h-4.5 w-4.5 flex-shrink-0 ${active ? "text-[#1A6E8A]" : ""}`} style={{ height: "18px", width: "18px" }} />
              {item.label}
            </Link>
          );
        })}
      </nav>

      {/* User info + sign out */}
      <div className="border-t border-white/10 p-4 space-y-3">
        <div className="flex items-center gap-3">
          <div className="h-8 w-8 rounded-full bg-[#1A6E8A] flex items-center justify-center text-white text-xs font-bold flex-shrink-0">
            {session?.user?.name?.charAt(0) ?? "A"}
          </div>
          <div className="min-w-0">
            <p className="text-white text-xs font-medium truncate">
              {session?.user?.name ?? "Admin User"}
            </p>
            <p className="text-white/50 text-[11px] truncate">
              {roleLabel[userRole]}
            </p>
          </div>
        </div>
        <button
          onClick={() => signOut({ callbackUrl: "/admin/login" })}
          className="flex w-full items-center gap-2 px-3 py-2 text-white/60 hover:text-white hover:bg-white/5 rounded-lg text-sm transition-colors"
        >
          <LogOut className="h-4 w-4" />
          Sign out
        </button>
      </div>
    </aside>
  );
}
