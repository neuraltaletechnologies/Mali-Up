import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../finance/data/finance_providers.dart';
import '../../finance/domain/models/cash_account.dart';
import '../../finance/domain/models/expense.dart';
import '../../inventory/data/inventory_providers.dart';
import '../../inventory/domain/models/inventory_item.dart';
import '../../sales/data/sales_providers.dart';

// ─── Date Range Model ─────────────────────────────────────────────────────────

enum ReportPeriod { today, thisWeek, thisMonth, lastMonth, thisQuarter, thisYear, custom }

class ReportDateRange {
  final DateTime start;
  final DateTime end;
  final ReportPeriod period;

  const ReportDateRange({
    required this.start,
    required this.end,
    required this.period,
  });

  String get label {
    switch (period) {
      case ReportPeriod.today:
        return 'Today';
      case ReportPeriod.thisWeek:
        return 'This Week';
      case ReportPeriod.thisMonth:
        return 'This Month';
      case ReportPeriod.lastMonth:
        return 'Last Month';
      case ReportPeriod.thisQuarter:
        return 'This Quarter';
      case ReportPeriod.thisYear:
        return 'This Year';
      case ReportPeriod.custom:
        final s = '${start.day}/${start.month}/${start.year}';
        final e = '${end.day}/${end.month}/${end.year}';
        return '$s – $e';
    }
  }

  String get labelSw {
    switch (period) {
      case ReportPeriod.today:
        return 'Leo';
      case ReportPeriod.thisWeek:
        return 'Wiki hii';
      case ReportPeriod.thisMonth:
        return 'Mwezi huu';
      case ReportPeriod.lastMonth:
        return 'Mwezi uliopita';
      case ReportPeriod.thisQuarter:
        return 'Robo hii';
      case ReportPeriod.thisYear:
        return 'Mwaka huu';
      case ReportPeriod.custom:
        final s = '${start.day}/${start.month}/${start.year}';
        final e = '${end.day}/${end.month}/${end.year}';
        return '$s – $e';
    }
  }

  static ReportDateRange forPeriod(ReportPeriod period, {DateTime? customStart, DateTime? customEnd}) {
    final now = DateTime.now();
    switch (period) {
      case ReportPeriod.today:
        final start = DateTime(now.year, now.month, now.day);
        return ReportDateRange(start: start, end: now, period: period);
      case ReportPeriod.thisWeek:
        final start = now.subtract(Duration(days: now.weekday - 1));
        return ReportDateRange(
          start: DateTime(start.year, start.month, start.day),
          end: now,
          period: period,
        );
      case ReportPeriod.thisMonth:
        return ReportDateRange(
          start: DateTime(now.year, now.month),
          end: now,
          period: period,
        );
      case ReportPeriod.lastMonth:
        final first = DateTime(now.year, now.month - 1);
        final last = DateTime(now.year, now.month, 0, 23, 59, 59);
        return ReportDateRange(start: first, end: last, period: period);
      case ReportPeriod.thisQuarter:
        final q = ((now.month - 1) ~/ 3) * 3 + 1;
        return ReportDateRange(
          start: DateTime(now.year, q),
          end: now,
          period: period,
        );
      case ReportPeriod.thisYear:
        return ReportDateRange(
          start: DateTime(now.year),
          end: now,
          period: period,
        );
      case ReportPeriod.custom:
        return ReportDateRange(
          start: customStart ?? DateTime(now.year, now.month),
          end: customEnd ?? now,
          period: period,
        );
    }
  }

  bool contains(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    final s = DateTime(start.year, start.month, start.day);
    final e = DateTime(end.year, end.month, end.day);
    return !d.isBefore(s) && !d.isAfter(e);
  }
}

// ─── Date Range Notifier ──────────────────────────────────────────────────────

class ReportRangeNotifier extends Notifier<ReportDateRange> {
  @override
  ReportDateRange build() => ReportDateRange.forPeriod(ReportPeriod.thisMonth);

  void setPeriod(ReportPeriod period) {
    state = ReportDateRange.forPeriod(period);
  }

