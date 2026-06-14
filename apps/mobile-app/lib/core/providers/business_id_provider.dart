import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/context_firestore_repository.dart';
import 'auth_provider.dart' show authStateProvider;

/// Canonical single-source-of-truth for the active businessId.
///
/// Re-emits whenever the signed-in user's profile changes (business switch,
/// first login, etc.). All repository providers watch this so they
/// automatically rebuild when the business context changes.
///
/// Watches authStateProvider so it rebuilds when Firebase Auth signs in
/// (e.g. immediately after first-time registration) rather than reading
/// currentUser once at build time and getting stuck with an empty businessId.
final currentBusinessIdProvider = StreamProvider<String>((ref) {
  final authAsync = ref.watch(authStateProvider);
  if (authAsync.isLoading) return Stream.value('');
  final user = authAsync.valueOrNull;
  if (user == null) return Stream.value('');

  final repo = ContextFirestoreRepository();
  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .snapshots()
      .map((snap) =>
          repo.resolveContextFromData(snap.data()).businessId ?? '');
});
