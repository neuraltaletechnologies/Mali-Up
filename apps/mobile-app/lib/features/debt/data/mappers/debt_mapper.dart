import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/models/debt.dart';

abstract final class DebtMapper {
  // ─── Drift row → domain ────────────────────────────────────────────────────

  static Debt fromRow(DebtsTableData row) {
    return Debt(
      id: row.id,
      partyName: row.partyName,
      partyPhone: row.partyPhone,
      partyId: row.partyId,
      type: row.type,
      originalAmount: row.originalAmount,
      paidAmount: row.paidAmount,
      dueDate: row.dueDate,
      status: row.status,
      invoiceRef: row.invoiceRef,
      note: row.note,
      createdBy: row.createdBy,
      createdAt: row.debtCreatedAt,
      isWrittenOff: row.isWrittenOff == 1,
      writeOffReason: row.writeOffReason,
      writtenOffBy: row.writtenOffBy,
      writtenOffAt: row.writtenOffAt,
    );
  }

  // ─── domain → Drift companion ──────────────────────────────────────────────

  static DebtsTableCompanion toCompanion(
    Debt debt, {
    required String businessId,
    required String syncStatus,
    required int localVersion,
    required int createdAtMs,
    int? serverUpdatedAt,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final id = debt.id.isNotEmpty ? debt.id : const Uuid().v4();
    return DebtsTableCompanion(
      id: Value(id),
      businessId: Value(businessId),
      partyName: Value(debt.partyName),
      partyPhone: Value(debt.partyPhone),
      partyId: Value(debt.partyId),
      type: Value(debt.type),
      originalAmount: Value(debt.originalAmount),
      paidAmount: Value(debt.paidAmount),
      dueDate: Value(debt.dueDate),
      status: Value(debt.status),
      invoiceRef: Value(debt.invoiceRef),
      note: Value(debt.note),
      createdBy: Value(debt.createdBy),
      debtCreatedAt: Value(debt.createdAt),
      isWrittenOff: Value(debt.isWrittenOff ? 1 : 0),
      writeOffReason: Value(debt.writeOffReason),
      writtenOffBy: Value(debt.writtenOffBy),
      writtenOffAt: Value(debt.writtenOffAt),
      createdAt: Value(createdAtMs),
      updatedAt: Value(now),
      serverUpdatedAt: Value(serverUpdatedAt),
      syncStatus: Value(syncStatus),
      localVersion: Value(localVersion),
      isDeleted: const Value(0),
    );
  }

  // ─── Firestore → domain ────────────────────────────────────────────────────

  static Debt fromFirestore(Map<String, dynamic> data, String id) {
    return Debt.fromFirestore(data, id);
  }
}

// ─── DebtPayment mapper ────────────────────────────────────────────────────────

abstract final class DebtPaymentMapper {
  static DebtPayment fromRow(DebtPaymentsTableData row) {
    return DebtPayment(
      id: row.id,
      amount: row.amount,
      date: row.date,
      method: row.method,
      note: row.note,
      recordedBy: row.recordedBy,
      accountId: row.accountId,
    );
  }

  static DebtPaymentsTableCompanion toCompanion(
    DebtPayment payment, {
    required String debtId,
    required String businessId,
    required String syncStatus,
    required int createdAtMs,
    int? serverUpdatedAt,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final id = payment.id.isNotEmpty ? payment.id : const Uuid().v4();
    return DebtPaymentsTableCompanion(
      id: Value(id),
      debtId: Value(debtId),
      businessId: Value(businessId),
      amount: Value(payment.amount),
      date: Value(payment.date),
      method: Value(payment.method),
      note: Value(payment.note),
      recordedBy: Value(payment.recordedBy),
      accountId: Value(payment.accountId),
      createdAt: Value(createdAtMs),
      updatedAt: Value(now),
      serverUpdatedAt: Value(serverUpdatedAt),
      syncStatus: Value(syncStatus),
      isDeleted: const Value(0),
    );
  }

  static DebtPayment fromFirestore(Map<String, dynamic> data, String id) {
    return DebtPayment.fromFirestore(data, id);
  }

  static Map<String, dynamic> toFirestore(DebtPayment payment) {
    return payment.toFirestore();
  }
}