  void setCustomRange(DateTime start, DateTime end) {
    state = ReportDateRange(
      start: start,
      end: end,
      period: ReportPeriod.custom,
    );
  }
}

final reportDateRangeProvider =
    NotifierProvider<ReportRangeNotifier, ReportDateRange>(ReportRangeNotifier.new);

// ─── Filtered Data Providers ──────────────────────────────────────────────────

DateTime? _parseDate(Object? value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}

double _parseAmount(Object? value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  final cleaned = value.toString().replaceAll(RegExp(r'[^0-9.\-]'), '').trim();
  return double.tryParse(cleaned) ?? 0;
}

final filteredInvoicesProvider = Provider<List<Map<String, dynamic>>>((ref) {
  final range = ref.watch(reportDateRangeProvider);
  final all = ref.watch(salesInvoiceListProvider).maybeWhen(
        data: (d) => d,
        orElse: () => <Map<String, dynamic>>[],
      );
  return all.where((inv) {
    final date = _parseDate(inv['createdAt']);
    return date != null && range.contains(date);
  }).toList();
});

final filteredExpensesProvider = Provider<List<Expense>>((ref) {
  final range = ref.watch(reportDateRangeProvider);
  final all = ref.watch(expenseListProvider).maybeWhen(
        data: (d) => d,
        orElse: () => <Expense>[],
      );
  return all.where((e) {
    final date = DateTime.tryParse(e.date);
    return date != null && range.contains(date);
  }).toList();
});

final allInventoryProvider = Provider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(inventoryItemListProvider).maybeWhen(
        data: (d) => d,
        orElse: () => <Map<String, dynamic>>[],
      );
});

final allCashAccountsProvider = Provider<List<CashAccount>>((ref) {
  return ref.watch(cashAccountListProvider).maybeWhen(
        data: (d) => d,
        orElse: () => <CashAccount>[],
      );
});

// ─── P&L Report ───────────────────────────────────────────────────────────────

class PnlReport {
  final double revenue;
  final double totalExpenses;
  final double grossProfit;
  final double netProfit;
  final double profitMargin;
  final double vatCollected;
  final int invoiceCount;
  final Map<String, double> expenseByCategory;
  final List<({int month, int year, double revenue, double expenses})> trend;

  const PnlReport({
    required this.revenue,
    required this.totalExpenses,
    required this.grossProfit,
    required this.netProfit,
    required this.profitMargin,
    required this.vatCollected,
    required this.invoiceCount,
    required this.expenseByCategory,
    required this.trend,
  });
}

final pnlReportProvider = Provider<PnlReport>((ref) {
  final invoices = ref.watch(filteredInvoicesProvider);
  final expenses = ref.watch(filteredExpensesProvider);

  double revenue = 0;
  double vatCollected = 0;
  int invoiceCount = 0;

  for (final inv in invoices) {
    final status = (inv['status'] ?? inv['paymentStatus'] ?? '').toString().toLowerCase();
    if (status == 'paid' || status == 'completed' || status == 'partial') {
      revenue += _parseAmount(inv['totalAmount'] ?? inv['total'] ?? inv['amount']);
      vatCollected += _parseAmount(inv['vatAmount'] ?? inv['vat'] ?? 0);
      invoiceCount++;
    }
  }

  double totalExpenses = 0;
  final Map<String, double> expenseByCategory = {};
  for (final e in expenses) {
    if (e.status == 'rejected') continue;
    final amount = _parseAmount(e.amount);
    totalExpenses += amount;
    expenseByCategory[e.category] = (expenseByCategory[e.category] ?? 0) + amount;
  }

  final grossProfit = revenue;
  final netProfit = revenue - totalExpenses;
  final profitMargin = revenue > 0 ? (netProfit / revenue) * 100 : 0.0;

  // Build 6-month trend
  final now = DateTime.now();
  final allInvoices = ref.watch(salesInvoiceListProvider).maybeWhen(
        data: (d) => d,
        orElse: () => <Map<String, dynamic>>[],
      );
  final allExpenses = ref.watch(expenseListProvider).maybeWhen(
        data: (d) => d,
        orElse: () => <Expense>[],
      );
  final trend = List.generate(6, (i) {
    final m = DateTime(now.year, now.month - 5 + i);
    double rev = 0;
    double exp = 0;
    for (final inv in allInvoices) {
      final date = _parseDate(inv['createdAt']);
      if (date == null || date.year != m.year || date.month != m.month) continue;
      final status = (inv['status'] ?? inv['paymentStatus'] ?? '').toString().toLowerCase();
      if (status == 'paid' || status == 'completed' || status == 'partial') {
        rev += _parseAmount(inv['totalAmount'] ?? inv['total'] ?? inv['amount']);
      }
    }
    for (final e in allExpenses) {
      final date = DateTime.tryParse(e.date);
      if (date == null || date.year != m.year || date.month != m.month) continue;
      if (e.status != 'rejected') exp += _parseAmount(e.amount);
    }
    return (month: m.month, year: m.year, revenue: rev, expenses: exp);
  });

  return PnlReport(
    revenue: revenue,
    totalExpenses: totalExpenses,
    grossProfit: grossProfit,
    netProfit: netProfit,
    profitMargin: profitMargin,
    vatCollected: vatCollected,
    invoiceCount: invoiceCount,
    expenseByCategory: expenseByCategory,
    trend: trend,
  );
});

