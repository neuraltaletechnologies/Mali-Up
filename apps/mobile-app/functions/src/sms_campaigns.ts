import {onSchedule} from "firebase-functions/v2/scheduler";
import {onDocumentCreated} from "firebase-functions/v2/firestore";
import {defineSecret} from "firebase-functions/params";
import * as admin from "firebase-admin";

/**
 * Beem SMS campaign dispatcher — the sending half of the admin console's
 * "Beem SMS" page (apps/admin/app/admin/(dashboard)/sms-campaigns).
 *
 * The admin app only writes campaign docs; all sending happens here.
 * "Send now" campaigns are written with status `queued` and sent at once by
 * the onSmsCampaignCreated trigger. Two more things are checked every 5
 * minutes:
 *
 *  1. Auto campaigns — `beem_sms_auto_campaigns/{id}` rules that fire once a
 *     year on a fixed date/hour in Tanzania time (Christmas 25 Dec, New Year
 *     1 Jan, …). When a rule is due and hasn't run this year, it materialises
 *     a normal `beem_sms_campaigns` doc (status `scheduled`, due now) and
 *     stamps `lastRunYear` in the same transaction so it can't fire twice.
 *  2. Scheduled campaigns — any `beem_sms_campaigns` doc with status
 *     `scheduled` whose `scheduledAtMs` has passed (or `queued`, if the
 *     trigger missed it) is claimed (status →
 *     `sending`, transactionally, so overlapping runs can't double-send),
 *     its audience resolved at send time, and dispatched.
 *  3. Delivery reports — each recipient's Beem result is saved under
 *     `beem_sms_campaigns/{id}/recipients/{phone}`, and checkDeliveryReports
 *     pulls Beem's per-number delivery status into those docs and into the
 *     campaign's delivered/undelivered counts.
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

/** Outcome of handing one recipient to Beem. "Accepted" is not "delivered":
 * the handset result comes later from the delivery-report API. */
interface SendResult {
  recipient: Recipient;
  accepted: boolean;
  requestId: string | null;
  reason: string | null;
}

async function postBeem(
  senderId: string,
  message: string,
  phones: string[],
): Promise<{requestId: string | null; error: string | null}> {
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
    const text = await res.text();
    if (!res.ok) return {requestId: null, error: `Beem HTTP ${res.status}: ${text}`};
    // Beem returns { successful, request_id, code, message, valid, invalid, ... }.
    type SendBody = {successful?: boolean; request_id?: string | number; message?: string};
    let body: SendBody & {data?: SendBody} = {};
    try {
      body = JSON.parse(text);
    } catch {
      // Not JSON: treat a 2xx as accepted, just without a request id.
    }
    const b = body.data ?? body;
    if (b.successful === false) return {requestId: null, error: `Beem rejected: ${b.message ?? text}`};
    const id = b.request_id;
    return {requestId: id === undefined || id === null ? null : String(id), error: null};
  } catch (err) {
    return {requestId: null, error: err instanceof Error ? err.message : String(err)};
  }
}

async function sendToRecipients(
  recipients: Recipient[],
  message: string,
  senderId: string,
): Promise<SendResult[]> {
  const results: SendResult[] = [];

  if (/\{\{?(name|businessName|phone|appName)\}\}?/i.test(message)) {
    // Personalised: one request per recipient, a few in flight at a time.
    for (let i = 0; i < recipients.length; i += SEND_CONCURRENCY) {
      const chunk = recipients.slice(i, i + SEND_CONCURRENCY);
      const outcomes = await Promise.all(
        chunk.map((r) => postBeem(senderId, personalize(message, r), [r.phone])),
      );
      outcomes.forEach((o, j) => results.push({
        recipient: chunk[j],
        accepted: o.error === null,
        requestId: o.requestId,
        reason: o.error,
      }));
    }
  } else {
    // Same text for everyone: up to 500 numbers share one request_id.
    for (let i = 0; i < recipients.length; i += 500) {
      const chunk = recipients.slice(i, i + 500);
      const o = await postBeem(senderId, message, chunk.map((r) => r.phone));
      chunk.forEach((r) => results.push({
        recipient: r,
        accepted: o.error === null,
        requestId: o.requestId,
        reason: o.error,
      }));
    }
  }

  return results;
}

/**
 * One doc per recipient under the campaign (id = phone), so the admin console
 * can list who got it and resend to whoever didn't. Written 500 per batch.
 */
async function writeRecipientResults(
  campaignRef: FirebaseFirestore.DocumentReference,
  results: SendResult[],
): Promise<void> {
  const db = admin.firestore();
  const now = admin.firestore.FieldValue.serverTimestamp();
  for (let i = 0; i < results.length; i += 500) {
    const batch = db.batch();
    for (const r of results.slice(i, i + 500)) {
      batch.set(campaignRef.collection("recipients").doc(r.recipient.phone), {
        phone: r.recipient.phone,
        name: r.recipient.name,
        businessName: r.recipient.businessName,
        status: r.accepted ? "accepted" : "failed",
        requestId: r.requestId,
        reason: r.reason,
        dlrStatus: r.accepted ? "PENDING" : null,
        sentAt: now,
        dlrCheckedAt: null,
      });
    }
    await batch.commit();
  }
}

