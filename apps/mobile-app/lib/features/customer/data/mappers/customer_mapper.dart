import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/models/customer.dart';

abstract final class CustomerMapper {
  // ─── Drift row → domain ────────────────────────────────────────────────────

  static Customer fromRow(CustomersTableData row) {
    final tags = _decodeTags(row.tags);
    return Customer(
      id: row.id,
      name: row.name,
      phone: row.phone,
      email: row.email,
      balance: row.balance.toStringAsFixed(2),
      lastTransactionDate: row.lastTransactionDate,
      tags: tags,
      isOrganisation: row.isOrganisation == 1,
      tinNumber: row.tinNumber,
      address: row.address,
      creditLimit: row.creditLimit,
    );
  }

  // ─── domain → Drift companion ──────────────────────────────────────────────

  static CustomersTableCompanion toCompanion(
    Customer customer, {
    required String businessId,
    required String syncStatus,
    required int localVersion,
    required int createdAtMs,
    int? serverUpdatedAt,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final id =
        customer.id.isNotEmpty ? customer.id : const Uuid().v4();
    return CustomersTableCompanion(
      id: Value(id),
      businessId: Value(businessId),
      name: Value(customer.name),
      phone: Value(customer.phone),
      email: Value(customer.email),
      balance: Value(double.tryParse(customer.balance) ?? 0),
      lastTransactionDate: Value(customer.lastTransactionDate),
      tags: Value(jsonEncode(customer.tags)),
      isOrganisation: Value(customer.isOrganisation ? 1 : 0),
      tinNumber: Value(customer.tinNumber),
      address: Value(customer.address),
      creditLimit: Value(customer.creditLimit),
      createdAt: Value(createdAtMs),
      updatedAt: Value(now),
      serverUpdatedAt: Value(serverUpdatedAt),
      syncStatus: Value(syncStatus),
      localVersion: Value(localVersion),
      isDeleted: const Value(0),
    );
  }

  // ─── Firestore data → domain ───────────────────────────────────────────────

  static Customer fromFirestore(Map<String, dynamic> data, String id) {
    return Customer.fromFirestore(data, id);
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  static List<String> _decodeTags(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) return List<String>.from(decoded);
    } catch (_) {}
    return const [];
  }
}
