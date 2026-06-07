import axios from "axios";
import type {
  PlatformUser,
  Business,
  Subscription,
  AuditLog,
  PlatformKPIs,
  ServiceHealth,
  ActivityEvent,
  SupportTicket,
  FeatureFlag,
  RevenueDataPoint,
} from "@/types/admin";
import * as mock from "./admin-mock-data";

const USE_MOCK = process.env.NEXT_PUBLIC_USE_MOCK === "true";

const api = axios.create({
  baseURL: process.env.NEXT_PUBLIC_ADMIN_API_URL ?? "http://localhost:3010",
  timeout: 15000,
});

function delay(ms: number) {
  return new Promise((r) => setTimeout(r, ms));
}

// KPIs
export async function fetchKPIs(): Promise<PlatformKPIs> {
  if (USE_MOCK) { await delay(400); return mock.mockKPIs; }
  const { data } = await api.get<PlatformKPIs>("/admin/kpis");
  return data;
}

export async function fetchRevenueData(): Promise<RevenueDataPoint[]> {
  if (USE_MOCK) { await delay(300); return mock.mockRevenueData; }
  const { data } = await api.get<RevenueDataPoint[]>("/admin/revenue");
  return data;
}

export async function fetchActivity(): Promise<ActivityEvent[]> {
  if (USE_MOCK) { await delay(200); return mock.mockActivity; }
  const { data } = await api.get<ActivityEvent[]>("/admin/activity");
  return data;
}

// Users
export async function fetchUsers(): Promise<PlatformUser[]> {
  if (USE_MOCK) { await delay(300); return mock.mockUsers; }
  const { data } = await api.get<PlatformUser[]>("/admin/users");
  return data;
}

export async function fetchUser(userId: string): Promise<PlatformUser> {
  if (USE_MOCK) {
    await delay(200);
    const user = mock.mockUsers.find((u) => u.userId === userId);
    if (!user) throw new Error("User not found");
    return user;
  }
  const { data } = await api.get<PlatformUser>(`/admin/users/${userId}`);
  return data;
}

export async function suspendUser(userId: string, reason: string): Promise<void> {
  if (USE_MOCK) { await delay(500); return; }
  await api.post(`/admin/users/${userId}/suspend`, { reason });
}

export async function reinstateUser(userId: string): Promise<void> {
  if (USE_MOCK) { await delay(500); return; }
  await api.post(`/admin/users/${userId}/reinstate`);
}

export async function deleteUser(userId: string, reason: string): Promise<void> {
  if (USE_MOCK) { await delay(500); return; }
  await api.delete(`/admin/users/${userId}`, { data: { reason } });
}

// Businesses
export async function fetchBusinesses(): Promise<Business[]> {
  if (USE_MOCK) { await delay(300); return mock.mockBusinesses; }
  const { data } = await api.get<Business[]>("/admin/businesses");
  return data;
}

export async function fetchBusiness(bizId: string): Promise<Business> {
  if (USE_MOCK) {
    await delay(200);
    const biz = mock.mockBusinesses.find((b) => b.bizId === bizId);
    if (!biz) throw new Error("Business not found");
    return biz;
  }
  const { data } = await api.get<Business>(`/admin/businesses/${bizId}`);
  return data;
}

// Subscriptions
export async function fetchSubscriptions(): Promise<Subscription[]> {
  if (USE_MOCK) { await delay(300); return mock.mockSubscriptions; }
  const { data } = await api.get<Subscription[]>("/admin/subscriptions");
  return data;
}

export async function upgradePlan(subscriptionId: string, planTier: string, reason: string): Promise<void> {
  if (USE_MOCK) { await delay(500); return; }
  await api.post(`/admin/subscriptions/${subscriptionId}/upgrade`, { planTier, reason });
}

export async function extendTrial(subscriptionId: string, days: number, reason: string): Promise<void> {
  if (USE_MOCK) { await delay(500); return; }
  await api.post(`/admin/subscriptions/${subscriptionId}/extend-trial`, { days, reason });
}

export async function markPaymentReceived(subscriptionId: string, amount: number, reason: string): Promise<void> {
  if (USE_MOCK) { await delay(500); return; }
  await api.post(`/admin/subscriptions/${subscriptionId}/mark-paid`, { amount, reason });
}

// Audit
export async function fetchAuditLogs(): Promise<AuditLog[]> {
  if (USE_MOCK) { await delay(300); return mock.mockAuditLogs; }
  const { data } = await api.get<AuditLog[]>("/admin/audit");
  return data;
}

// System
export async function fetchServiceHealth(): Promise<ServiceHealth[]> {
  if (USE_MOCK) { await delay(200); return mock.mockServiceHealth; }
  const { data } = await api.get<ServiceHealth[]>("/admin/system/health");
  return data;
}

// Support
export async function fetchSupportTickets(): Promise<SupportTicket[]> {
  if (USE_MOCK) { await delay(300); return mock.mockSupportTickets; }
  const { data } = await api.get<SupportTicket[]>("/admin/support");
  return data;
}

// Feature flags
export async function fetchFeatureFlags(): Promise<FeatureFlag[]> {
  if (USE_MOCK) { await delay(200); return mock.mockFeatureFlags; }
  const { data } = await api.get<FeatureFlag[]>("/admin/features");
  return data;
}

export async function updateFeatureFlag(flagId: string, updates: Partial<FeatureFlag>): Promise<void> {
  if (USE_MOCK) { await delay(400); return; }
  await api.patch(`/admin/features/${flagId}`, updates);
}
