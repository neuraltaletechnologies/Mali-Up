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
      createdBy: row.createdBy,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        row.createdAt,
      ).toIso8601String(),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        row.updatedAt,
      ).toIso8601String(),
      hasReturn: row.hasReturn != 0,
      returnedAmount: row.returnedAmount,
      creditNoteNumber: row.creditNoteNumber,
    );
  }

  static InvoiceItem _itemFromRow(InvoiceItemsTableData r) {
    return InvoiceItem(
      // productId is the catalog link (empty for services/free-text lines
      // and for rows written before this column existed); r.id itself was
      // the catalog link for those older rows, so it's the right fallback.
      id: r.productId.isNotEmpty ? r.productId : r.id,
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
      createdBy: Value(invoice.createdBy),
      createdAt: Value(createdAtMs),
      updatedAt: Value(now),
      hasReturn: Value(invoice.hasReturn ? 1 : 0),
      returnedAmount: Value(invoice.returnedAmount),
      creditNoteNumber: Value(invoice.creditNoteNumber),
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
        // Always a fresh row id — see the productId comment on the table for
        // why this can no longer just reuse the catalog item's id.
        id: Value(const Uuid().v4()),
        invoiceId: Value(invoiceId),
        name: Value(item.name),
        description: Value(item.description),
        quantity: Value(item.quantity),
        unitPrice: Value(item.unitPrice),
        total: Value(item.total),
        productId: Value(item.id),
      );
    }).toList();
  }

  // ─── Firestore data → domain ───────────────────────────────────────────────

  static Invoice fromFirestore(Map<String, dynamic> data, String id) {
    return Invoice.fromFirestore(data, id);
  }
}
