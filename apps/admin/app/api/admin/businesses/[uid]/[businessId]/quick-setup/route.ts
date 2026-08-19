import { NextResponse } from 'next/server'
import admin from 'firebase-admin'
import { adminFirestore } from '@/lib/firebase-admin'
import { requireAdminSession } from '@/lib/api-guard'
import { auth } from '@/lib/auth'
import { writeAudit } from '@/lib/write-audit'

type Params = { uid: string; businessId: string }

// Firestore batches cap at 500 writes; stay well under it.
const WRITE_CHUNK = 400

function chunk<T>(items: T[], size: number): T[][] {
  const out: T[][] = []
  for (let i = 0; i < items.length; i += size) out.push(items.slice(i, i + size))
  return out
}

interface ProductRow { name: string; type?: 'product' | 'service'; unit?: string; sellingPrice?: number; costPrice?: number; stock?: number; sku?: string }
interface CustomerRow { name: string; phone?: string; email?: string; address?: string; creditLimit?: number }
interface DebtRow { partyName: string; partyPhone?: string; type?: 'receivable' | 'payable'; amount: number; dueDate?: string; note?: string }
interface PaymentMethodRow { name: string; type?: 'cash' | 'bank' | 'mobileMoney'; accountNumber?: string; openingBalance?: number }
interface ExpenseRow { category: string; amount: number; date?: string; note?: string; paymentMethod?: string }
interface TeamRow { name: string; phone: string; email?: string; role?: 'manager' | 'accountant' | 'cashier' | 'stockClerk' }

interface QuickSetupBody {
  products?: ProductRow[]
  customers?: CustomerRow[]
  debts?: DebtRow[]
  paymentMethods?: PaymentMethodRow[]
  expenses?: ExpenseRow[]
  team?: TeamRow[]
}

// Mirrors defaultPermissionsFor() in team_member.dart's _roleDefaults map —
// keep in sync if roles/permissions change there. 'owner' and 'custom' are
// intentionally omitted: quick-setup invites always land as one of these
// four fixed roles, matching the roles the mobile Team screen offers.
const ROLE_PERMISSIONS: Record<string, string[]> = {
  manager: [
    'viewSales', 'createSale', 'editSale', 'deleteSale', 'applyDiscount', 'issueRefund',
    'viewInventory', 'addStock', 'editStock', 'adjustStock', 'deleteStock',
    'viewFinancialReports', 'manageExpenses', 'viewCashFlow',
    'viewCustomers', 'manageCustomers', 'grantCredit',
    'viewDebt', 'manageDebt', 'writeOffDebt', 'exportData',
  ],
  accountant: [
    'viewSales', 'viewInventory', 'viewFinancialReports', 'manageExpenses', 'viewCashFlow',
    'viewCustomers', 'viewDebt', 'manageDebt', 'writeOffDebt', 'exportData',
  ],
  cashier: ['viewSales', 'createSale', 'applyDiscount', 'viewInventory', 'viewCustomers'],
  stockClerk: ['viewInventory', 'addStock', 'editStock', 'adjustStock'],
}