// ─── Delivery reports ────────────────────────────────────────────────────────
// Beem sends no delivery callback for local SMS. Delivery is pulled per
// number with GET /public/v1/delivery-reports?dest_addr=&request_id=, at least
// 5 minutes after sending. Driven by the 5-minute schedule below: first check
// after DLR_FIRST_CHECK_MS, then every DLR_RETRY_MS, until nothing is PENDING
// or DLR_MAX_ATTEMPTS is reached (anything still PENDING then stays PENDING).

const BEEM_DLR_URL = "https://dlrapi.beem.africa/public/v1/delivery-reports";
const DLR_FIRST_CHECK_MS = 5 * 60 * 1000;
const DLR_RETRY_MS = 10 * 60 * 1000;
const DLR_MAX_ATTEMPTS = 6;
// Keeps one scheduled run well inside its timeout; the rest wait for the next run.
const DLR_MAX_LOOKUPS_PER_RUN = 1500;

type DlrStatus = "PENDING" | "DELIVERED" | "UNDELIVERED";

async function fetchDlr(phone: string, requestId: string): Promise<DlrStatus | null> {
  try {
    const qs = `dest_addr=${encodeURIComponent(phone)}&request_id=${encodeURIComponent(requestId)}`;
    const res = await fetch(`${BEEM_DLR_URL}?${qs}`, {headers: {"Authorization": beemAuthHeader()}});
    if (!res.ok) return null;
    const body = (await res.json()) as unknown;
    const rows = (Array.isArray(body) ? body : (body as {data?: unknown[]})?.data ?? [body]) as
      {dest_addr?: string; status?: string}[];
    const row = rows.find((x) => normalizePhone(x?.dest_addr) === phone) ?? rows[0];
    const status = String(row?.status ?? "").toUpperCase();
    return status === "DELIVERED" || status === "UNDELIVERED" || status === "PENDING" ? status : null;
  } catch {
    return null;
  }
}

