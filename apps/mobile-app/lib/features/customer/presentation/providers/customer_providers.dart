import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/business_id_provider.dart';
import '../../../../core/providers/sync_provider.dart';
import '../../data/repositories/sync_customer_repository.dart';
import '../../domain/models/customer.dart';

final customerRepositoryProvider = Provider<SyncCustomerRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
  final bizId = ref.watch(currentBusinessIdProvider).valueOrNull ?? '';
  final policy = ref.watch(offlinePolicyProvider);
  return SyncCustomerRepository(db: db, uid: uid, businessId: bizId, policy: policy);
});

/// Live stream of all non-deleted customers, ordered by name.
/// Backed by Drift — works fully offline.
final customersProvider = StreamProvider<List<Customer>>((ref) {
  return ref.watch(customerRepositoryProvider).watchAll();
});

final customerSearchProvider =
    FutureProvider.family<List<Customer>, String>((ref, query) {
  if (query.isEmpty) {
    return ref.watch(customerRepositoryProvider).watchAll().first;
  }
  return ref.watch(customerRepositoryProvider).search(query);
});
