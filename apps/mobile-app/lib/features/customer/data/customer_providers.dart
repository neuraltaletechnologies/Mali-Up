import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/repositories/context_firestore_repository.dart';
import '../../../core/providers/database_provider.dart';
import '../../rbac/data/rbac_providers.dart';
import 'mappers/customer_mapper.dart';
import '../domain/models/customer.dart';

DateTime? _toDateTime(dynamic v) {
  if (v is Timestamp) return v.toDate();
  if (v is DateTime) return v;
  if (v is String) {
    try {
      return DateTime.parse(v);
    } catch (_) {
      return null;
    }
  }
  return null;
}

final contextFirestoreRepositoryProvider = Provider<ContextFirestoreRepository>((ref) {
  return ContextFirestoreRepository();
});

/// Streams the active businessId from the user's Firestore profile.
/// Re-emits whenever the user switches business or their profile updates,
/// causing all downstream data providers to restart with the new context.
final currentBusinessIdProvider = StreamProvider<String>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return Stream.value('');
  final repo = ref.read(contextFirestoreRepositoryProvider);
  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .snapshots()
      .map((snap) => repo.resolveContextFromData(snap.data()).businessId ?? '');
});

/// Offline-first customer stream backed by Drift.
/// Uses the DAO + CustomerMapper directly to avoid circular imports
/// with the presentation layer.
final customerListProvider = StreamProvider<List<Customer>>((ref) {
  final db = ref.watch(_customerDatabaseProvider);
  final bizId = ref.watch(currentBusinessIdProvider).valueOrNull ?? '';
  if (bizId.isEmpty) return Stream.value(const []);
  return db.customerDao
      .watchAll(bizId)
      .map((rows) => rows.map(CustomerMapper.fromRow).toList());
});

final _customerDatabaseProvider = Provider((ref) =>
    ref.watch(appDatabaseProvider));

// Invoices belonging to a specific customer
final customerInvoicesProvider =
    StreamProvider.family<List<Map<String, dynamic>>, String>((ref, customerId) async* {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null || customerId.isEmpty) {
    yield const [];
    return;
  }
  final ownerUid = ref.watch(tenantOwnerUidProvider) ?? user.uid;
  final businessAsync = ref.watch(currentBusinessIdProvider);
  if (businessAsync.isLoading) {
    return;
  }
  final bizId = businessAsync.valueOrNull;
  if (bizId == null || bizId.isEmpty) {
    yield const [];
    return;
  }
  final repo = ref.read(contextFirestoreRepositoryProvider);
  final col = repo.scopeCollection(
    uid: ownerUid,
    context: ResolvedFinanceContext.business(bizId),
    childCollection: 'sales_invoices',
  );
  // No composite index needed: filter only, sort client-side.
  yield* col
      .where('customerId', isEqualTo: customerId)
      .snapshots()
      .map((s) {
        final docs =
            s.docs.map((d) => {'id': d.id, ...d.data()}).toList();
        docs.sort((a, b) {
          final at = _toDateTime(a['createdAt']);
          final bt = _toDateTime(b['createdAt']);
          if (at == null && bt == null) return 0;
          if (at == null) return 1;
          if (bt == null) return -1;
          return bt.compareTo(at); // descending: newest first
        });
        return docs;
      });
});

// Communication log / notes per customer (subcollection)
final customerNotesProvider =
    StreamProvider.family<List<Map<String, dynamic>>, String>((ref, customerId) async* {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null || customerId.isEmpty) {
    yield const [];
    return;
  }
  final ownerUid = ref.watch(tenantOwnerUidProvider) ?? user.uid;
  final businessAsync = ref.watch(currentBusinessIdProvider);
  if (businessAsync.isLoading) {
    return;
  }
  final bizId = businessAsync.valueOrNull;
  if (bizId == null || bizId.isEmpty) {
    yield const [];
    return;
  }
  final repo = ref.read(contextFirestoreRepositoryProvider);
  final customersCol = repo.scopeCollection(
    uid: ownerUid,
    context: ResolvedFinanceContext.business(bizId),
    childCollection: 'customers',
  );
  yield* customersCol
      .doc(customerId)
      .collection('notes')
      .orderBy('addedAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());
});

