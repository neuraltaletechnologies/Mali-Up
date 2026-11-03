// Browser-only client for the public /pay checkout — the website equivalent
// of the mobile app's onboarding + upgrade-sheet flow, talking to the same
// Firebase project, the same Cloud Functions and the same Firestore rules.
// Nothing here is trusted: plan activation still happens only in
// functions/src/clickpesa.ts after ClickPesa confirms the charge.

import { initializeApp, getApps, getApp, type FirebaseApp } from 'firebase/app'
import {
  getAuth,
  signInWithEmailAndPassword,
  createUserWithEmailAndPassword,
  signOut,
  type Auth,
} from 'firebase/auth'
import {
  getFirestore,
  collection,
  doc,
  getDocs,
  query,
  where,
  limit,
  setDoc,
  onSnapshot,
  serverTimestamp,
  type Firestore,
  type Timestamp,
} from 'firebase/firestore'
import { getFunctions, httpsCallable, type Functions } from 'firebase/functions'
import type { BillingCycle, PaidTier } from './public-plans'

const firebaseConfig = {
  apiKey:            process.env.NEXT_PUBLIC_FIREBASE_API_KEY!,
  authDomain:        process.env.NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN!,
  projectId:         process.env.NEXT_PUBLIC_FIREBASE_PROJECT_ID ?? 'neuraltale-mali-up',
  storageBucket:     process.env.NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET!,
  messagingSenderId: process.env.NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID!,
  appId:             process.env.NEXT_PUBLIC_FIREBASE_APP_ID!,
}

// A separate named app so a customer signing in here never replaces an
// admin's Firebase session on the same origin (lib/firebase-client.ts uses
// the default app for the admin portal login).
const APP_NAME = 'maliup-pay'

function app(): FirebaseApp {
  if (typeof window === 'undefined') {
    throw new Error('The pay client must only be used in the browser.')
  }
  return getApps().some((a) => a.name === APP_NAME)
    ? getApp(APP_NAME)
    : initializeApp(firebaseConfig, APP_NAME)
}

const auth = (): Auth => getAuth(app())
const db = (): Firestore => getFirestore(app())
const fns = (): Functions => getFunctions(app(), 'us-central1')

// ─── Phone helpers — mirror PhoneNumberUtils in the mobile app ───────────────

/** Canonical digits-only number, Tanzania assumed when no country code. */
export function canonicalPhone(input: string): string {
  let digits = input.replace(/\D/g, '')
  if (digits.startsWith('00')) digits = digits.slice(2)
  if (digits.startsWith('0')) return `255${digits.slice(1)}`
  if (digits.length === 9) return `255${digits}`
  return digits
}

/** True for a Tanzanian mobile number ClickPesa can push to (06x/07x). */
export function isTzMobile(input: string): boolean {
  return /^255[67]\d{8}$/.test(canonicalPhone(input))
}

/** Exact values older app versions may have stored (see lookupVariants). */
function lookupVariants(input: string): string[] {
  const raw = input.replace(/\D/g, '')
  const canonical = canonicalPhone(input)
  const variants = new Set<string>([canonical, `+${canonical}`, raw, `+${raw}`])
  if (canonical.startsWith('255') && canonical.length > 8) {
    const local = canonical.slice(3)
    variants.add(local)
    variants.add(`0${local}`)
  }
  return [...variants].filter((v) => v && v !== '+')
}

const authEmail = (phone: string) => `${canonicalPhone(phone)}@mali.up`

// ─── PIN → Firebase Auth password (pin_auth_password.dart, v2) ───────────────

const PEPPER = 'Mali Up::Auth::v2::2026::9f3a7c1e2b6d4f81'

async function passwordFromPin(phone: string, pin: string): Promise<string> {
  const enc = new TextEncoder()
  const key = await crypto.subtle.importKey(
    'raw', enc.encode(PEPPER), { name: 'HMAC', hash: 'SHA-256' }, false, ['sign'],
  )
  const digest = new Uint8Array(
    await crypto.subtle.sign('HMAC', key, enc.encode(`${canonicalPhone(phone)}:${pin}`)),
  )
  let binary = ''
  digest.forEach((b) => { binary += String.fromCharCode(b) })
  const b64url = btoa(binary).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '')
  return `Mu2#${b64url}`
}

// ─── Account lookup ──────────────────────────────────────────────────────────

export interface FoundAccount {
  uid: string
  name: string
  isTeamMember: boolean
  authEmails: string[]
}

