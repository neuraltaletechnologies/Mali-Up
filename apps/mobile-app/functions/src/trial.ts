import {onDocumentCreated} from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";
import {digitsOnly, sendBeemSms} from "./beem_sms";

/**
 * Reverse trial: every new business starts on a paid tier (Growth by
 * default) for a few days, then falls back to Starter unless it pays.
 *
 * Everything an admin can tune lives in `platform_config/trial`, edited from
 * the admin portal's "Free Trial" page (apps/admin): on/off, length, which
 * tier, and the three messages — the in-app welcome popup (shown by the app
 * itself, see lib/shared/widgets/trial_gift_dialog.dart), the push reminder a
 * few days before the end, and the SMS with payment directions on the end
 * date. Missing fields fall back to DEFAULT_TRIAL_CONFIG below, which the
 * admin portal mirrors.
 *
 * Business-doc fields this module owns (clients cannot write any `plan*`
 * field — see firestore.rules):
 *   plan, planSource: "trial", planStartedAt, planExpiresAt,
 *   subscriptionStatus: "trialing", trialStartedAt, trialEndsAt, trialDays,
 *   trialReminderSentAt, trialExpirySmsStatus / trialExpirySmsSentAt /
 *   trialExpirySmsAttempts / trialExpirySmsError.
 *
 * Expiry itself needs no job: the app already treats a paid tier past
 * `planExpiresAt` as Starter. Paying during the trial goes through
 * clickpesa.ts, which extends from the trial's end date and stamps
 * `planSource: "clickpesa"` — so a paid business is never sent the
 * "your trial ended" SMS.
 */

const REGION = "us-central1";
const DAY_MS = 24 * 60 * 60 * 1000;
// East Africa Time is UTC+3 all year (no DST).
const EAT_OFFSET_MS = 3 * 60 * 60 * 1000;
// No pushes/SMS at night: the hourly sweep only sends between these EAT hours.
const SEND_WINDOW_START_HOUR = 8;
const SEND_WINDOW_END_HOUR = 20;
const MAX_SMS_ATTEMPTS = 3;
// The sweep ignores trials that ended longer ago than this.
const EXPIRY_LOOKBACK_MS = 3 * DAY_MS;

export interface TrialConfig {
  enabled: boolean;
  days: number;
  tier: "growth" | "business";
  reminderDaysBefore: number;
  welcomeTitleSw: string;
  welcomeBodySw: string;
  welcomeTitleEn: string;
  welcomeBodyEn: string;
  reminderTitleSw: string;
  reminderBodySw: string;
  reminderTitleEn: string;
  reminderBodyEn: string;
  expirySms: string;
  payUrl: string;
}

// Placeholders: {name} {businessName} {days} {daysLeft} {endDate}
// {priceMonthly} {priceYearly} {payUrl}. Keep in sync with the admin portal
// (apps/admin/lib/trial-config.ts) and the app (trial_service.dart).
export const DEFAULT_TRIAL_CONFIG: TrialConfig = {
  enabled: true,
  days: 7,
  tier: "growth",
  reminderDaysBefore: 2,
  welcomeTitleSw: "Zawadi yako ya siku {days}! 🎁",
  welcomeBodySw:
    "Hongera {name}! Tumekupa kifurushi cha Growth BURE kwa siku {days}. " +
    "Tumia ripoti kamili, mtiririko wa fedha, madeni na mauzo bila kikomo. " +
    "Kifurushi kitaisha tarehe {endDate} (siku {daysLeft} zimebaki).",
  welcomeTitleEn: "Your {days}-day gift! 🎁",
  welcomeBodyEn:
    "Congratulations {name}! We've gifted you the Growth package FREE for {days} days. " +
    "Enjoy full reports, cash flow, debt tracking and unlimited sales. " +
    "It ends on {endDate} ({daysLeft} days left).",
  reminderTitleSw: "Siku {daysLeft} zimebaki ⏳",
  reminderBodySw:
    "Kifurushi chako cha Growth cha bure kinaisha tarehe {endDate}. " +
    "Lipia sasa ({priceMonthly}/mwezi) uendelee kutumia vipengele vyote.",
  reminderTitleEn: "{daysLeft} days left ⏳",
  reminderBodyEn:
    "Your free Growth package ends on {endDate}. " +
    "Pay now ({priceMonthly}/month) to keep every feature.",
  expirySms:
    "Habari {name}, kifurushi chako cha Growth cha siku {days} kimeisha leo {endDate}. " +
    "Kuendelea: fungua Mali Up > Mipangilio > Mpango > chagua Growth > weka namba ya " +
    "M-Pesa/Mixx/Airtel/Halopesa > thibitisha kwa PIN. Bei {priceMonthly}/mwezi au " +
    "{priceYearly}/mwaka. Au lipia hapa: {payUrl} Msaada: +255653520829",
  payUrl: "https://maliup.neuraltale.com/pay",
};

