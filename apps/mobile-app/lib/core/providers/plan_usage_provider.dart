import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/customer/data/customer_providers.dart';
import '../../features/finance/data/finance_providers.dart';
import '../../features/inventory/presentation/providers/inventory_providers.dart';
import '../../features/invoice/presentation/providers/invoice_providers.dart';
import '../../features/team/data/team_providers.dart';

/// Live consumption of each metered plan limit, for the free-plan usage panel
/// on the My Plan screen and the compact figures on the Settings plan card.
///
/// Every count is read from the offline-first Drift streams (never Firestore),
/// so the panel stays accurate with no connection and matches exactly what the
/// "add" gates in each feature enforce against.
class PlanUsage {
  /// Sales (invoices, excluding quotations) whose row was created today, on
  /// this device. Backs the `maxSalesPerDay` cap.
  final int salesToday;

  /// Sales (invoices, excluding quotations) whose row was created this
  /// calendar month. Backs the `monthlyInvoices` cap — computed locally here
  /// so it stays consistent with [salesToday]; the gate itself still uses the
  /// server-verified count on [PlanStatus].
  final int invoicesThisMonth;

  /// Customers on file. Backs `maxCustomers`.
  final int customers;

  /// Manually-created inventory items, excluding customer-return items (which
  /// never count). Backs `maxProducts`.
  final int products;

  /// Service-type products, a subset of [products]. Backs `maxServiceProducts`.
  final int serviceProducts;

  /// Team members excluding the owner. Backs `maxUsers` (owner + this count).
  final int teamMembers;

  /// Cash Flow accounts on file — activated built-in payment channels plus
  /// custom accounts, combined. Backs `maxAccounts`.
  final int accounts;

  const PlanUsage({
    this.salesToday = 0,
    this.invoicesThisMonth = 0,
    this.customers = 0,
    this.products = 0,
    this.serviceProducts = 0,
    this.teamMembers = 0,
    this.accounts = 0,
  });
}

final planUsageProvider = Provider<PlanUsage>((ref) {
  final invoices = ref.watch(invoicesProvider).valueOrNull ?? const [];
  final customers = ref.watch(customerListProvider).valueOrNull ?? const [];
  final inventory = ref.watch(inventoryProvider).valueOrNull ?? const [];
  final team = ref.watch(teamMembersProvider).valueOrNull ?? const [];
  final accounts = ref.watch(cashAccountListProvider).valueOrNull ?? const [];

  final now = DateTime.now();
  String two(int v) => v.toString().padLeft(2, '0');
  final monthPrefix = '${now.year}-${two(now.month)}';
  final todayPrefix = '$monthPrefix-${two(now.day)}';

  var salesToday = 0;
  var invoicesThisMonth = 0;
  for (final inv in invoices) {
    if (inv.type.toLowerCase() == 'quotation') continue;
    // Invoice.createdAt is an ISO-8601 string ('2026-09-07T14:30:00.000').
    if (inv.createdAt.startsWith(monthPrefix)) {
      invoicesThisMonth++;
      if (inv.createdAt.startsWith(todayPrefix)) salesToday++;
    }
  }

  var products = 0;
  var serviceProducts = 0;
  for (final item in inventory) {
    if (item.productType == 'customerReturn') continue;
    products++;
    if (item.productType == 'service') serviceProducts++;
  }

  return PlanUsage(
    salesToday: salesToday,
    invoicesThisMonth: invoicesThisMonth,
    customers: customers.length,
    products: products,
    serviceProducts: serviceProducts,
    teamMembers: team.length,
    accounts: accounts.length,
  );
});
