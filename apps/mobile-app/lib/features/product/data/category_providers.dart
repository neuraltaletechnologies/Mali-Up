import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/repositories/context_firestore_repository.dart';
import '../../customer/data/customer_providers.dart';
import '../domain/models/product_category.dart';

/// Streams the categories for the currently active business.
/// Path: tenants/{uid}/businesses/{bizId}/categories
final categoryListProvider = StreamProvider<List<ProductCategory>>((ref) async* {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    yield const <ProductCategory>[];
    return;
  }
  final businessAsync = ref.watch(currentBusinessIdProvider);
  if (businessAsync.isLoading) return;
  final bizId = businessAsync.valueOrNull;
  if (bizId == null || bizId.isEmpty) {
    yield const <ProductCategory>[];
    return;
  }
  final repo = ref.read(contextFirestoreRepositoryProvider);
  final col = repo.scopeCollection(
    uid: user.uid,
    context: ResolvedFinanceContext.business(bizId),
    childCollection: 'categories',
  );
  yield* col
      .orderBy('name')
      .snapshots()
      .map((snap) => snap.docs
          .map((d) => ProductCategory.fromFirestore(d.data(), d.id))
          .toList());
});

/// Streams the businessType string of the user's currently active business.
/// Reads from users/{uid}.businessType — set during onboarding.
final currentBusinessTypeProvider = StreamProvider<String>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return Stream.value('');
  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .snapshots()
      .map((snap) => (snap.data()?['businessType'] as String?) ?? '');
});

/// Adds a new category and returns its generated document ID.
Future<String> addCategory({
  required String uid,
  required String bizId,
  required String name,
  required ContextFirestoreRepository repo,
}) async {
  final col = repo.scopeCollection(
    uid: uid,
    context: ResolvedFinanceContext.business(bizId),
    childCollection: 'categories',
  );
  final ref = await col.add({
    'name': name.trim(),
    'createdAt': FieldValue.serverTimestamp(),
  });
  return ref.id;
}
