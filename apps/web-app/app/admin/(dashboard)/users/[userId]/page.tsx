import { fetchUser, fetchBusinesses } from "@/lib/admin-api";
import { auth } from "@/auth";
import { notFound } from "next/navigation";
import Link from "next/link";
import { ChevronLeft, Smartphone, Calendar, Building2, Mail, Phone } from "lucide-react";
import { PageHeader } from "@/components/admin/layout/PageHeader";
import { StatusBadge } from "@/components/admin/shared/StatusBadge";
import { PlanBadge } from "@/components/admin/shared/PlanBadge";
import { formatDate, formatDateTime, timeAgo, formatPhone } from "@/lib/admin-utils";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";

export const dynamic = "force-dynamic";

export default async function UserDetailPage({
  params,
}: {
  params: Promise<{ userId: string }>;
}) {
  const { userId } = await params;
  const [user, businesses] = await Promise.all([
    fetchUser(userId).catch(() => null),
    fetchBusinesses(),
  ]);

  if (!user) return notFound();

  const userBusinesses = businesses.filter(
    (b) => b.ownerPhone === user.phone || b.bizId === user.defaultBusinessId
  );

  return (
    <div className="max-w-4xl space-y-6">
      <Link
        href="/admin/users"
        className="inline-flex items-center gap-1.5 text-sm text-slate-500 hover:text-slate-700"
      >
        <ChevronLeft className="h-4 w-4" />
        Back to Users
      </Link>

      <div className="flex items-start gap-4">
        <div className="h-14 w-14 rounded-full bg-[#0D1B3E] flex items-center justify-center text-white text-xl font-bold flex-shrink-0">
          {user.name.charAt(0)}
        </div>
        <div className="flex-1">
          <div className="flex items-center gap-3 flex-wrap">
            <h2 className="text-xl font-bold text-slate-900">{user.name}</h2>
            <StatusBadge status={user.status} />
          </div>
          <div className="mt-1 flex items-center gap-4 text-sm text-slate-500 flex-wrap">
            <span className="flex items-center gap-1.5">
              <Phone className="h-3.5 w-3.5" />
              <span className="font-mono">{formatPhone(user.phone)}</span>
            </span>
            {user.email && (
              <span className="flex items-center gap-1.5">
                <Mail className="h-3.5 w-3.5" />
                {user.email}
              </span>
            )}
            <span className="flex items-center gap-1.5">
              <Calendar className="h-3.5 w-3.5" />
              Joined {formatDate(user.createdAt)}
            </span>
          </div>
        </div>
      </div>

      <Tabs defaultValue="overview">
        <TabsList className="bg-slate-100">
          <TabsTrigger value="overview">Overview</TabsTrigger>
          <TabsTrigger value="businesses">Businesses ({userBusinesses.length})</TabsTrigger>
          <TabsTrigger value="activity">Activity</TabsTrigger>
        </TabsList>

        <TabsContent value="overview" className="mt-4">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div className="bg-white rounded-xl border border-slate-200 p-5 space-y-4">
              <h3 className="text-sm font-semibold text-slate-700">Profile</h3>
              <dl className="space-y-3 text-sm">
                <div className="flex justify-between">
                  <dt className="text-slate-500">User ID</dt>
                  <dd className="font-mono text-slate-800">{user.userId}</dd>
                </div>
                <div className="flex justify-between">
                  <dt className="text-slate-500">Status</dt>
                  <dd><StatusBadge status={user.status} /></dd>
                </div>
                <div className="flex justify-between">
                  <dt className="text-slate-500">Businesses</dt>
                  <dd className="font-mono font-semibold">{user.businessCount}</dd>
                </div>
                <div className="flex justify-between">
                  <dt className="text-slate-500">Last login</dt>
                  <dd className="text-slate-700">{timeAgo(user.lastLoginAt)}</dd>
                </div>
                <div className="flex justify-between">
                  <dt className="text-slate-500">Joined</dt>
                  <dd className="text-slate-700">{formatDate(user.createdAt)}</dd>
                </div>
              </dl>
            </div>

            <div className="bg-white rounded-xl border border-slate-200 p-5 space-y-4">
              <h3 className="text-sm font-semibold text-slate-700 flex items-center gap-2">
                <Smartphone className="h-4 w-4" />
                Device
              </h3>
              <dl className="space-y-3 text-sm">
                <div className="flex justify-between">
                  <dt className="text-slate-500">Device</dt>
                  <dd className="text-slate-700 text-right max-w-[60%]">{user.deviceInfo}</dd>
                </div>
                <div className="flex justify-between">
                  <dt className="text-slate-500">Last seen</dt>
                  <dd className="text-slate-700">{formatDateTime(user.lastLoginAt)}</dd>
                </div>
              </dl>
            </div>
          </div>
        </TabsContent>

        <TabsContent value="businesses" className="mt-4">
          {userBusinesses.length === 0 ? (
            <div className="bg-white rounded-xl border border-slate-200 p-10 text-center text-slate-400">
              No businesses linked to this user.
            </div>
          ) : (
            <div className="space-y-3">
              {userBusinesses.map((biz) => (
                <div
                  key={biz.bizId}
                  className="bg-white rounded-xl border border-slate-200 p-4 flex items-center justify-between"
                >
                  <div className="flex items-center gap-3">
                    <div className="h-10 w-10 rounded-lg bg-slate-100 flex items-center justify-center">
                      <Building2 className="h-5 w-5 text-slate-400" />
                    </div>
                    <div>
                      <p className="font-medium text-slate-900">{biz.name}</p>
                      <p className="text-xs text-slate-500">{biz.type} · {biz.location}</p>
                    </div>
                  </div>
                  <div className="flex items-center gap-3">
                    <PlanBadge tier={biz.planTier} />
                    <StatusBadge status={biz.status} />
                    <Link
                      href={`/admin/businesses/${biz.bizId}`}
                      className="text-xs text-[#1A6E8A] hover:underline"
                    >
                      View →
                    </Link>
                  </div>
                </div>
              ))}
            </div>
          )}
        </TabsContent>

        <TabsContent value="activity" className="mt-4">
          <div className="bg-white rounded-xl border border-slate-200 p-10 text-center text-slate-400">
            Activity log requires Admin API connection.
          </div>
        </TabsContent>
      </Tabs>
    </div>
  );
}