// ─── Sales Report ─────────────────────────────────────────────────────────────

class SalesReport {
  final double totalRevenue;
  final int invoiceCount;
  final double averageInvoiceValue;
  final Map<String, double> byPaymentMethod;
  final Map<String, double> byProduct;
  final Map<String, double> byCustomer;
  final List<({int month, int year, double total})> trend;

  const SalesReport({
    required this.totalRevenue,
    required this.invoiceCount,
    required this.averageInvoiceValue,
    required this.byPaymentMethod,
    required this.byProduct,
    required this.byCustomer,
    required this.trend,
  });
}

final salesReportProvider = Provider<SalesReport>((ref) {
  final invoices = ref.watch(filteredInvoicesProvider);

  double total = 0;
  int count = 0;
  final Map<String, double> byPayment = {};
  final Map<String, double> byProduct = {};
  final Map<String, double> byCustomer = {};

  for (final inv in invoices) {
    final status = (inv['status'] ?? inv['paymentStatus'] ?? '').toString().toLowerCase();
    if (status != 'paid' && status != 'completed' && status != 'partial') continue;

    final amount = _parseAmount(inv['totalAmount'] ?? inv['total'] ?? inv['amount']);
    total += amount;
    count++;

    final method = (inv['paymentMethod'] ?? 'Other').toString();
    byPayment[method] = (byPayment[method] ?? 0) + amount;

    final custName = (inv['customerName'] ?? inv['customer'] ?? 'Unknown').toString();
    byCustomer[custName] = (byCustomer[custName] ?? 0) + amount;

    final items = inv['items'];
    if (items is List) {
      for (final item in items) {
        if (item is! Map) continue;
        final name = (item['productName'] ?? item['name'] ?? 'Unknown').toString();
        final lineTotal = _parseAmount(item['lineTotal'] ?? item['total'] ??
            (_parseAmount(item['unitPrice'] ?? item['price']) * _parseAmount(item['qty'] ?? item['quantity'] ?? 1)));
        byProduct[name] = (byProduct[name] ?? 0) + lineTotal;
      }
    }
  }

  final now = DateTime.now();
  final allInvoices = ref.watch(salesInvoiceListProvider).maybeWhen(
        data: (d) => d,
        orElse: () => <Map<String, dynamic>>[],
      );
  final trend = List.generate(6, (i) {
    final m = DateTime(now.year, now.month - 5 + i);
    double rev = 0;
    for (final inv in allInvoices) {
      final date = _parseDate(inv['createdAt']);
      if (date == null || date.year != m.year || date.month != m.month) continue;
      final status = (inv['status'] ?? inv['paymentStatus'] ?? '').toString().toLowerCase();
      if (status == 'paid' || status == 'completed' || status == 'partial') {
        rev += _parseAmount(inv['totalAmount'] ?? inv['total'] ?? inv['amount']);
      }
    }
    return (month: m.month, year: m.year, total: rev);
  });

  return SalesReport(
    totalRevenue: total,
    invoiceCount: count,
    averageInvoiceValue: count > 0 ? total / count : 0,
    byPaymentMethod: byPayment,
    byProduct: byProduct,
    byCustomer: byCustomer,
    trend: trend,
  );
});