/** Pre-auth lookup of an account by phone (allowed by isLimitedLookup). */
export async function findAccount(phone: string): Promise<FoundAccount | null> {
  const variants = lookupVariants(phone)
  for (const field of ['phone', 'phoneNumber']) {
    for (const v of variants) {
      const snap = await getDocs(query(collection(db(), 'users'), where(field, '==', v), limit(1)))
      const hit = snap.docs[0]
      if (!hit) continue
      const d = hit.data()
      const emails = ['authEmail', 'email', 'recoveryEmail']
        .map((f) => (typeof d[f] === 'string' ? (d[f] as string).trim().toLowerCase() : ''))
        .filter(Boolean)
      return {
        uid: hit.id,
        name: (d.name as string) || '',
        isTeamMember: d.isTeamMember === true,
        authEmails: emails,
      }
    }
  }
  return null
}

/** Signs in with phone + PIN exactly like OnboardingRepository.loginWithPin. */
export async function loginWithPin(phone: string, pin: string, account: FoundAccount | null): Promise<string> {
  const password = await passwordFromPin(phone, pin)
  const candidates = [...new Set([authEmail(phone), ...(account?.authEmails ?? [])])]
  let lastError: unknown
  for (const email of candidates) {
    try {
      const cred = await signInWithEmailAndPassword(auth(), email, password)
      return cred.user.uid
    } catch (e) {
      lastError = e
      const code = (e as { code?: string }).code ?? ''
      if (!['auth/user-not-found', 'auth/invalid-credential', 'auth/wrong-password', 'auth/invalid-login-credentials'].includes(code)) {
        throw e
      }
    }
  }
  throw lastError
}

export async function logout(): Promise<void> {
  try { await signOut(auth()) } catch { /* nothing to sign out of */ }
}

// ─── New account (mirrors the app's OTP → account → profile chain) ───────────

export async function sendOtp(phone: string): Promise<string> {
  const res = await httpsCallable<{ phone: string }, { pinId: string }>(fns(), 'sendBeemOtp')({
    phone: canonicalPhone(phone),
  })
  return res.data.pinId
}

export async function verifyOtp(phone: string, pinId: string, code: string): Promise<boolean> {
  const res = await httpsCallable<{ phone: string; pinId: string; pin: string }, { verified: boolean }>(
    fns(), 'verifyBeemOtp',
  )({ phone: canonicalPhone(phone), pinId, pin: code })
  return res.data.verified === true
}

export interface NewAccountInput {
  phone: string
  pin: string
  fullName: string
  businessName: string
  businessType: string
}

/**
 * Creates the Firebase Auth account plus users/{uid} and businesses/{id},
 * field-for-field compatible with OnboardingRepository.saveUser /
 * saveBusinessProfile so the owner can later sign into the app with the
 * same phone + PIN and land on this business. Returns the new business id.
 */
export async function createAccount(input: NewAccountInput): Promise<{ uid: string; businessId: string }> {
  const phone = canonicalPhone(input.phone)
  const email = authEmail(phone)
  const password = await passwordFromPin(phone, input.pin)

  // Burns the OTP marker (and heals an orphaned auth account for this phone
  // by resetting its password to this PIN), exactly like the app does.
  let accountExisted = false
  try {
    const res = await httpsCallable<{ phone: string; newPassword: string }, { accountExisted: boolean }>(
      fns(), 'consumeOtpVerification',
    )({ phone, newPassword: password })
    accountExisted = res.data.accountExisted === true
  } catch (e) {
    // No marker left: an earlier attempt already consumed it — fall through
    // to sign-in below, which only succeeds if that attempt made the account.
    if ((e as { code?: string }).code !== 'functions/failed-precondition') throw e
    accountExisted = true
  }

  let uid: string
  if (accountExisted) {
    uid = (await signInWithEmailAndPassword(auth(), email, password)).user.uid
  } else {
    try {
      uid = (await createUserWithEmailAndPassword(auth(), email, password)).user.uid
    } catch (e) {
      if ((e as { code?: string }).code !== 'auth/email-already-in-use') throw e
      uid = (await signInWithEmailAndPassword(auth(), email, password)).user.uid
    }
  }

  // Retry after a partial earlier attempt: don't create a second business.
  const existing = await listOwnedBusinesses(uid)
  if (existing.length > 0) return { uid, businessId: existing[0].id }

  const fullName = input.fullName.trim()
  const parts = fullName.split(/\s+/)
  const bizRef = doc(collection(db(), 'businesses'))
  await setDoc(bizRef, {
    ownerUid: uid,
    ownerName: fullName,
    ownerPhone: phone,
    businessName: input.businessName.trim(),
    businessCategory: input.businessType,
    country: 'Tanzania',
    plan: 'Trial',
    isActive: true,
    staffCount: 0,
    signupSource: 'website',
    createdAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
  })
  await setDoc(doc(db(), 'users', uid), {
    phone,
    authEmail: email,
    name: fullName,
    firstName: parts[0] ?? '',
    lastName: parts.slice(1).join(' '),
    email: '',
    language: 'sw',
    isTeamMember: false,
    selectedBusinessId: bizRef.id,
    phoneVerified: true,
    signupSource: 'website',
    createdAt: serverTimestamp(),
    lastActiveAt: serverTimestamp(),
  })
  return { uid, businessId: bizRef.id }
}

