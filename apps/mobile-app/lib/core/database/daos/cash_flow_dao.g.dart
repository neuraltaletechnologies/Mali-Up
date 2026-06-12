// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cash_flow_dao.dart';

// ignore_for_file: type=lint
mixin _$CashFlowDaoMixin on DatabaseAccessor<AppDatabase> {
  $CashAccountsTableTable get cashAccountsTable =>
      attachedDatabase.cashAccountsTable;
  $CashTransactionsTableTable get cashTransactionsTable =>
      attachedDatabase.cashTransactionsTable;
  $DailyReconciliationsTableTable get dailyReconciliationsTable =>
      attachedDatabase.dailyReconciliationsTable;
  CashFlowDaoManager get managers => CashFlowDaoManager(this);
}

class CashFlowDaoManager {
  final _$CashFlowDaoMixin _db;
  CashFlowDaoManager(this._db);
  $$CashAccountsTableTableTableManager get cashAccountsTable =>
      $$CashAccountsTableTableTableManager(
        _db.attachedDatabase,
        _db.cashAccountsTable,
      );
  $$CashTransactionsTableTableTableManager get cashTransactionsTable =>
      $$CashTransactionsTableTableTableManager(
        _db.attachedDatabase,
        _db.cashTransactionsTable,
      );
  $$DailyReconciliationsTableTableTableManager get dailyReconciliationsTable =>
      $$DailyReconciliationsTableTableTableManager(
        _db.attachedDatabase,
        _db.dailyReconciliationsTable,
      );
}
