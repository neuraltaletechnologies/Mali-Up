import '../domain/models/customer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/data/repositories/context_firestore_repository.dart';

final contextFirestoreRepositoryProvider = Provider<ContextFirestoreRepository>((ref) {
  return ContextFirestoreRepository();
});

final customerListProvider = StreamProvider<List<Customer>>((ref) async* {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    yield const <Customer>[];
    return;
  }

  final repository = ref.watch(contextFirestoreRepositoryProvider);
  final context = await repository.resolveContextForUser(user.uid);

  yield* repository.watchCustomers(uid: user.uid, context: context);
});

// Invoices belonging to a specific customer
final customerInvoicesProvider =
    StreamProvider.family<List<Map<String, dynamic>>, String>((ref, customerId) async* {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null || customerId.isEmpty) {
    yield const [];
    return;
  }
  final repo = ref.watch(contextFirestoreRepositoryProvider);
  final ctx = await repo.resolveContextForUser(user.uid);
  final col = repo.scopeCollection(
      uid: user.uid, context: ctx, childCollection: 'sales_invoices');
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
  final repo = ref.watch(contextFirestoreRepositoryProvider);
  final ctx = await repo.resolveContextForUser(user.uid);
  final customersCol =
      repo.scopeCollection(uid: user.uid, context: ctx, childCollection: 'customers');
  yield* customersCol
      .doc(customerId)
      .collection('notes')
      .orderBy('addedAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());
});