// ─── Businesses ──────────────────────────────────────────────────────────────

export interface OwnedBusiness {
  id: string
  name: string
  plan: string
  planExpiresAt: Date | null
}

export async function listOwnedBusinesses(uid: string): Promise<OwnedBusiness[]> {
  const snap = await getDocs(
    query(collection(db(), 'businesses'), where('ownerUid', '==', uid), limit(20)),
  )
  return snap.docs
    .map((d) => {
      const data = d.data()
      const exp = data.planExpiresAt as Timestamp | undefined
      return {
        id: d.id,
        name: (data.businessName as string) || 'Biashara',
        plan: ((data.plan as string) || '').toLowerCase(),
        planExpiresAt: exp && typeof exp.toDate === 'function' ? exp.toDate() : null,
      }
    })
    .sort((a, b) => a.name.localeCompare(b.name))
}

// ─── Payment ─────────────────────────────────────────────────────────────────

export async function startPayment(args: {
  tier: PaidTier
  billingCycle: BillingCycle
  businessId: string
  phoneNumber: string
}): Promise<string> {
  const res = await httpsCallable<typeof args, { orderReference: string }>(
    fns(), 'initiateClickPesaPayment',
  )({ ...args, phoneNumber: canonicalPhone(args.phoneNumber) })
  return res.data.orderReference
}

export type PaymentOutcome =
  | { status: 'completed'; planExpiresAt: string | null }
  | { status: 'failed' }
  | { status: 'timeout' }

/**
 * Waits for a payment to resolve: watches clickpesa_payments/{ref} (written
 * by the webhook — instant, free) and falls back to a sparse
 * verifyClickPesaPayment poll in case the webhook delivery is lost. Same
 * strategy as ClickPesaService.waitForPayment in the app.
 */
export function waitForPayment(orderReference: string, timeoutMs = 3 * 60_000): Promise<PaymentOutcome> {
  return new Promise((resolve) => {
    let done = false
    const finish = (o: PaymentOutcome) => {
      if (done) return
      done = true
      unsub()
      clearInterval(poll)
      clearTimeout(timer)
      resolve(o)
    }
    const handle = (data: { status?: string; planExpiresAt?: string } | undefined) => {
      if (data?.status === 'completed') finish({ status: 'completed', planExpiresAt: data.planExpiresAt ?? null })
      else if (data?.status === 'failed') finish({ status: 'failed' })
    }
    const unsub = onSnapshot(
      doc(db(), 'clickpesa_payments', orderReference),
      (snap) => handle(snap.data() as { status?: string; planExpiresAt?: string } | undefined),
      () => { /* listener errors fall back to polling */ },
    )
    const verify = httpsCallable<{ orderReference: string }, { status: string; planExpiresAt?: string }>(
      fns(), 'verifyClickPesaPayment',
    )
    const poll = setInterval(async () => {
      try { handle((await verify({ orderReference })).data) } catch { /* keep waiting */ }
    }, 20_000)
    const timer = setTimeout(() => finish({ status: 'timeout' }), timeoutMs)
  })
}

/** Turns a Firebase/Functions error into a short bilingual message. */
export function friendlyError(e: unknown): string {
  const code = (e as { code?: string }).code ?? ''
  const message = (e as { message?: string }).message ?? ''
  if (code === 'functions/resource-exhausted') return 'Majaribio mengi sana. Subiri dakika chache kisha ujaribu tena.'
  if (['auth/invalid-credential', 'auth/wrong-password', 'auth/invalid-login-credentials'].includes(code)) {
    return 'PIN si sahihi. Jaribu tena.'
  }
  if (code === 'auth/too-many-requests') return 'Umejaribu mara nyingi. Subiri kidogo kisha ujaribu tena.'
  if (code === 'auth/network-request-failed' || code === 'functions/unavailable') {
    return 'Hakuna mtandao. Angalia intaneti yako na ujaribu tena.'
  }
  if (code === 'functions/permission-denied') return 'Mmiliki wa biashara pekee ndiye anaweza kulipia kifurushi.'
  if (code === 'functions/failed-precondition' && message.toLowerCase().includes('verif')) {
    return 'Uthibitisho wa namba umeisha muda. Omba msimbo mpya.'
  }
  if (code === 'functions/invalid-argument' && message) return message
  return 'Kuna tatizo limetokea. Tafadhali jaribu tena.'
}
