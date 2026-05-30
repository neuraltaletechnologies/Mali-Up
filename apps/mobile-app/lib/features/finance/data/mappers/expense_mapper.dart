import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/models/expense.dart';

abstract final class ExpenseMapper {
  // ─── Drift row → domain ────────────────────────────────────────────────────

  static Expense fromRow(ExpensesTableData row) {
    return Expense(
      id: row.id,
      category: row.category,
      // domain stores amount as String to preserve formatting
      amount: row.amount.toStringAsFixed(2),
      date: row.date,
      note: row.note,
      recipient: row.recipient,
      isRecurring: row.isRecurring == 1,
      recurrenceType: row.recurrenceType,
      nextDueDate: row.nextDueDate,
      templateId: row.templateId,
      receiptUrl: row.receiptUrl,
      paymentMethod: row.paymentMethod,
      status: row.status,
      approvedBy: row.approvedBy,
      createdBy: row.createdBy,
    );
  }

  // ─── domain → Drift companion ──────────────────────────────────────────────

  static ExpensesTableCompanion toCompanion(
    Expense expense, {
    required String businessId,
    required String syncStatus,
    required int localVersion,
    required int createdAtMs,
    int? serverUpdatedAt,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final id =
        expense.id.isNotEmpty ? expense.id : const Uuid().v4();
    return ExpensesTableCompanion(
      id: Value(id),
      businessId: Value(businessId),
      category: Value(expense.category),
      amount: Value(double.tryParse(expense.amount) ?? 0),
      date: Value(expense.date),
      note: Value(expense.note),
      recipient: Value(expense.recipient),
      isRecurring: Value(expense.isRecurring ? 1 : 0),
      recurrenceType: Value(expense.recurrenceType),
      nextDueDate: Value(expense.nextDueDate),
      templateId: Value(expense.templateId),
      receiptUrl: Value(expense.receiptUrl),
      paymentMethod: Value(expense.paymentMethod),
      status: Value(expense.status),
      approvedBy: Value(expense.approvedBy),
      createdBy: Value(expense.createdBy),
      createdAt: Value(createdAtMs),
      updatedAt: Value(now),
      serverUpdatedAt: Value(serverUpdatedAt),
      syncStatus: Value(syncStatus),
      localVersion: Value(localVersion),
      isDeleted: const Value(0),
    );
  }

  // ─── Firestore data → domain ───────────────────────────────────────────────

  static Expense fromFirestore(Map<String, dynamic> data, String id) {
    return Expense.fromFirestore(data, id);
  }
}