// ─── Expense Report ───────────────────────────────────────────────────────────

class ExpenseReport {
  final double totalExpenses;
  final int expenseCount;
  final Map<String, double> byCategory;
  final Map<String, double> byVendor;
  final Map<String, double> byPaymentMethod;
  final List<({int month, int year, double total})> trend;

  const ExpenseReport({
    required this.totalExpenses,
    required this.expenseCount,
    required this.byCategory,
    required this.byVendor,
    required this.byPaymentMethod,
    required this.trend,
  });
}

final expenseReportProvider = Provider<ExpenseReport>((ref) {
  final expenses = ref.watch(filteredExpensesProvider);

  double total = 0;
  final Map<String, double> byCategory = {};
  final Map<String, double> byVendor = {};
  final Map<String, double> byPaymentMethod = {};

  for (final e in expenses) {
    if (e.status == 'rejected') continue;
    final amount = _parseAmount(e.amount);
    total += amount;
    byCategory[e.category] = (byCategory[e.category] ?? 0) + amount;
    if (e.recipient.isNotEmpty) {
      byVendor[e.recipient] = (byVendor[e.recipient] ?? 0) + amount;
    }
    byPaymentMethod[e.paymentMethod] = (byPaymentMethod[e.paymentMethod] ?? 0) + amount;
  }

  final now = DateTime.now();
  final allExpenses = ref.watch(expenseListProvider).maybeWhen(
        data: (d) => d,
        orElse: () => <Expense>[],
      );
  final trend = List.generate(6, (i) {
    final m = DateTime(now.year, now.month - 5 + i);
    double t = 0;
    for (final e in allExpenses) {
      final date = DateTime.tryParse(e.date);
      if (date == null || date.year != m.year || date.month != m.month) continue;
      if (e.status != 'rejected') t += _parseAmount(e.amount);
    }
    return (month: m.month, year: m.year, total: t);
  });

  return ExpenseReport(
    totalExpenses: total,
    expenseCount: expenses.where((e) => e.status != 'rejected').length,
    byCategory: byCategory,
    byVendor: byVendor,
    byPaymentMethod: byPaymentMethod,
    trend: trend,
  );
});

// ─── VAT Summary ──────────────────────────────────────────────────────────────

class VatSummary {
  final double vatCollectedOnSales;
  final double vatPaidOnPurchases;
  final double netVatPayable;
  final int taxableSalesCount;
  final int taxablePurchasesCount;
  final double taxableSalesAmount;
  final double taxablePurchasesAmount;

  const VatSummary({
    required this.vatCollectedOnSales,
    required this.vatPaidOnPurchases,
    required this.netVatPayable,
    required this.taxableSalesCount,
    required this.taxablePurchasesCount,
    required this.taxableSalesAmount,
    required this.taxablePurchasesAmount,
  });
}

