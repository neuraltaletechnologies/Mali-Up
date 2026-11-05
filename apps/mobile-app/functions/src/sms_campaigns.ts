import {onSchedule} from "firebase-functions/v2/scheduler";
import {defineSecret} from "firebase-functions/params";
import * as admin from "firebase-admin";

/**
 * Beem SMS campaign dispatcher — the sending half of the admin console's
 * "Beem SMS" page (apps/admin/app/admin/(dashboard)/sms-campaigns).
 *
 * The admin app sends "Send now" campaigns itself, but it has no background
 * runner, so two things live here instead, checked every 5 minutes:
 *
 *  1. Auto campaigns — `beem_sms_auto_campaigns/{id}` rules that fire once a
 *     year on a fixed date/hour in Tanzania time (Christmas 25 Dec, New Year
 *     1 Jan, …). When a rule is due and hasn't run this year, it materialises
 *     a normal `beem_sms_campaigns` doc (status `scheduled`, due now) and
 *     stamps `lastRunYear` in the same transaction so it can't fire twice.
 *  2. Scheduled campaigns — any `beem_sms_campaigns` doc with status
 *     `scheduled` whose `scheduledAtMs` has passed is claimed (status →
 *     `sending`, transactionally, so overlapping runs can't double-send),
 *     its audience resolved at send time, and dispatched.
 *
 * Recipient resolution and personalisation mirror apps/admin/lib/
 * sms-recipients.ts and lib/beem.ts — keep them in step.
 */

const BEEM_API_KEY = defineSecret("BEEM_API_KEY");
const BEEM_SECRET_KEY = defineSecret("BEEM_SECRET_KEY");

const BEEM_SMS_SEND_URL = "https://apisms.beem.africa/v1/send";
const TZ_OFFSET_MS = 3 * 60 * 60 * 1000; // Africa/Dar_es_Salaam, UTC+3, no DST
const SEND_CONCURRENCY = 10;

interface Audience {
  kind: "all" | "business_category" | "plan_tier" | "selected_businesses" | "custom_numbers";
  category?: string;
  planTier?: string;
  businessIds?: string[];
  customNumbers?: string[];
}

interface Recipient {
  phone: string;
  name: string;
  businessName: string;
}

function beemAuthHeader(): string {
  return "Basic " + Buffer.from(`${BEEM_API_KEY.value()}:${BEEM_SECRET_KEY.value()}`).toString("base64");
}

/** Mirrors normalizePhone in apps/admin/lib/beem.ts (and PhoneNumberUtils.canonical in the app). */
function normalizePhone(raw: unknown): string {
  let digits = String(raw ?? "").replace(/\D/g, "");
  if (digits.startsWith("00")) digits = digits.slice(2);
  if (digits.startsWith("0") && digits.length === 10) return "255" + digits.slice(1);
  if (digits.length === 9) return "255" + digits;
  return digits;
}

function validPhone(phone: string): boolean {
  return phone.length >= 9 && phone.length <= 15;
}

/** Mirrors formatPersonalizedMessage in apps/admin/lib/beem.ts. */
function personalize(template: string, r: Recipient): string {
  const name = r.name.trim() || "Mteja";
  const biz = r.businessName.trim() || "Biashara yako";
  return template
    .replace(/\{\{?name\}\}?/gi, name)
    .replace(/\{\{?businessName\}\}?/gi, biz)
    .replace(/\{\{?phone\}\}?/gi, r.phone)
    .replace(/\{appName\}/gi, "Mali Up");
}

// ─── Recipients — mirrors apps/admin/lib/sms-recipients.ts ───────────────────
// users/{uid}: phone, name, firstName, selectedBusinessId (owners) / businessId (staff).
// businesses/{id}: ownerUid, ownerName, businessName, businessCategory, plan — no phone;
// the owner's phone lives on users/{ownerUid}.

const MAX_DOCS = 2000;

type Data = FirebaseFirestore.DocumentData;

interface Directory {
  usersById: Map<string, Data>;
  usersByPhone: Map<string, Data>;
  businessesById: Map<string, Data>;
}

async function loadDirectory(): Promise<Directory> {
  const db = admin.firestore();
  const [usersSnap, bizSnap] = await Promise.all([
    db.collection("users").limit(MAX_DOCS).get(),
    db.collection("businesses").limit(MAX_DOCS).get(),
  ]);
  const usersById = new Map<string, Data>();
  const usersByPhone = new Map<string, Data>();
  for (const doc of usersSnap.docs) {
    const d = doc.data();
    usersById.set(doc.id, d);
    const phone = normalizePhone(d.phone || d.phoneNumber);
    // Prefer the owner account when an owner and a staff record share a phone.
    if (phone && (!usersByPhone.has(phone) || d.isTeamMember !== true)) usersByPhone.set(phone, d);
  }
  const businessesById = new Map<string, Data>();
  for (const doc of bizSnap.docs) businessesById.set(doc.id, doc.data());
  return {usersById, usersByPhone, businessesById};
}

