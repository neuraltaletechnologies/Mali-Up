import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/repositories/context_firestore_repository.dart';
import '../domain/models/customer.dart';

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

final customerListProvider = StreamProvider<List<Customer>>((ref) async* {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    yield const <Customer>[];
    return;
  }
  final bizId = ref.watch(currentBusinessIdProvider).valueOrNull;
  if (bizId == null || bizId.isEmpty) {
    yield const <Customer>[];
    return;
  }
  final repo = ref.read(contextFirestoreRepositoryProvider);
  yield* repo.watchCustomers(
    uid: user.uid,
    context: ResolvedFinanceContext.business(bizId),
  );
});

// Invoices belonging to a specific customer
final customerInvoicesProvider =
    StreamProvider.family<List<Map<String, dynamic>>, String>((ref, customerId) async* {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null || customerId.isEmpty) {
    yield const [];
    return;
  }
  final bizId = ref.watch(currentBusinessIdProvider).valueOrNull;
  if (bizId == null || bizId.isEmpty) {
    yield const [];
    return;
  }
  final repo = ref.read(contextFirestoreRepositoryProvider);
  final col = repo.scopeCollection(
    uid: user.uid,
    context: ResolvedFinanceContext.business(bizId),
    childCollection: 'sales_invoices',
  );
  yield* col
      .where('customerId', isEqualTo: customerId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());
});

// Communication log / notes per customer (subcollection)
final customerNotesProvider =
    StreamProvider.family<List<Map<String, dynamic>>, String>((ref, customerId) async* {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null || customerId.isEmpty) {
    yield const [];
    return;
  }
  final bizId = ref.watch(currentBusinessIdProvider).valueOrNull;
  if (bizId == null || bizId.isEmpty) {
    yield const [];
    return;
  }
  final repo = ref.read(contextFirestoreRepositoryProvider);
  final customersCol = repo.scopeCollection(
    uid: user.uid,
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

