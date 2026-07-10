import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/models/invoice.dart';

abstract final class InvoiceMapper {
  // ─── Drift row → domain ────────────────────────────────────────────────────

  static Invoice fromRow(
    InvoicesTableData row,
    List<InvoiceItemsTableData> items,
  ) {
    return Invoice(
      id: row.id,
      customerId: row.customerId,
      customerName: row.customerName,
      customerPhone: row.customerPhone,
      invoiceNumber: row.invoiceNumber,
      date: row.date,
      dueDate: row.dueDate,
      status: row.status,
      type: row.docType,
      subtotal: row.subtotal,
      discountAmount: row.discountAmount,
      tax: row.tax,
      total: row.total,
      amountPaid: row.amountPaid,
      paymentMethod: row.paymentMethod,
      paymentAccountId: row.paymentAccountId,
      items: items.map(_itemFromRow).toList(),
      note: row.note,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt)
          .toIso8601String(),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAt)
          .toIso8601String(),
    );
  }

  static InvoiceItem _itemFromRow(InvoiceItemsTableData r) {
    return InvoiceItem(
      id: r.id,
      name: r.name,
      description: r.description,
      quantity: r.quantity,
      unitPrice: r.unitPrice,
      total: r.total,
    );
  }

  // ─── domain → Drift companion ──────────────────────────────────────────────

  static InvoicesTableCompanion toCompanion(
    Invoice invoice, {
    required String businessId,
    required String syncStatus,
    required int localVersion,
    required int createdAtMs,
    int? serverUpdatedAt,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return InvoicesTableCompanion(
      id: Value(invoice.id),
      businessId: Value(businessId),
      customerId: Value(invoice.customerId),
      customerName: Value(invoice.customerName),
      customerPhone: Value(invoice.customerPhone),
      invoiceNumber: Value(invoice.invoiceNumber),
      date: Value(invoice.date),
      dueDate: Value(invoice.dueDate),
      status: Value(invoice.status),
      docType: Value(invoice.type),
      subtotal: Value(invoice.subtotal),
      discountAmount: Value(invoice.discountAmount),
      tax: Value(invoice.tax),
      total: Value(invoice.total),
      amountPaid: Value(invoice.amountPaid),
      paymentMethod: Value(invoice.paymentMethod),
      paymentAccountId: Value(invoice.paymentAccountId),
      note: Value(invoice.note),
      createdAt: Value(createdAtMs),
      updatedAt: Value(now),
      serverUpdatedAt: Value(serverUpdatedAt),
      syncStatus: Value(syncStatus),
      localVersion: Value(localVersion),
      isDeleted: const Value(0),
    );
  }

  static List<InvoiceItemsTableCompanion> toItemCompanions(
    List<InvoiceItem> items,
    String invoiceId,
  ) {
    return items.map((item) {
      return InvoiceItemsTableCompanion(
        id: Value(item.id.isNotEmpty ? item.id : const Uuid().v4()),
        invoiceId: Value(invoiceId),
        name: Value(item.name),
        description: Value(item.description),
        quantity: Value(item.quantity),
        unitPrice: Value(item.unitPrice),
        total: Value(item.total),
      );
    }).toList();
  }

  // ─── Firestore data → domain ───────────────────────────────────────────────

  static Invoice fromFirestore(Map<String, dynamic> data, String id) {
    return Invoice.fromFirestore(data, id);
  }
}
