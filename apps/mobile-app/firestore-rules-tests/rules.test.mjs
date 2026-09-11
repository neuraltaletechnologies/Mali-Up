// Firestore security rules tests for the DataScope.own change
// (sales_invoices / expenses / inventory_items own-record read fallback).
//
// Run against the local Firestore emulator — see README.md in this folder.
//
// These intentionally do NOT touch the app's real Firestore project; the
// emulator only ever holds data seeded by this file.

import { test, before, after } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} from '@firebase/rules-unit-testing';
import {
  doc, getDoc, getDocs, collection, query, where,
} from 'firebase/firestore';

const BIZ_ID = 'biz1';
const OWNER_UID = 'owner1';
const MANAGER_UID = 'manager1';  // viewSales + viewFinancialReports + viewInventory
const STAFF_A_UID = 'staffA';    // createSale + manageExpenses only, own-scope
const STAFF_B_UID = 'staffB';    // same shape as staff A, different assigned item
const NO_PERMS_UID = 'noperms1'; // active staff doc, empty permissions

let testEnv;

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: 'demo-mali-up-rules-test',
    firestore: {
      rules: readFileSync('../firestore.rules', 'utf8'),
      host: 'localhost',
      port: 8080,
    },
  });

  // Seed as an admin context — bypasses rules entirely, matching how the
  // app's own writes (owner invites staff, creates sales) would land in
  // Firestore, without needing to satisfy the create-rule validators here.
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();

    await db.doc(`businesses/${BIZ_ID}`).set({ ownerUid: OWNER_UID });

    const staff = (uid, permissions, memberId) =>
      db.doc(`businesses/${BIZ_ID}/staff/${uid}`).set({
        status: 'active',
        permissions,
        // Mirrors the real pointer doc — see onboarding_repository.dart.
        ...(memberId ? { memberId } : {}),
      });
    await staff(MANAGER_UID, ['viewSales', 'viewFinancialReports', 'viewInventory', 'createSale', 'manageExpenses']);
    await staff(STAFF_A_UID, ['createSale', 'manageExpenses'], 'memberRecA');
    await staff(STAFF_B_UID, ['createSale', 'manageExpenses'], 'memberRecB');
    await staff(NO_PERMS_UID, []);

    await db.doc(`businesses/${BIZ_ID}/sales_invoices/inv_a`).set({ createdBy: STAFF_A_UID, total: 1000 });
    await db.doc(`businesses/${BIZ_ID}/sales_invoices/inv_b`).set({ createdBy: STAFF_B_UID, total: 2000 });

    await db.doc(`businesses/${BIZ_ID}/expenses/exp_a`).set({ createdBy: STAFF_A_UID, amount: 50 });
    await db.doc(`businesses/${BIZ_ID}/expenses/exp_b`).set({ createdBy: STAFF_B_UID, amount: 60 });

    await db.doc(`businesses/${BIZ_ID}/inventory_items/item_a`).set({ name: 'Service Item A', assignedToUserId: STAFF_A_UID });
    await db.doc(`businesses/${BIZ_ID}/inventory_items/item_b`).set({ name: 'Service Item B', assignedToUserId: STAFF_B_UID });
    // Assigned to staff A by staff *record id* — i.e. an assignment made
    // before that member accepted their invite and got an Auth UID.
    await db.doc(`businesses/${BIZ_ID}/inventory_items/item_c`).set({ name: 'Service Item C', assignedToUserId: 'memberRecA' });
  });
});

after(async () => {
  await testEnv.cleanup();
});

function firestoreAs(uid) {
  return uid === null
    ? testEnv.unauthenticatedContext().firestore()
    : testEnv.authenticatedContext(uid).firestore();
}

// ── sales_invoices ────────────────────────────────────────────────────────────

test('owner reads any sale in their business', async () => {
  const db = firestoreAs(OWNER_UID);
  await assertSucceeds(getDoc(doc(db, `businesses/${BIZ_ID}/sales_invoices/inv_a`)));
  await assertSucceeds(getDoc(doc(db, `businesses/${BIZ_ID}/sales_invoices/inv_b`)));
});

test('staff with viewSales reads every sale, not just their own', async () => {
  const db = firestoreAs(MANAGER_UID);
  await assertSucceeds(getDoc(doc(db, `businesses/${BIZ_ID}/sales_invoices/inv_a`)));
  await assertSucceeds(getDoc(doc(db, `businesses/${BIZ_ID}/sales_invoices/inv_b`)));
});

