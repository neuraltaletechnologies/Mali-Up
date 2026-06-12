import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/models/cash_account.dart';
import '../../domain/models/cash_transaction.dart';
import '../../domain/models/daily_reconciliation.dart';

abstract final class CashAccountMapper {
  // ─── Drift row → domain ────────────────────────────────────────────────────

  static CashAccount fromRow(CashAccountsTableData row) {
    return CashAccount(
      id: row.id,
      name: row.name,
      type: row.type,
      balance: row.balance,
      accountNumber:
          row.accountNumber.isNotEmpty ? row.accountNumber : null,
      currency: row.currency,
      lastReconciled: row.lastReconciled,
    );
  }

  // ─── domain → Drift companion ──────────────────────────────────────────────

  static CashAccountsTableCompanion toCompanion(
    CashAccount account, {
    required String businessId,
    required String syncStatus,
    required int localVersion,
    required int createdAtMs,
    int? serverUpdatedAt,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final id = account.id.isNotEmpty ? account.id : const Uuid().v4();
    return CashAccountsTableCompanion(
      id: Value(id),
      businessId: Value(businessId),
      name: Value(account.name),
      type: Value(account.type),
      balance: Value(account.balance),
      accountNumber: Value(account.accountNumber ?? ''),
      currency: Value(account.currency),
      lastReconciled: Value(account.lastReconciled),
      createdAt: Value(createdAtMs),
      updatedAt: Value(now),
      serverUpdatedAt: Value(serverUpdatedAt),
      syncStatus: Value(syncStatus),
      localVersion: Value(localVersion),
      isDeleted: const Value(0),
    );
  }

  // ─── Firestore → domain ────────────────────────────────────────────────────

  static CashAccount fromFirestore(Map<String, dynamic> data, String id) {
    return CashAccount.fromFirestore(data, id);
  }
}

abstract final class CashTransactionMapper {
  static CashTransaction fromRow(CashTransactionsTableData row) {
    return CashTransaction(
      id: row.id,
      type: row.type,
      amount: row.amount,
      fromAccountId: row.fromAccountId,
      toAccountId: row.toAccountId,
      description: row.description,
      date: row.date,
      reference: row.reference,
      activityCategory: row.activityCategory,
      createdBy: row.createdBy,
    );
  }

  static CashTransactionsTableCompanion toCompanion(
    CashTransaction txn, {
    required String businessId,
    required String syncStatus,
    required int createdAtMs,
    int? serverUpdatedAt,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final id = txn.id.isNotEmpty ? txn.id : const Uuid().v4();
    return CashTransactionsTableCompanion(
      id: Value(id),
      businessId: Value(businessId),
      type: Value(txn.type),
      amount: Value(txn.amount),
      fromAccountId: Value(txn.fromAccountId),
      toAccountId: Value(txn.toAccountId),
      description: Value(txn.description),
      date: Value(txn.date),
      reference: Value(txn.reference),
      activityCategory: Value(txn.activityCategory),
      createdBy: Value(txn.createdBy),
      createdAt: Value(createdAtMs),
      updatedAt: Value(now),
      serverUpdatedAt: Value(serverUpdatedAt),
      syncStatus: Value(syncStatus),
      isDeleted: const Value(0),
    );
  }

  static CashTransaction fromFirestore(Map<String, dynamic> data, String id) {
    return CashTransaction.fromFirestore(data, id);
  }
}

abstract final class ReconciliationMapper {
  /// Deterministic doc id — one reconciliation per account per day.
  /// Makes offline retries and concurrent saves idempotent.
  static String deterministicId(String accountId, String date) =>
      '${accountId}_$date';

  static DailyReconciliation fromRow(DailyReconciliationsTableData row) {
    return DailyReconciliation(
      id: row.id,
      accountId: row.accountId,
      date: row.date,
      openingBalance: row.openingBalance,
      closingBalance: row.closingBalance,
      totalDeposits: row.totalDeposits,
      totalWithdrawals: row.totalWithdrawals,
      notes: row.notes,
      reconciledBy: row.reconciledBy,
      isReconciled: row.isReconciled == 1,
    );
  }

  static DailyReconciliationsTableCompanion toCompanion(
    DailyReconciliation rec, {
    required String businessId,
    required String syncStatus,
    required int createdAtMs,
    int? serverUpdatedAt,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final id = rec.id.isNotEmpty
        ? rec.id
        : deterministicId(rec.accountId, rec.date);
    return DailyReconciliationsTableCompanion(
      id: Value(id),
      businessId: Value(businessId),
      accountId: Value(rec.accountId),
      date: Value(rec.date),
      openingBalance: Value(rec.openingBalance),
      closingBalance: Value(rec.closingBalance),
      totalDeposits: Value(rec.totalDeposits),
      totalWithdrawals: Value(rec.totalWithdrawals),
      notes: Value(rec.notes),
      reconciledBy: Value(rec.reconciledBy),
      isReconciled: Value(rec.isReconciled ? 1 : 0),
      createdAt: Value(createdAtMs),
      updatedAt: Value(now),
      serverUpdatedAt: Value(serverUpdatedAt),
      syncStatus: Value(syncStatus),
      isDeleted: const Value(0),
    );
  }

  static DailyReconciliation fromFirestore(
      Map<String, dynamic> data, String id) {
    return DailyReconciliation.fromFirestore(data, id);
  }
}
