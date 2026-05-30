import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/repositories/context_firestore_repository.dart';
import '../../customer/data/customer_providers.dart';

final salesInvoiceListProvider = StreamProvider<List<Map<String, dynamic>>>((ref) async* {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    yield const <Map<String, dynamic>>[];
    return;
  }
  final businessAsync = ref.watch(currentBusinessIdProvider);
  if (businessAsync.isLoading) {
    return;
  }
  final bizId = businessAsync.valueOrNull;
  if (bizId == null || bizId.isEmpty) {
    yield const <Map<String, dynamic>>[];
    return;
  }
  final repository = ref.read(contextFirestoreRepositoryProvider);
  final collection = repository.scopeCollection(
    uid: user.uid,
    context: ResolvedFinanceContext.business(bizId),
    childCollection: 'sales_invoices',
  );
  yield* collection
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());
});

double parseNumericAmount(Object? value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  final cleaned = value
      .toString()
      .replaceAll(RegExp(r'[^0-9.\-]'), '')
      .trim();
  return double.tryParse(cleaned) ?? 0;
}

String readInvoiceStatus(Map<String, dynamic> item) {
  final raw = (item['status'] ?? item['paymentStatus'] ?? '').toString().trim();
  if (raw.isEmpty) return 'Pending';
  return raw;
}

DateTime? readTimestamp(Object? value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}
