// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'debt_dao.dart';

// ignore_for_file: type=lint
mixin _$DebtDaoMixin on DatabaseAccessor<AppDatabase> {
  $DebtsTableTable get debtsTable => attachedDatabase.debtsTable;
  $DebtPaymentsTableTable get debtPaymentsTable =>
      attachedDatabase.debtPaymentsTable;
  DebtDaoManager get managers => DebtDaoManager(this);
}

class DebtDaoManager {
  final _$DebtDaoMixin _db;
  DebtDaoManager(this._db);
  $$DebtsTableTableTableManager get debtsTable =>
      $$DebtsTableTableTableManager(_db.attachedDatabase, _db.debtsTable);
  $$DebtPaymentsTableTableTableManager get debtPaymentsTable =>
      $$DebtPaymentsTableTableTableManager(
        _db.attachedDatabase,
        _db.debtPaymentsTable,
      );
}