let cachedConfig: {value: TrialConfig; at: number} | null = null;
const CONFIG_TTL_MS = 60 * 1000;

export async function loadTrialConfig(): Promise<TrialConfig> {
  if (cachedConfig && Date.now() - cachedConfig.at < CONFIG_TTL_MS) return cachedConfig.value;
  let value = DEFAULT_TRIAL_CONFIG;
  try {
    const snap = await admin.firestore().collection("platform_config").doc("trial").get();
    value = mergeConfig(snap.data() ?? {});
  } catch (err) {
    console.error("[Trial] Could not read platform_config/trial, using defaults:", err);
  }
  cachedConfig = {value, at: Date.now()};
  return value;
}

function mergeConfig(raw: FirebaseFirestore.DocumentData): TrialConfig {
  const c: TrialConfig = {...DEFAULT_TRIAL_CONFIG};
  for (const key of Object.keys(DEFAULT_TRIAL_CONFIG) as (keyof TrialConfig)[]) {
    const v = raw[key];
    const def = DEFAULT_TRIAL_CONFIG[key];
    if (typeof def === "string" && typeof v === "string" && v.trim()) {
      (c as unknown as Record<string, unknown>)[key] = v;
    } else if (typeof def === "number" && typeof v === "number" && Number.isFinite(v)) {
      (c as unknown as Record<string, unknown>)[key] = v;
    } else if (typeof def === "boolean" && typeof v === "boolean") {
      (c as unknown as Record<string, unknown>)[key] = v;
    }
  }
  c.days = Math.min(Math.max(Math.round(c.days), 1), 90);
  c.reminderDaysBefore = Math.min(Math.max(Math.round(c.reminderDaysBefore), 1), c.days);
  if (c.tier !== "growth" && c.tier !== "business") c.tier = "growth";
  return c;
}

// ── Formatting ──────────────────────────────────────────────────────────────

/** dd/MM/yyyy in East Africa Time. */
export function formatEatDate(date: Date): string {
  const d = new Date(date.getTime() + EAT_OFFSET_MS);
  const dd = String(d.getUTCDate()).padStart(2, "0");
  const mm = String(d.getUTCMonth() + 1).padStart(2, "0");
  return `${dd}/${mm}/${d.getUTCFullYear()}`;
}

function formatTzs(v: number): string {
  return `TZS ${Math.round(v).toLocaleString("en-US")}`;
}

/** Whole days left, rounded up — 1.2 days left reads as "2". Never negative. */
function daysLeft(endsAt: Date, now: Date): number {
  return Math.max(0, Math.ceil((endsAt.getTime() - now.getTime()) / DAY_MS));
}

export function fillTemplate(template: string, vars: Record<string, string | number>): string {
  return template.replace(/\{\{?\s*(\w+)\s*\}\}?/g, (match, key: string) =>
    key in vars ? String(vars[key]) : match,
  );
}

async function loadPrices(tier: string): Promise<{priceMonthly: number; priceYearly: number}> {
  const fallback = tier === "business" ?
    {priceMonthly: 15000, priceYearly: 150000} :
    {priceMonthly: 6000, priceYearly: 60000};
  try {
    const snap = await admin.firestore().collection("platform_config").doc("plans").get();
    const t = (snap.data()?.[tier] ?? {}) as {priceMonthly?: number; priceYearly?: number};
    return {
      priceMonthly: t.priceMonthly && t.priceMonthly > 0 ? t.priceMonthly : fallback.priceMonthly,
      priceYearly: t.priceYearly && t.priceYearly > 0 ? t.priceYearly : fallback.priceYearly,
    };
  } catch {
    return fallback;
  }
}