function firstNameOf(...candidates: unknown[]): string {
  for (const c of candidates) {
    const s = typeof c === "string" ? c.trim() : "";
    if (s) return s.split(/\s+/)[0];
  }
  return "Mteja";
}

function businessNameOf(biz: Data | undefined): string {
  return String(biz?.businessName || biz?.name || "").trim();
}

function userRecipient(dir: Directory, user: Data, phone: string): Recipient {
  const bizId = String(user.selectedBusinessId || user.businessId || "");
  return {
    phone,
    name: firstNameOf(user.firstName, user.name),
    businessName: businessNameOf(dir.businessesById.get(bizId)),
  };
}

function businessRecipient(dir: Directory, biz: Data): Recipient | null {
  const owner = dir.usersById.get(String(biz.ownerUid || ""));
  const phone = normalizePhone(biz.ownerPhone || biz.phone || owner?.phone);
  if (!validPhone(phone)) return null;
  return {
    phone,
    name: firstNameOf(owner?.firstName, biz.ownerName, owner?.name),
    businessName: businessNameOf(biz),
  };
}

async function resolveRecipients(audience: Audience): Promise<Recipient[]> {
  const dir = await loadDirectory();
  const byPhone = new Map<string, Recipient>();
  const add = (r: Recipient | null) => {
    if (r && !byPhone.has(r.phone)) byPhone.set(r.phone, r);
  };

  switch (audience.kind) {
  case "custom_numbers":
    for (const raw of audience.customNumbers ?? []) {
      const phone = normalizePhone(raw);
      if (!validPhone(phone)) continue;
      const user = dir.usersByPhone.get(phone);
      add(user ? userRecipient(dir, user, phone) : {phone, name: "Mteja", businessName: ""});
    }
    break;

  case "selected_businesses":
    for (const id of audience.businessIds ?? []) {
      const biz = dir.businessesById.get(id);
      if (biz) add(businessRecipient(dir, biz));
    }
    break;

  case "business_category": {
    const target = (audience.category ?? "").toLowerCase().trim();
    for (const biz of dir.businessesById.values()) {
      const cat = String(biz.businessCategory || biz.category || biz.industry || "").toLowerCase().trim();
      if (cat === target || cat.includes(target)) add(businessRecipient(dir, biz));
    }
    break;
  }

  case "plan_tier": {
    const target = (audience.planTier ?? "").toLowerCase().trim();
    for (const biz of dir.businessesById.values()) {
      if (String(biz.plan || "starter").toLowerCase().trim() === target) add(businessRecipient(dir, biz));
    }
    break;
  }

  default:
    for (const user of dir.usersById.values()) {
      const phone = normalizePhone(user.phone || user.phoneNumber);
      if (validPhone(phone)) add(userRecipient(dir, user, phone));
    }
  }

  return [...byPhone.values()];
}

// ─── Sending ─────────────────────────────────────────────────────────────────

async function postBeem(senderId: string, message: string, phones: string[]): Promise<string | null> {
  try {
    const res = await fetch(BEEM_SMS_SEND_URL, {
      method: "POST",
      headers: {"Authorization": beemAuthHeader(), "Content-Type": "application/json"},
      body: JSON.stringify({
        source_addr: senderId,
        schedule_time: "",
        encoding: 0,
        message,
        recipients: phones.map((dest, i) => ({recipient_id: i + 1, dest_addr: dest})),
      }),
    });
    return res.ok ? null : `Beem HTTP ${res.status}: ${await res.text()}`;
  } catch (err) {
    return err instanceof Error ? err.message : String(err);
  }
}

async function sendToRecipients(
  recipients: Recipient[],
  message: string,
  senderId: string,
): Promise<{sent: number; failed: {phone: string; reason: string}[]}> {
  const failed: {phone: string; reason: string}[] = [];
  let sent = 0;

  if (/\{\{?(name|businessName|phone|appName)\}\}?/i.test(message)) {
    // Personalised — one request per recipient, a few in flight at a time.
    for (let i = 0; i < recipients.length; i += SEND_CONCURRENCY) {
      const chunk = recipients.slice(i, i + SEND_CONCURRENCY);
      const errors = await Promise.all(
        chunk.map((r) => postBeem(senderId, personalize(message, r), [r.phone])),
      );
      errors.forEach((reason, j) => {
        if (reason) failed.push({phone: chunk[j].phone, reason});
        else sent++;
      });
    }
  } else {
    for (let i = 0; i < recipients.length; i += 500) {
      const phones = recipients.slice(i, i + 500).map((r) => r.phone);
      const reason = await postBeem(senderId, message, phones);
      if (reason) phones.forEach((phone) => failed.push({phone, reason}));
      else sent += phones.length;
    }
  }

  return {sent, failed};
}

// ─── Scheduling helpers ──────────────────────────────────────────────────────

/** Legacy docs stored the raw `datetime-local` value ("2026-12-25T09:00",
 * no zone) — the admins are in Tanzania, so read those as EAT. */
