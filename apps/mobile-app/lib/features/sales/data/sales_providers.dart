import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../invoice/domain/models/invoice.dart';
import '../../invoice/presentation/providers/invoice_providers.dart';

// ── Offline-first sales stream ────────────────────────────────────────────────
//
// Reads from Drift via invoicesProvider (kept in sync by SyncService).
// The raw-map shape is preserved so all existing consumers (SalesScreen,
// dashboard widgets) require zero changes.

final salesInvoiceListProvider =
    Provider<AsyncValue<List<Map<String, dynamic>>>>((ref) {
  return ref.watch(invoicesProvider).whenData(
        (invoices) => invoices.map(_invoiceToMap).toList(),
      );
});

Map<String, dynamic> _invoiceToMap(Invoice inv) => {
      'id': inv.id,
      'customerId': inv.customerId,
      'customerName': inv.customerName,
      'invoiceNumber': inv.invoiceNumber,
      'date': inv.date,
      'dueDate': inv.dueDate,
      'status': inv.status,
      'paymentStatus': inv.status,
      'subtotal': inv.subtotal,
      'tax': inv.tax,
      'total': inv.total,
      'totalAmount': inv.total,
      'amount': inv.total,
      'items': inv.items.map((i) => i.toFirestore()).toList(),
      'note': inv.note,
      'createdAt': inv.createdAt,
      'updatedAt': inv.updatedAt,
    };

/// Reads the invoice total from either the quick-sale field ('amount') or the
/// full-invoice field ('totalAmount'), whichever is present and non-zero.
double readInvoiceTotal(Map<String, dynamic> item) {
  final a = parseNumericAmount(item['totalAmount']);
  if (a > 0) return a;
  return parseNumericAmount(item['amount']);
}

double parseNumericAmount(Object? value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  final cleaned = value
      .toString()
      .replaceAll(RegExp(r'[^0-9.\-]'), '')
      .trim();
  return double.tryParse(cleaned) ?? 0;
}

String readInvoiceStatus(Map<String, dynamic> item) {
  final raw = (item['status'] ?? item['paymentStatus'] ?? '').toString().trim();
  if (raw.isEmpty) return 'Pending';
  return raw;
}

DateTime? readTimestamp(Object? value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}
