import 'package:drift/drift.dart';

class InvoicesTable extends Table {
  @override
  String get tableName => 'invoices';

  TextColumn get id => text()();
  TextColumn get businessId => text()();
  TextColumn get customerId => text()();
  TextColumn get customerName => text()();
  TextColumn get customerPhone => text().withDefault(const Constant(''))();
  TextColumn get invoiceNumber => text()();
  TextColumn get date => text()();
  TextColumn get dueDate => text()();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  // 'invoice' | 'quotation'
  TextColumn get docType => text().withDefault(const Constant('invoice'))();
  RealColumn get subtotal => real()();
  RealColumn get discountAmount => real().withDefault(const Constant(0))();
  RealColumn get tax => real()();
  RealColumn get total => real()();
  RealColumn get amountPaid => real().withDefault(const Constant(0))();
  TextColumn get paymentMethod => text().withDefault(const Constant(''))();
  TextColumn get paymentAccountId => text().withDefault(const Constant(''))();
  TextColumn get note => text().withDefault(const Constant(''))();
  TextColumn get createdBy => text().withDefault(const Constant(''))();

  // Timestamps stored as unix milliseconds for precise comparison
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  // Last updatedAt confirmed by Firestore — null until first sync
  IntColumn get serverUpdatedAt => integer().nullable()();

  // Sync state machine
  TextColumn get syncStatus =>
      text().withDefault(const Constant('pending_create'))();
  IntColumn get localVersion => integer().withDefault(const Constant(1))();
  // Soft delete: 1 = deleted, stays in table until sync confirms deletion
  IntColumn get isDeleted => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}