final vatSummaryProvider = Provider<VatSummary>((ref) {
  final invoices = ref.watch(filteredInvoicesProvider);
  final expenses = ref.watch(filteredExpensesProvider);

  double vatCollected = 0;
  double taxableSalesAmount = 0;
  int taxableSalesCount = 0;

  for (final inv in invoices) {
    final vat = _parseAmount(inv['vatAmount'] ?? inv['vat'] ?? 0);
    if (vat > 0) {
      vatCollected += vat;
      taxableSalesAmount += _parseAmount(inv['totalAmount'] ?? inv['total'] ?? 0);
      taxableSalesCount++;
    }
  }

  double vatPaid = 0;
  double taxablePurchasesAmount = 0;
  int taxablePurchasesCount = 0;

  for (final e in expenses) {
    if (e.status == 'rejected') continue;
    // Assume 18% VAT on expenses marked as taxable (category hint: 'VAT' or 'tax' in note)
    // For now derive VAT from expense amounts where explicitly set
    final amount = _parseAmount(e.amount);
    if (e.note.toLowerCase().contains('vat') || e.category.toLowerCase().contains('tax')) {
      vatPaid += amount * 0.18 / 1.18;
      taxablePurchasesAmount += amount;
      taxablePurchasesCount++;
    }
  }

  return VatSummary(
    vatCollectedOnSales: vatCollected,
    vatPaidOnPurchases: vatPaid,
    netVatPayable: vatCollected - vatPaid,
    taxableSalesCount: taxableSalesCount,
    taxablePurchasesCount: taxablePurchasesCount,
    taxableSalesAmount: taxableSalesAmount,
    taxablePurchasesAmount: taxablePurchasesAmount,
  );
});

// ─── AR Aging ─────────────────────────────────────────────────────────────────

class AgingBucket {
  final String label;
  final List<Map<String, dynamic>> items;
  final double total;

  const AgingBucket({required this.label, required this.items, required this.total});
}

class ArAgingReport {
  final AgingBucket current;     // 0–30 days
  final AgingBucket days31to60;
  final AgingBucket days61to90;
  final AgingBucket over90;
  final double grandTotal;

  const ArAgingReport({
    required this.current,
    required this.days31to60,
    required this.days61to90,
    required this.over90,
    required this.grandTotal,
  });
}

final arAgingProvider = Provider<ArAgingReport>((ref) {
  final allInvoices = ref.watch(salesInvoiceListProvider).maybeWhen(
        data: (d) => d,
        orElse: () => <Map<String, dynamic>>[],
      );
  final now = DateTime.now();

  final List<Map<String, dynamic>> c0 = [], c31 = [], c61 = [], c91 = [];

  for (final inv in allInvoices) {
    final status = (inv['status'] ?? inv['paymentStatus'] ?? '').toString().toLowerCase();
    if (status == 'paid' || status == 'completed') continue;

    final date = _parseDate(inv['createdAt'] ?? inv['dueDate']);
    if (date == null) continue;

    final ageDays = now.difference(date).inDays;
    final amount = _parseAmount(inv['totalAmount'] ?? inv['total'] ?? inv['amount']);
    final entry = {
      ...inv,
      '_ageDays': ageDays,
      '_amount': amount,
    };

    if (ageDays <= 30) {
      c0.add(entry);
    } else if (ageDays <= 60) {
      c31.add(entry);
    } else if (ageDays <= 90) {
      c61.add(entry);
    } else {
      c91.add(entry);
    }
  }

  double total(List<Map<String, dynamic>> list) =>
      list.fold(0.0, (s, e) => s + (e['_amount'] as double));

  return ArAgingReport(
    current: AgingBucket(label: '0–30 days', items: c0, total: total(c0)),
    days31to60: AgingBucket(label: '31–60 days', items: c31, total: total(c31)),
    days61to90: AgingBucket(label: '61–90 days', items: c61, total: total(c61)),
    over90: AgingBucket(label: '90+ days', items: c91, total: total(c91)),
    grandTotal: total(c0) + total(c31) + total(c61) + total(c91),
  );
});

// ─── AP Aging ─────────────────────────────────────────────────────────────────

class ApAgingReport {
  final AgingBucket current;
  final AgingBucket days31to60;
  final AgingBucket days61to90;
  final AgingBucket over90;
  final double grandTotal;

  const ApAgingReport({
    required this.current,
    required this.days31to60,
    required this.days61to90,
    required this.over90,
    required this.grandTotal,
  });
}