test('createSale-only, own-scoped staff reads their own sale', async () => {
  const db = firestoreAs(STAFF_A_UID);
  await assertSucceeds(getDoc(doc(db, `businesses/${BIZ_ID}/sales_invoices/inv_a`)));
});

test('createSale-only, own-scoped staff cannot read another member\'s sale', async () => {
  const db = firestoreAs(STAFF_A_UID);
  await assertFails(getDoc(doc(db, `businesses/${BIZ_ID}/sales_invoices/inv_b`)));
});

test('an unscoped list query is rejected for an own-scoped staff member', async () => {
  const db = firestoreAs(STAFF_A_UID);
  // No where() clause — Firestore can't prove every possible result
  // satisfies the own-record rule, so the whole query is denied.
  await assertFails(getDocs(collection(db, `businesses/${BIZ_ID}/sales_invoices`)));
});

test('a createdBy-scoped list query succeeds and returns only that member\'s own sale', async () => {
  const db = firestoreAs(STAFF_A_UID);
  const q = query(
    collection(db, `businesses/${BIZ_ID}/sales_invoices`),
    where('createdBy', '==', STAFF_A_UID),
  );
  const snap = await assertSucceeds(getDocs(q));
  assert.equal(snap.size, 1);
  assert.equal(snap.docs[0].id, 'inv_a');
});

test('staff with no permissions cannot read any sale', async () => {
  const db = firestoreAs(NO_PERMS_UID);
  await assertFails(getDoc(doc(db, `businesses/${BIZ_ID}/sales_invoices/inv_a`)));
});

test('unauthenticated caller cannot read any sale', async () => {
  const db = firestoreAs(null);
  await assertFails(getDoc(doc(db, `businesses/${BIZ_ID}/sales_invoices/inv_a`)));
});

// ── expenses ──────────────────────────────────────────────────────────────────

test('manageExpenses-only, own-scoped staff reads their own expense but not another member\'s', async () => {
  const db = firestoreAs(STAFF_A_UID);
  await assertSucceeds(getDoc(doc(db, `businesses/${BIZ_ID}/expenses/exp_a`)));
  await assertFails(getDoc(doc(db, `businesses/${BIZ_ID}/expenses/exp_b`)));
});

test('staff with viewFinancialReports reads every expense', async () => {
  const db = firestoreAs(MANAGER_UID);
  await assertSucceeds(getDoc(doc(db, `businesses/${BIZ_ID}/expenses/exp_a`)));
  await assertSucceeds(getDoc(doc(db, `businesses/${BIZ_ID}/expenses/exp_b`)));
});

// ── inventory_items (assignedToUserId, not createdBy) ──────────────────────────

test('own-scoped staff reads only the item assigned to them', async () => {
  const db = firestoreAs(STAFF_A_UID);
  await assertSucceeds(getDoc(doc(db, `businesses/${BIZ_ID}/inventory_items/item_a`)));
  await assertFails(getDoc(doc(db, `businesses/${BIZ_ID}/inventory_items/item_b`)));
});

test('staff with viewInventory reads every item', async () => {
  const db = firestoreAs(MANAGER_UID);
  await assertSucceeds(getDoc(doc(db, `businesses/${BIZ_ID}/inventory_items/item_a`)));
  await assertSucceeds(getDoc(doc(db, `businesses/${BIZ_ID}/inventory_items/item_b`)));
});

test('own-scoped staff reads an item assigned to them by staff record id', async () => {
  const db = firestoreAs(STAFF_A_UID);
  await assertSucceeds(getDoc(doc(db, `businesses/${BIZ_ID}/inventory_items/item_c`)));
});

test('own-scoped staff cannot read an item assigned to another member by record id', async () => {
  const db = firestoreAs(STAFF_B_UID);
  await assertFails(getDoc(doc(db, `businesses/${BIZ_ID}/inventory_items/item_c`)));
});

test('a staff-record-id-scoped list query returns only that member\'s assigned items', async () => {
  const db = firestoreAs(STAFF_A_UID);
  const q = query(
    collection(db, `businesses/${BIZ_ID}/inventory_items`),
    where('assignedToUserId', '==', 'memberRecA'),
  );
  const snap = await assertSucceeds(getDocs(q));
  assert.equal(snap.size, 1);
  assert.equal(snap.docs[0].id, 'item_c');
});
