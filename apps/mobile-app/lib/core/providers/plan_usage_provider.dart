import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/customer/data/customer_providers.dart';
import '../../features/finance/data/finance_providers.dart';
import '../../features/invoice/domain/models/invoice.dart';
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
  final List<Invoice> _invoices;

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
    List<Invoice> invoices = const [],
    this.customers = 0,
    this.products = 0,
    this.serviceProducts = 0,
    this.teamMembers = 0,
    this.accounts = 0,
  }) : _invoices = invoices;

  /// Sales (invoices, excluding quotations) whose row was created today, on
  /// this device. Backs the `maxSalesPerDay` cap.
  ///
  /// Computed live from [DateTime.now()] on every access rather than cached
  /// at provider-rebuild time, so the daily cap actually resets at local
  /// midnight even if nothing else happens to trigger a rebuild (e.g. the
  /// app stays open/backgrounded overnight with no new invoice/customer/
  /// inventory write) — a stale cached value used to make the daily cap
  /// behave like it never reset, i.e. like a much longer-window cap.
  int get salesToday => _countMatching(_todayPrefix());

  /// Sales (invoices, excluding quotations) whose row was created this
  /// calendar month. Backs the `monthlyInvoices` cap — computed locally here
  /// so it stays consistent with [salesToday]; the gate itself still uses the
  /// server-verified count on [PlanStatus]. Same live-computation rationale
  /// as [salesToday].
  int get invoicesThisMonth => _countMatching(_monthPrefix());

  int _countMatching(String prefix) {
    var count = 0;
    for (final inv in _invoices) {
      if (inv.type.toLowerCase() == 'quotation') continue;
      // Invoice.createdAt is an ISO-8601 string ('2026-09-07T14:30:00.000').
      if (inv.createdAt.startsWith(prefix)) count++;
    }
    return count;
  }

  static String _twoDigits(int v) => v.toString().padLeft(2, '0');

  static String _monthPrefix() {
    final now = DateTime.now();
    return '${now.year}-${_twoDigits(now.month)}';
  }

  static String _todayPrefix() =>
      '${_monthPrefix()}-${_twoDigits(DateTime.now().day)}';
}

final planUsageProvider = Provider<PlanUsage>((ref) {
  final invoices = ref.watch(invoicesProvider).valueOrNull ?? const [];
  final customers = ref.watch(customerListProvider).valueOrNull ?? const [];
  final inventory = ref.watch(inventoryProvider).valueOrNull ?? const [];
  final team = ref.watch(teamMembersProvider).valueOrNull ?? const [];
  final accounts = ref.watch(cashAccountListProvider).valueOrNull ?? const [];

  var products = 0;
  var serviceProducts = 0;
  for (final item in inventory) {
    if (item.productType == 'customerReturn') continue;
    products++;
    if (item.productType == 'service') serviceProducts++;
  }

  return PlanUsage(
    invoices: invoices,
    customers: customers.length,
    products: products,
    serviceProducts: serviceProducts,
    teamMembers: team.length,
    accounts: accounts.length,
  );
});