// Bulk-populates a brand-new business with everything staff typically enter
// while onboarding a client on their behalf: products/services, customers,
// debts, payment methods (cash accounts), expenses, and team invites — all
// in one call. Writes go straight to the same Firestore subcollections the
// mobile app's Sync*Repository classes read/write
// (businesses/{id}/inventory_items|customers|debts|cash_accounts|expenses|staff),
// so every record flows down to the owner's device via the normal
// SyncService pull cycle, exactly as if they'd entered it themselves.
export async function POST(
  request: Request,
  { params }: { params: Promise<Params> },
) {
  const denied = await requireAdminSession()
  if (denied) return denied

  const { uid, businessId } = await params

  try {
    const body = (await request.json()) as QuickSetupBody

    const bizRef = adminFirestore.collection('businesses').doc(businessId)
    const bizDoc = await bizRef.get()
    if (!bizDoc.exists) {
      return NextResponse.json({ error: 'Business not found' }, { status: 404 })
    }
    const bizData = bizDoc.data() as Record<string, unknown>
    const bizName = (bizData.businessName as string) || businessId
    const ownerUid = (bizData.ownerUid as string) || uid

    const session = await auth()
    const adminName = session?.user?.name ?? session?.user?.email ?? 'Admin'
    const nowIso = new Date().toISOString()

    type Op = { ref: FirebaseFirestore.DocumentReference; data: Record<string, unknown> }
    const ops: Op[] = []
    const counts = { products: 0, customers: 0, debts: 0, paymentMethods: 0, expenses: 0, team: 0 }

    // ── Products & services ──────────────────────────────────────────────────
    const invItemsRef = bizRef.collection('inventory_items')
    for (const row of body.products ?? []) {
      if (!row.name?.trim()) continue
      const isService = row.type === 'service'
      ops.push({
        ref: invItemsRef.doc(),
        data: {
          name: row.name.trim(),
          description: '', category: '', categoryId: '', categoryName: '',
          sku: row.sku?.trim() || '',
          currentStock: isService ? 0 : (row.stock ?? 0),
          stock: isService ? 0 : (row.stock ?? 0),
          reorderPoint: 5,
          unitPrice: row.sellingPrice ?? 0,
          sellingPrice: row.sellingPrice ?? 0,
          costPrice: row.costPrice ?? 0,
          buyingPrice: row.costPrice ?? 0,
          productType: isService ? 'service' : 'stock',
          unit: row.unit?.trim() || 'Piece',
          supplier: '', lastRestocked: '',
          createdAt: nowIso, updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          isActive: true, expiryDate: '', batchNumber: '', warrantyPeriod: '', brand: '',
          sellingUnits: [], returnReason: '', bomIngredients: [], bomOverheads: [], bomBatchYield: 1,
          addedByAdmin: true,
        },
      })
      counts.products++
    }

    // ── Customers ─────────────────────────────────────────────────────────────
    const customersRef = bizRef.collection('customers')
    for (const row of body.customers ?? []) {
      if (!row.name?.trim()) continue
      ops.push({
        ref: customersRef.doc(),
        data: {
          name: row.name.trim(),
          phone: row.phone?.trim() || '',
          email: row.email?.trim() || '',
          balance: 0,
          lastTransactionDate: '',
          tags: [],
          isOrganisation: false,
          ...(row.address?.trim() ? { address: row.address.trim() } : {}),
          ...(row.creditLimit && row.creditLimit > 0 ? { creditLimit: row.creditLimit } : {}),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
      })
      counts.customers++
    }

    // ── Debts ─────────────────────────────────────────────────────────────────
    const debtsRef = bizRef.collection('debts')
    for (const row of body.debts ?? []) {
      if (!row.partyName?.trim() || !row.amount) continue
      ops.push({
        ref: debtsRef.doc(),
        data: {
          partyName: row.partyName.trim(),
          ...(row.partyPhone?.trim() ? { partyPhone: row.partyPhone.trim() } : {}),
          type: row.type === 'payable' ? 'payable' : 'receivable',
          originalAmount: row.amount,
          paidAmount: 0,
          dueDate: row.dueDate?.trim() || '',
          status: 'current',
          ...(row.note?.trim() ? { note: row.note.trim() } : {}),
          createdBy: adminName,
          createdAt: nowIso,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
      })
      counts.debts++
    }

    // ── Payment methods (cash accounts) ──────────────────────────────────────
    const cashRef = bizRef.collection('cash_accounts')
    for (const row of body.paymentMethods ?? []) {
      if (!row.name?.trim()) continue
      ops.push({
        ref: cashRef.doc(),
        data: {
          name: row.name.trim(),
          type: row.type ?? 'cash',
          balance: row.openingBalance ?? 0,
          currency: 'TZS',
          lastReconciled: '',
          ...(row.accountNumber?.trim() ? { accountNumber: row.accountNumber.trim() } : {}),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
      })
      counts.paymentMethods++
    }

    // ── Expenses ──────────────────────────────────────────────────────────────
    const expensesRef = bizRef.collection('expenses')
    for (const row of body.expenses ?? []) {
      if (!row.category?.trim() || !row.amount) continue
      ops.push({
        ref: expensesRef.doc(),
        data: {
          category: row.category.trim(),
          amount: row.amount,
          date: row.date?.trim() || nowIso,
          note: row.note?.trim() || '',
          recipient: '',
          isRecurring: false,
          paymentMethod: row.paymentMethod?.trim() || 'cash',
          status: 'approved',
          createdBy: adminName,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
      })
      counts.expenses++
    }

    // ── Team members (invites) ───────────────────────────────────────────────
    // Mirrors what the owner-facing "Add team member" flow writes: a pending
    // `staff` doc plus a `pendingInvites` doc keyed by phone, so when that
    // person signs up the existing onboarding flow finds and activates it —
    // see onboarding_repository.dart's _linkWorker (staff lookup by phone).
    const staffRef = bizRef.collection('staff')
    let teamAdded = 0
    for (const row of body.team ?? []) {
      if (!row.name?.trim() || !row.phone?.trim()) continue
      const role = row.role ?? 'cashier'
      const permissions = ROLE_PERMISSIONS[role] ?? []
      const memberRef = staffRef.doc()
      ops.push({
        ref: memberRef,
        data: {
          name: row.name.trim(),
          email: row.email?.trim() || '',
          phone: row.phone.trim(),
          role,
          customPermissions: [],
          permissions,
          status: 'pending',
          invitedAt: admin.firestore.FieldValue.serverTimestamp(),
          invitedBy: adminName,
          dataScope: 'all',
        },
      })
      ops.push({
        ref: adminFirestore.collection('pendingInvites').doc(),
        data: {
          businessId,
          businessName: bizName,
          fullName: row.name.trim(),
          phoneNumber: row.phone.trim(),
          email: row.email?.trim() || '',
          role,
          invitedBy: adminName,
          ownerUid,
          memberId: memberRef.id,
          status: 'pending',
          pinCreated: false,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        },
      })
      teamAdded++
    }
    counts.team = teamAdded

    if (ops.length === 0) {
      return NextResponse.json({ error: 'No valid rows to save' }, { status: 400 })
    }

    for (const group of chunk(ops, WRITE_CHUNK)) {
      const batch = adminFirestore.batch()
      for (const op of group) batch.set(op.ref, op.data)
      await batch.commit()
    }

    if (teamAdded > 0) {
      await bizRef.update({ staffCount: admin.firestore.FieldValue.increment(teamAdded) })
    }

    await writeAudit({
      action: 'quick_setup_business',
      resourceType: 'business',
      resourceId: businessId,
      resourceName: bizName,
      isDestructive: false,
      after: counts,
    })

    return NextResponse.json({ counts })
  } catch (err) {
    console.error(`[POST /api/admin/businesses/${uid}/${businessId}/quick-setup]`, err)
    return NextResponse.json({ error: 'Failed to save business details' }, { status: 500 })
  }
}