final apAgingProvider = Provider<ApAgingReport>((ref) {
  final allExpenses = ref.watch(expenseListProvider).maybeWhen(
        data: (d) => d,
        orElse: () => <Expense>[],
      );
  final now = DateTime.now();

  final List<Map<String, dynamic>> c0 = [], c31 = [], c61 = [], c91 = [];

  for (final e in allExpenses) {
    if (e.status == 'approved') continue; // only unpaid/pending counts as AP

    final date = DateTime.tryParse(e.date);
    if (date == null) continue;

    final ageDays = now.difference(date).inDays;
    final amount = _parseAmount(e.amount);
    final entry = <String, dynamic>{
      'id': e.id,
      'recipient': e.recipient,
      'category': e.category,
      'amount': amount,
      'date': e.date,
      'status': e.status,
      '_ageDays': ageDays,
      '_amount': amount,
    };

    if (ageDays <= 30) {
      c0.add(entry);
    } else if (ageDays <= 60) {
      c31.add(entry);
    } else if (ageDays <= 90) {
      c61.add(entry);
    } else {
      c91.add(entry);
    }
  }

  double total(List<Map<String, dynamic>> list) =>
      list.fold(0.0, (s, e) => s + (e['_amount'] as double));

  return ApAgingReport(
    current: AgingBucket(label: '0–30 days', items: c0, total: total(c0)),
    days31to60: AgingBucket(label: '31–60 days', items: c31, total: total(c31)),
    days61to90: AgingBucket(label: '61–90 days', items: c61, total: total(c61)),
    over90: AgingBucket(label: '90+ days', items: c91, total: total(c91)),
    grandTotal: total(c0) + total(c31) + total(c61) + total(c91),
  );
});

// ─── Cash Flow Report ─────────────────────────────────────────────────────────

class CashFlowReport {
  final double operatingInflows;
  final double operatingOutflows;
  final double netOperating;
  final double openingBalance;
  final double closingBalance;
  final List<({String label, double amount, bool isInflow})> lineItems;

  const CashFlowReport({
    required this.operatingInflows,
    required this.operatingOutflows,
    required this.netOperating,
    required this.openingBalance,
    required this.closingBalance,
    required this.lineItems,
  });
}

final cashFlowReportProvider = Provider<CashFlowReport>((ref) {
  final invoices = ref.watch(filteredInvoicesProvider);
  final expenses = ref.watch(filteredExpensesProvider);
  final accounts = ref.watch(allCashAccountsProvider);

  final openingBalance = accounts.fold(0.0, (s, a) => s + _parseAmount(a.balance));

  double inflows = 0;
  final List<({String label, double amount, bool isInflow})> items = [];

  for (final inv in invoices) {
    final status = (inv['status'] ?? inv['paymentStatus'] ?? '').toString().toLowerCase();
    if (status != 'paid' && status != 'completed') continue;
    final amount = _parseAmount(inv['totalAmount'] ?? inv['total'] ?? inv['amount']);
    inflows += amount;
    items.add((
      label: 'Invoice #${(inv['invoiceNumber'] ?? inv['id']).toString().substring(0, 6)}',
      amount: amount,
      isInflow: true,
    ));
  }

  double outflows = 0;
  for (final e in expenses) {
    if (e.status == 'rejected') continue;
    final amount = _parseAmount(e.amount);
    outflows += amount;
    items.add((
      label: '${e.category}: ${e.recipient.isNotEmpty ? e.recipient : e.note}',
      amount: amount,
      isInflow: false,
    ));
  }

  return CashFlowReport(
    operatingInflows: inflows,
    operatingOutflows: outflows,
    netOperating: inflows - outflows,
    openingBalance: openingBalance,
    closingBalance: openingBalance + (inflows - outflows),
    lineItems: items,
  );
});

// ─── Balance Sheet ────────────────────────────────────────────────────────────

class BalanceSheet {
  // Assets
  final double cashAndEquivalents;
  final double accountsReceivable;
  final double inventoryValue;
  final double totalCurrentAssets;
  final double totalAssets;

  // Liabilities
  final double accountsPayable;
  final double totalCurrentLiabilities;
  final double totalLiabilities;

  // Equity
  final double ownersEquity;

  const BalanceSheet({
    required this.cashAndEquivalents,
    required this.accountsReceivable,
    required this.inventoryValue,
    required this.totalCurrentAssets,
    required this.totalAssets,
    required this.accountsPayable,
    required this.totalCurrentLiabilities,
    required this.totalLiabilities,
    required this.ownersEquity,
  });
}

