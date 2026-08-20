import 'package:drift/drift.dart';

import 'invoices_table.dart';

class InvoiceItemsTable extends Table {
  @override
  String get tableName => 'invoice_items';

  // Always a freshly generated row id — never the linked product's id, since
  // the same product is sold across many invoices and this is the table's
  // primary key (see productId below for the catalog link).
  TextColumn get id => text()();
  TextColumn get invoiceId =>
      text().references(InvoicesTable, #id, onDelete: KeyAction.cascade)();
  TextColumn get name => text()();
  TextColumn get description => text().withDefault(const Constant(''))();
  RealColumn get quantity => real()();
  RealColumn get unitPrice => real()();
  RealColumn get total => real()();
  // Inventory/catalog item this line was sold from. Empty for services and
  // free-text lines with no stock link. Used to restock on returns and to
  // round-trip InvoiceItem.id through Firestore's `productId` field.
  TextColumn get productId => text().withDefault(const Constant(''))();

  @override
  Set<Column> get primaryKey => {id};
}
