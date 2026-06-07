import 'package:drift/drift.dart';

import 'invoices_table.dart';

class InvoiceItemsTable extends Table {
  @override
  String get tableName => 'invoice_items';

  TextColumn get id => text()();
  TextColumn get invoiceId =>
      text().references(InvoicesTable, #id, onDelete: KeyAction.cascade)();
  TextColumn get name => text()();
  TextColumn get description => text().withDefault(const Constant(''))();
  RealColumn get quantity => real()();
  RealColumn get unitPrice => real()();
  RealColumn get total => real()();

  @override
  Set<Column> get primaryKey => {id};
}