// ── Granting ────────────────────────────────────────────────────────────────

/** A plan value that means "free" — what onboarding writes, or nothing. */
function isFreePlanValue(plan: unknown): boolean {
  const p = String(plan ?? "").trim().toLowerCase();
  return p === "" || p === "trial" || p === "starter" || p === "free";
}

// Fallback business caps when platform_config/plans has no maxBusinesses
// (-1 = unlimited). Mirrors _fallbackLimits in plan_service.dart.
const FALLBACK_MAX_BUSINESSES: Record<string, number> = {starter: 1, growth: 1};

function toDate(v: unknown): Date | null {
  if (v instanceof admin.firestore.Timestamp) return v.toDate();
  if (v instanceof Date) return v;
  return null;
}

/** Live plan the owner paid for or an admin granted — trials don't count. */
function isLivePaid(b: FirebaseFirestore.DocumentData, now: Date): boolean {
  if (isFreePlanValue(b.plan) || b.planSource === "trial") return false;
  const expires = toDate(b.planExpiresAt);
  return !expires || expires > now;
}

/**
 * How many businesses this owner may have (-1 = unlimited): the highest
 * maxBusinesses among their live paid businesses, never below 1. Same rule
 * as allowedBusinessCount() in lib/core/services/plan_service.dart — keep
 * them in step.
 */
export function allowedBusinesses(
  businesses: FirebaseFirestore.DocumentData[],
  planDefs: FirebaseFirestore.DocumentData,
  now: Date,
): number {
  let allowed = 1;
  for (const b of businesses) {
    if (!isLivePaid(b, now)) continue;
    const tier = String(b.plan).trim().toLowerCase();
    let max: unknown = planDefs[tier]?.maxBusinesses;
    if (typeof max !== "number") max = FALLBACK_MAX_BUSINESSES[tier] ?? -1;
    if (tier === "enterprise" && typeof b.enterpriseOverrides?.maxBusinesses === "number") {
      max = b.enterpriseOverrides.maxBusinesses;
    }
    if (max === -1) return -1;
    if ((max as number) > allowed) allowed = max as number;
  }
  return allowed;
}

/**
 * Starts the trial on a newly created business. Every new business gets one,
 * as long as it fits the owner's business allowance (see allowedBusinesses)
 * and the owner hasn't already used that many trials — so a free account
 * gets exactly one trial, and deleting/re-creating a business can't farm
 * more. Owners on a plan with unlimited businesses get a trial on each.
 */
export const onBusinessCreatedTrial = onDocumentCreated(
  {document: "businesses/{businessId}", region: REGION},
  async (event) => {
    const data = event.data?.data();
    if (!data) return;
    const config = await loadTrialConfig();
    if (!config.enabled) return;
    if (!isFreePlanValue(data.plan) || data.trialStartedAt) return;

    const db = admin.firestore();
    const bizRef = db.collection("businesses").doc(event.params.businessId);
    const ownerUid = String(data.ownerUid ?? "");
    const userRef = ownerUid ? db.collection("users").doc(ownerUid) : null;

    try {
      await db.runTransaction(async (tx) => {
        const biz = await tx.get(bizRef);
        const user = userRef ? await tx.get(userRef) : null;
        const b = biz.data();
        // Re-check on the fresh read: triggers are at-least-once.
        if (!b || b.trialStartedAt || !isFreePlanValue(b.plan)) return;

        const now = new Date();
        const [owned, plans] = await Promise.all([
          tx.get(db.collection("businesses").where("ownerUid", "==", ownerUid)),
          tx.get(db.collection("platform_config").doc("plans")),
        ]);
        const allowed = allowedBusinesses(owned.docs.map((d) => d.data()), plans.data() ?? {}, now);
        // The new business is already in `owned`.
        if (allowed !== -1 && owned.size > allowed) {
          console.log(`[Trial] ${bizRef.id}: over business allowance (${owned.size}/${allowed}), no trial`);
          return;
        }
        // Pre-counter accounts only have trialUsedAt — that was one trial.
        const u = user?.data();
        const used = Number(u?.trialsGranted) || (u?.trialUsedAt ? 1 : 0);
        if (allowed !== -1 && used >= allowed) {
          console.log(`[Trial] ${bizRef.id}: owner already used ${used}/${allowed} trials`);
          return;
        }

        const endsAt = new Date(now.getTime() + config.days * DAY_MS);
        tx.update(bizRef, trialFields(config, now, endsAt));
        if (userRef && user?.exists) {
          tx.update(userRef, {
            trialUsedAt: admin.firestore.FieldValue.serverTimestamp(),
            trialsGranted: used + 1,
          });
        }
      });
      console.log(`[Trial] Started ${config.days}-day ${config.tier} trial on ${bizRef.id}`);
    } catch (err) {
      console.error(`[Trial] Could not start trial on ${bizRef.id}:`, err);
    }
  },
);