final balanceSheetProvider = Provider<BalanceSheet>((ref) {
  final accounts = ref.watch(allCashAccountsProvider);
  final allInvoices = ref.watch(salesInvoiceListProvider).maybeWhen(
        data: (d) => d,
        orElse: () => <Map<String, dynamic>>[],
      );
  final allExpenses = ref.watch(expenseListProvider).maybeWhen(
        data: (d) => d,
        orElse: () => <Expense>[],
      );
  final inventory = ref.watch(allInventoryProvider);

  final cash = accounts.fold(0.0, (s, a) => s + _parseAmount(a.balance));

  double ar = 0;
  for (final inv in allInvoices) {
    final status = (inv['status'] ?? inv['paymentStatus'] ?? '').toString().toLowerCase();
    if (status != 'paid' && status != 'completed') {
      ar += _parseAmount(inv['totalAmount'] ?? inv['total'] ?? inv['amount']);
    }
  }

  double invValue = 0;
  for (final item in inventory) {
    final stock = (item['currentStock'] as num?)?.toDouble() ?? 0;
    final price = (item['unitPrice'] as num?)?.toDouble() ?? 0;
    invValue += stock * price;
  }

  final totalCurrentAssets = cash + ar + invValue;

  double ap = 0;
  for (final e in allExpenses) {
    if (e.status == 'pending') {
      ap += _parseAmount(e.amount);
    }
  }

  final totalLiabilities = ap;
  final equity = totalCurrentAssets - totalLiabilities;

  return BalanceSheet(
    cashAndEquivalents: cash,
    accountsReceivable: ar,
    inventoryValue: invValue,
    totalCurrentAssets: totalCurrentAssets,
    totalAssets: totalCurrentAssets,
    accountsPayable: ap,
    totalCurrentLiabilities: ap,
    totalLiabilities: totalLiabilities,
    ownersEquity: equity,
  );
});

// ─── Inventory Valuation ──────────────────────────────────────────────────────

class InventoryValuationItem {
  final String id;
  final String name;
  final String category;
  final String sku;
  final double stock;
  final double unitPrice;
  final double totalValue;
  final String unit;

  const InventoryValuationItem({
    required this.id,
    required this.name,
    required this.category,
    required this.sku,
    required this.stock,
    required this.unitPrice,
    required this.totalValue,
    required this.unit,
  });
}

class InventoryValuationReport {
  final List<InventoryValuationItem> items;
  final double totalValue;
  final Map<String, double> byCategory;
  final int totalSkus;
  final double totalUnits;

  const InventoryValuationReport({
    required this.items,
    required this.totalValue,
    required this.byCategory,
    required this.totalSkus,
    required this.totalUnits,
  });
}

final inventoryValuationProvider = Provider<InventoryValuationReport>((ref) {
  final inventory = ref.watch(allInventoryProvider);

  final List<InventoryValuationItem> items = [];
  final Map<String, double> byCategory = {};
  double totalValue = 0;
  double totalUnits = 0;

  for (final raw in inventory) {
    final isActive = raw['isActive'] as bool? ?? true;
    if (!isActive) continue;

    final item = InventoryItem.fromFirestore(Map<String, dynamic>.from(raw), raw['id'] as String? ?? '');
    final value = item.currentStock * item.unitPrice;
    totalValue += value;
    totalUnits += item.currentStock;
    byCategory[item.category] = (byCategory[item.category] ?? 0) + value;

    items.add(InventoryValuationItem(
      id: item.id,
      name: item.name,
      category: item.category,
      sku: item.sku,
      stock: item.currentStock,
      unitPrice: item.unitPrice,
      totalValue: value,
      unit: item.unit,
    ));
  }

  items.sort((a, b) => b.totalValue.compareTo(a.totalValue));

  return InventoryValuationReport(
    items: items,
    totalValue: totalValue,
    byCategory: byCategory,
    totalSkus: items.length,
    totalUnits: totalUnits,
  );
});