/** Pulls delivery reports for every campaign whose check is due. Returns lookups made. */
async function checkDeliveryReports(now: number): Promise<number> {
  const db = admin.firestore();
  const snap = await db.collection("beem_sms_campaigns").where("dlrState", "==", "pending").get();
  let lookups = 0;

  for (const doc of snap.docs) {
    const c = doc.data();
    if (typeof c.dlrNextCheckMs === "number" && c.dlrNextCheckMs > now) continue;
    if (lookups >= DLR_MAX_LOOKUPS_PER_RUN) break;

    const recSnap = await doc.ref.collection("recipients").where("status", "==", "accepted").get();
    const due = recSnap.docs.filter((r) => {
      const d = r.data();
      return d.dlrStatus !== "DELIVERED" && d.dlrStatus !== "UNDELIVERED" && d.requestId;
    }).slice(0, DLR_MAX_LOOKUPS_PER_RUN - lookups);

    const updates: {ref: FirebaseFirestore.DocumentReference; status: DlrStatus}[] = [];
    for (let i = 0; i < due.length; i += SEND_CONCURRENCY) {
      const chunk = due.slice(i, i + SEND_CONCURRENCY);
      const statuses = await Promise.all(
        chunk.map((r) => fetchDlr(String(r.data().phone), String(r.data().requestId))),
      );
      statuses.forEach((status, j) => {
        if (status && status !== chunk[j].data().dlrStatus) updates.push({ref: chunk[j].ref, status});
      });
    }
    lookups += due.length;

    for (let i = 0; i < updates.length; i += 500) {
      const batch = db.batch();
      for (const u of updates.slice(i, i + 500)) {
        batch.update(u.ref, {dlrStatus: u.status, dlrCheckedAt: admin.firestore.FieldValue.serverTimestamp()});
      }
      await batch.commit();
    }

    // Recount from the docs just read plus the updates just written.
    const latest = new Map(updates.map((u) => [u.ref.id, u.status]));
    let delivered = 0;
    let undelivered = 0;
    let pending = 0;
    for (const r of recSnap.docs) {
      const status = latest.get(r.id) ?? r.data().dlrStatus;
      if (status === "DELIVERED") delivered++;
      else if (status === "UNDELIVERED") undelivered++;
      else pending++;
    }

    const attempts = (Number(c.dlrAttempts) || 0) + 1;
    const finished = pending === 0 || attempts >= DLR_MAX_ATTEMPTS;
    await doc.ref.update({
      deliveredCount: delivered,
      undeliveredCount: undelivered,
      dlrPendingCount: pending,
      dlrAttempts: attempts,
      dlrState: finished ? "done" : "pending",
      dlrNextCheckMs: finished ? null : now + DLR_RETRY_MS,
      dlrCheckedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  }
  return lookups;
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

/** Statuses a sender may claim: `queued` (Send now) and `scheduled` (due later). */
const CLAIMABLE = ["queued", "scheduled"];

/**
 * Claims one campaign (status → `sending`, transactionally so the create
 * trigger and the 5-minute sweep can't both send it), resolves its audience
 * and dispatches it. Returns true when this call did the sending.
 */
async function claimAndDispatch(ref: FirebaseFirestore.DocumentReference): Promise<boolean> {
  const db = admin.firestore();
  const data = await db.runTransaction(async (tx) => {
    const fresh = await tx.get(ref);
    const d = fresh.data();
    if (!d || !CLAIMABLE.includes(d.status)) return null;
    tx.update(ref, {status: "sending", sendingStartedAt: admin.firestore.FieldValue.serverTimestamp()});
    return d;
  });
  if (!data) return false;

  try {
    const recipients = await resolveRecipients((data.audience as Audience) || {kind: "all"});
    const message = String(data.message || "");
    if (recipients.length === 0 || !message) {
      await ref.update({
        status: "failed",
        targetCount: recipients.length,
        sentAt: admin.firestore.FieldValue.serverTimestamp(),
        failedRecipients: [{phone: "-", reason: recipients.length === 0 ? "No recipients" : "Empty message"}],
      });
      return true;
    }

    const senderId = String(data.senderId || process.env.BEEM_SMS_SENDER_ID || "Mali Up");
    const results = await sendToRecipients(recipients, message, senderId);
    const sent = results.filter((r) => r.accepted).length;
    const failed = results
      .filter((r) => !r.accepted)
      .map((r) => ({phone: r.recipient.phone, reason: r.reason ?? "Unknown error"}));
    // Written before the campaign update, so the console never shows a
    // finished campaign whose recipient list is still missing.
    await writeRecipientResults(ref, results);
    const parts = Math.max(1, Number(data.smsPartsCount) || 1);
    await ref.update({
      status: sent === recipients.length ? "sent" : sent > 0 ? "partially_failed" : "failed",
      targetCount: recipients.length,
      estimatedCredits: recipients.length * parts,
      sentCount: sent,
      failedCount: failed.length,
      sentAt: admin.firestore.FieldValue.serverTimestamp(),
      failedRecipients: failed.slice(0, 50),
      recipientsTracked: true,
      deliveredCount: 0,
      undeliveredCount: 0,
      dlrPendingCount: sent,
      dlrAttempts: 0,
      dlrState: sent > 0 ? "pending" : "none",
      dlrNextCheckMs: sent > 0 ? Date.now() + DLR_FIRST_CHECK_MS : null,
    });
  } catch (err) {
    console.error("[SmsCampaigns] dispatch failed", ref.id, err);
    await ref.update({
      status: "failed",
      sentAt: admin.firestore.FieldValue.serverTimestamp(),
      failedRecipients: [{phone: "-", reason: err instanceof Error ? err.message : String(err)}],
    });
  }
  return true;
}

async function dispatchDueCampaigns(now: number): Promise<number> {
  const db = admin.firestore();
  const snap = await db.collection("beem_sms_campaigns").where("status", "in", CLAIMABLE).get();
  let dispatched = 0;

  for (const doc of snap.docs) {
    const d = doc.data();
    // `queued` campaigns are due immediately; the create trigger normally
    // sends them first, so this only catches ones it missed.
    const due = d.status === "queued" ? now : dueAtMs(d);
    if (due === null || due > now) continue;
    if (await claimAndDispatch(doc.ref)) dispatched++;
  }
  return dispatched;
}

/**
 * Sends "Send now" campaigns the moment the admin app writes them. The admin
 * app runs on a Cloudflare Worker, whose per-request subrequest and time
 * limits can't cover one Beem call per personalised recipient, so it only
 * queues the campaign and this does the sending.
 */
export const onSmsCampaignCreated = onDocumentCreated(
  {
    document: "beem_sms_campaigns/{campaignId}",
    region: "us-central1",
    timeoutSeconds: 540,
    secrets: [BEEM_API_KEY, BEEM_SECRET_KEY],
  },
  async (event) => {
    if (event.data?.data()?.status !== "queued") return;
    await claimAndDispatch(event.data.ref);
  },
);

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
    const dlrLookups = await checkDeliveryReports(now);
    if (created || dispatched || dlrLookups) {
      console.log(
        `[SmsCampaigns] auto campaigns created=${created}, campaigns dispatched=${dispatched}, ` +
        `delivery lookups=${dlrLookups}`,
      );
    }
  },
);
