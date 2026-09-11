import { NextResponse } from 'next/server'
import { restFirestore as adminFirestore } from '@/lib/firestore-rest'
import { requireAdminSession } from '@/lib/api-guard'
import type { PlanTier, PlanDefinition, PlanDefinitions } from '@/types'

const CONFIG_DOC = 'platform_config'
const PLANS_DOC  = 'plans'

const DEFAULT_PLANS: PlanDefinitions = {
  starter: {
    pricePerCycle: 0,
    cycleMonths: 6,
    maxUsers: 1,
    monthlyInvoices: 50,
    maxBusinesses: 1,
    maxCustomers: 20,
    maxProducts: 15,
    maxServiceProducts: 3,
    maxSalesPerDay: 10,
    cashFlow: false,
    expenseTracking: false,
    manualDebt: false,
    fullReports: false,
    mpesaImport: false,
    smsReminders: false,
    allExports: false,
    multiLocation: false,
    apiAccess: false,
    prioritySupport: false,
    customIntegrations: false,
    whiteLabel: false,
    dedicatedOnboarding: false,
  },
  growth: {
    pricePerCycle: 30000,
    cycleMonths: 6,
    maxUsers: 3,
    monthlyInvoices: -1,
    maxBusinesses: -1,
    maxCustomers: -1,
    maxProducts: -1,
    maxServiceProducts: -1,
    maxSalesPerDay: -1,
    cashFlow: true,
    expenseTracking: true,
    manualDebt: true,
    fullReports: true,
    mpesaImport: true,
    smsReminders: true,
    allExports: false,
    multiLocation: false,
    apiAccess: false,
    prioritySupport: false,
    customIntegrations: false,
    whiteLabel: false,
    dedicatedOnboarding: false,
  },
  business: {
    pricePerCycle: 40000,
    cycleMonths: 6,
    maxUsers: 10,
    monthlyInvoices: -1,
    maxBusinesses: -1,
    maxCustomers: -1,
    maxProducts: -1,
    maxServiceProducts: -1,
    maxSalesPerDay: -1,
    cashFlow: true,
    expenseTracking: true,
    manualDebt: true,
    fullReports: true,
    mpesaImport: true,
    smsReminders: true,
    allExports: true,
    multiLocation: true,
    apiAccess: true,
    prioritySupport: true,
    customIntegrations: false,
    whiteLabel: false,
    dedicatedOnboarding: false,
  },
  enterprise: {
    pricePerCycle: 0,
    cycleMonths: 6,
    maxUsers: -1,
    monthlyInvoices: -1,
    maxBusinesses: -1,
    maxCustomers: -1,
    maxProducts: -1,
    maxServiceProducts: -1,
    maxSalesPerDay: -1,
    cashFlow: true,
    expenseTracking: true,
    manualDebt: true,
    fullReports: true,
    mpesaImport: true,
    smsReminders: true,
    allExports: true,
    multiLocation: true,
    apiAccess: true,
    prioritySupport: true,
    customIntegrations: true,
    whiteLabel: true,
    dedicatedOnboarding: true,
  },
  lifetime: {
    pricePerCycle: 0,
    cycleMonths: 0,
    maxUsers: -1,
    monthlyInvoices: -1,
    maxBusinesses: -1,
    maxCustomers: -1,
    maxProducts: -1,
    maxServiceProducts: -1,
    maxSalesPerDay: -1,
    cashFlow: true,
    expenseTracking: true,
    manualDebt: true,
    fullReports: true,
    mpesaImport: true,
    smsReminders: true,
    allExports: true,
    multiLocation: true,
    apiAccess: true,
    prioritySupport: true,
    customIntegrations: true,
    whiteLabel: true,
    dedicatedOnboarding: true,
  },
}

async function getPlansDoc() {
  const ref = adminFirestore.collection(CONFIG_DOC).doc(PLANS_DOC)
  const snap = await ref.get()
  if (!snap.exists) return DEFAULT_PLANS
  const data = snap.data() as Partial<PlanDefinitions>
  // Merge defaults so any missing tier/field always has a value
  const result = { ...DEFAULT_PLANS } as PlanDefinitions
  for (const tier of Object.keys(DEFAULT_PLANS) as PlanTier[]) {
    if (data[tier]) result[tier] = { ...DEFAULT_PLANS[tier], ...data[tier] }
  }
  return result
}

export async function GET() {
  const denied = await requireAdminSession()
  if (denied) return denied

  try {
    const plans = await getPlansDoc()
    return NextResponse.json({ plans })
  } catch (err) {
    console.error('[GET /api/admin/plans]', err)
    return NextResponse.json({ error: 'Failed to fetch plans' }, { status: 500 })
  }
}