function dueAtMs(data: FirebaseFirestore.DocumentData): number | null {
  if (typeof data.scheduledAtMs === "number") return data.scheduledAtMs;
  const raw = data.scheduledAt;
  if (typeof raw !== "string" || !raw) return null;
  const hasZone = /(Z|[+-]\d{2}:?\d{2})$/.test(raw);
  const ms = Date.parse(hasZone ? raw : `${raw.replace(" ", "T")}+03:00`);
  return Number.isNaN(ms) ? null : ms;
}

/** Creates this year's campaign for every auto rule that is due. */
async function materializeAutoCampaigns(now: number): Promise<number> {
  const db = admin.firestore();
  const local = new Date(now + TZ_OFFSET_MS);
  const year = local.getUTCFullYear();
  const month = local.getUTCMonth() + 1;
  const day = local.getUTCDate();
  const hour = local.getUTCHours();

  const rules = await db.collection("beem_sms_auto_campaigns").where("enabled", "==", true).get();
  let created = 0;

  for (const rule of rules.docs) {
    const r = rule.data();
    if (r.month !== month || r.day !== day || hour < (r.hour ?? 9)) continue;
    if (r.lastRunYear === year) continue;

    const fired = await db.runTransaction(async (tx) => {
      const fresh = (await tx.get(rule.ref)).data();
      if (!fresh || fresh.enabled !== true || fresh.lastRunYear === year) return false;
      const campaignRef = db.collection("beem_sms_campaigns").doc();
      tx.set(campaignRef, {
        name: `${fresh.name || "Auto campaign"} ${year}`,
        campaignType: fresh.campaignType || "custom",
        senderId: fresh.senderId || process.env.BEEM_SMS_SENDER_ID || "Mali Up",
        message: fresh.message || "",
        messageSw: null,
        audience: fresh.audience || {kind: "all"},
        status: "scheduled",
        targetCount: 0,
        sentCount: 0,
        failedCount: 0,
        smsPartsCount: 1,
        estimatedCredits: 0,
        scheduledAt: new Date(now).toISOString(),
        scheduledAtMs: now,
        sentAt: null,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        createdByAdminId: "auto",
        createdByAdminName: "Auto campaign",
        autoCampaignId: rule.id,
      });
      tx.update(rule.ref, {
        lastRunYear: year,
        lastRunAt: admin.firestore.FieldValue.serverTimestamp(),
        lastCampaignId: campaignRef.id,
      });
      return true;
    });
    if (fired) created++;
  }
  return created;
}

async function dispatchDueCampaigns(now: number): Promise<number> {
  const db = admin.firestore();
  const snap = await db.collection("beem_sms_campaigns").where("status", "==", "scheduled").get();
  let dispatched = 0;

  for (const doc of snap.docs) {
    const due = dueAtMs(doc.data());
    if (due === null || due > now) continue;

    const claimed = await db.runTransaction(async (tx) => {
      const fresh = await tx.get(doc.ref);
      if (fresh.data()?.status !== "scheduled") return false;
      tx.update(doc.ref, {status: "sending"});
      return true;
    });
    if (!claimed) continue;

    const data = doc.data();
    try {
      const recipients = await resolveRecipients((data.audience as Audience) || {kind: "all"});
      const message = String(data.message || "");
      if (recipients.length === 0 || !message) {
        await doc.ref.update({
          status: "failed",
          targetCount: recipients.length,
          sentAt: admin.firestore.FieldValue.serverTimestamp(),
          failedRecipients: [{phone: "-", reason: recipients.length === 0 ? "No recipients" : "Empty message"}],
        });
        continue;
      }

      const senderId = String(data.senderId || process.env.BEEM_SMS_SENDER_ID || "Mali Up");
      const {sent, failed} = await sendToRecipients(recipients, message, senderId);
      const parts = Math.max(1, Number(data.smsPartsCount) || 1);
      await doc.ref.update({
        status: sent === recipients.length ? "sent" : sent > 0 ? "partially_failed" : "failed",
        targetCount: recipients.length,
        estimatedCredits: recipients.length * parts,
        sentCount: sent,
        failedCount: failed.length,
        sentAt: admin.firestore.FieldValue.serverTimestamp(),
        failedRecipients: failed.slice(0, 50),
      });
      dispatched++;
    } catch (err) {
      console.error("[SmsCampaigns] dispatch failed", doc.id, err);
      await doc.ref.update({
        status: "failed",
        sentAt: admin.firestore.FieldValue.serverTimestamp(),
        failedRecipients: [{phone: "-", reason: err instanceof Error ? err.message : String(err)}],
      });
    }
  }
  return dispatched;
}

export const dispatchSmsCampaigns = onSchedule(
  {
    schedule: "every 5 minutes",
    region: "us-central1",
    timeoutSeconds: 540,
    secrets: [BEEM_API_KEY, BEEM_SECRET_KEY],
  },
  async () => {
    const now = Date.now();
    const created = await materializeAutoCampaigns(now);
    const dispatched = await dispatchDueCampaigns(now);
    if (created || dispatched) {
      console.log(`[SmsCampaigns] auto campaigns created=${created}, campaigns dispatched=${dispatched}`);
    }
  },
);