function trialFields(config: TrialConfig, now: Date, endsAt: Date) {
  const endsTs = admin.firestore.Timestamp.fromDate(endsAt);
  return {
    plan: config.tier,
    planSource: "trial",
    subscriptionStatus: "trialing",
    planStartedAt: admin.firestore.FieldValue.serverTimestamp(),
    planExpiresAt: endsTs,
    trialStartedAt: admin.firestore.Timestamp.fromDate(now),
    trialEndsAt: endsTs,
    trialDays: config.days,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  };
}

// ── Lifecycle sweep (reminder push + expiry SMS) ────────────────────────────

function inSendWindow(now: Date): boolean {
  const hour = new Date(now.getTime() + EAT_OFFSET_MS).getUTCHours();
  return hour >= SEND_WINDOW_START_HOUR && hour < SEND_WINDOW_END_HOUR;
}

/** FCM topic names allow only [a-zA-Z0-9-_.~%]. Mirrors PushTopics (Dart). */
const safeTopic = (id: string) => id.replace(/[^a-zA-Z0-9\-_.~%]/g, "_");

interface TrialSweepCounts {
  scanned: number;
  reminders: number;
  sms: number;
  smsFailed: number;
}

/**
 * Called from the hourly processPendingWelcomeSms job (welcome_sms.ts) so it
 * shares that job's Beem secrets and stays within Cloud Scheduler's 3 free
 * jobs. Reads only businesses whose trial ends within the reminder window or
 * ended recently — never the whole collection.
 */
export async function runTrialLifecycle(now = new Date()): Promise<TrialSweepCounts | string> {
  if (!inSendWindow(now)) return "outside send window";
  const config = await loadTrialConfig();
  const db = admin.firestore();

  const from = admin.firestore.Timestamp.fromMillis(now.getTime() - EXPIRY_LOOKBACK_MS);
  const to = admin.firestore.Timestamp.fromMillis(now.getTime() + config.reminderDaysBefore * DAY_MS);
  const snap = await db.collection("businesses")
    .where("trialEndsAt", ">=", from)
    .where("trialEndsAt", "<=", to)
    .get();

  const counts: TrialSweepCounts = {scanned: snap.size, reminders: 0, sms: 0, smsFailed: 0};
  if (snap.empty) return counts;
  const prices = await loadPrices(config.tier);

  for (const doc of snap.docs) {
    const b = doc.data();
    // Paid (clickpesa) or admin-granted since the trial started — nothing to nag about.
    if (b.planSource !== "trial") continue;
    const endsAt = (b.trialEndsAt as FirebaseFirestore.Timestamp).toDate();
    const vars = await templateVars(b, config, prices, endsAt, now);

    if (now < endsAt && !b.trialReminderSentAt) {
      if (await sendReminderPush(doc.id, config, vars)) {
        await doc.ref.update({trialReminderSentAt: admin.firestore.FieldValue.serverTimestamp()});
        counts.reminders++;
      }
    }

    if (now >= endsAt && isExpirySmsCandidate(b)) {
      const outcome = await sendExpirySms(doc.ref, b, config, vars);
      if (outcome === "sent") counts.sms++;
      else if (outcome !== "skipped") counts.smsFailed++;
    }
  }
  return counts;
}

async function templateVars(
  b: FirebaseFirestore.DocumentData,
  config: TrialConfig,
  prices: {priceMonthly: number; priceYearly: number},
  endsAt: Date,
  now: Date,
): Promise<Record<string, string | number>> {
  let name = String(b.ownerName ?? "").trim().split(" ")[0] ?? "";
  if (!name && b.ownerUid) {
    try {
      const u = await admin.firestore().collection("users").doc(String(b.ownerUid)).get();
      name = String(u.data()?.firstName ?? u.data()?.name ?? "").trim().split(" ")[0] ?? "";
    } catch {
      // Name is cosmetic.
    }
  }
  return {
    name: name || "Mteja",
    businessName: String(b.businessName ?? "").trim() || "Biashara yako",
    days: Number(b.trialDays) || config.days,
    daysLeft: daysLeft(endsAt, now),
    endDate: formatEatDate(endsAt),
    priceMonthly: formatTzs(prices.priceMonthly),
    priceYearly: formatTzs(prices.priceYearly),
    payUrl: config.payUrl,
  };
}

async function sendReminderPush(
  businessId: string,
  config: TrialConfig,
  vars: Record<string, string | number>,
): Promise<boolean> {
  const copy = {
    sw: {title: fillTemplate(config.reminderTitleSw, vars), body: fillTemplate(config.reminderBodySw, vars)},
    en: {title: fillTemplate(config.reminderTitleEn, vars), body: fillTemplate(config.reminderBodyEn, vars)},
  };
  const messages: admin.messaging.Message[] = (["sw", "en"] as const).map((lang) => ({
    // Owners only — a payment nag is not for the cashier.
    topic: `biz_${safeTopic(businessId)}_owners_${lang}`,
    notification: copy[lang],
    data: {category: "trial_reminder", route: "/subscription"},
    android: {notification: {channelId: "mali_up_alerts"}},
    fcmOptions: {analyticsLabel: "trial_reminder"},
  }));
  try {
    const res = await admin.messaging().sendEach(messages);
    res.responses.forEach((r) => {
      if (!r.success) console.error("[Trial] reminder push failed", businessId, r.error?.code);
    });
    return res.successCount > 0;
  } catch (err) {
    console.error(`[Trial] reminder push failed for ${businessId}:`, err);
    return false;
  }
}

function isExpirySmsCandidate(b: FirebaseFirestore.DocumentData): boolean {
  const s = b.trialExpirySmsStatus;
  return s !== "sent" && s !== "abandoned" && s !== "in_progress";
}

type SmsOutcome = "sent" | "failed" | "abandoned" | "skipped";

async function sendExpirySms(
  ref: FirebaseFirestore.DocumentReference,
  b: FirebaseFirestore.DocumentData,
  config: TrialConfig,
  vars: Record<string, string | number>,
): Promise<SmsOutcome> {
  const db = admin.firestore();
  // Claim first so overlapping sweeps can't double-send.
  try {
    const claimed = await db.runTransaction(async (tx) => {
      const fresh = (await tx.get(ref)).data();
      if (!fresh || fresh.planSource !== "trial" || !isExpirySmsCandidate(fresh)) return false;
      tx.update(ref, {trialExpirySmsStatus: "in_progress"});
      return true;
    });
    if (!claimed) return "skipped";
  } catch (err) {
    console.error(`[Trial] could not claim expiry SMS for ${ref.id}:`, err);
    return "skipped";
  }

  let phone = digitsOnly(b.phone ?? b.businessPhone);
  if (phone.length < 9 && b.ownerUid) {
    const u = await db.collection("users").doc(String(b.ownerUid)).get().catch(() => null);
    phone = digitsOnly(u?.data()?.phone);
  }

  const message = fillTemplate(config.expirySms, vars);
  const result = phone.length >= 9 ?
    await sendBeemSms(phone, message) :
    {success: false, notCovered: true, error: "No owner phone on file"};

  if (result.success) {
    await ref.update({
      trialExpirySmsStatus: "sent",
      trialExpirySmsSentAt: admin.firestore.FieldValue.serverTimestamp(),
      trialExpirySmsPhone: phone,
    });
    return "sent";
  }
  const attempts = (Number(b.trialExpirySmsAttempts) || 0) + 1;
  const status = result.notCovered || attempts >= MAX_SMS_ATTEMPTS ? "abandoned" : "failed";
  await ref.update({
    trialExpirySmsStatus: status,
    trialExpirySmsAttempts: attempts,
    trialExpirySmsError: result.error ?? "Unknown error",
  });
  console.error(`[Trial] expiry SMS ${status} for ${ref.id}: ${result.error}`);
  return status;
}
