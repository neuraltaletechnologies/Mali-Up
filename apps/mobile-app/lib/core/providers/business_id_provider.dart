import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/context_firestore_repository.dart';

/// Canonical single-source-of-truth for the active businessId.
///
/// Re-emits whenever the signed-in user's profile changes (business switch,
/// first login, etc.). All repository providers watch this so they
/// automatically rebuild when the business context changes.
final currentBusinessIdProvider = StreamProvider<String>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return Stream.value('');

  final repo = ContextFirestoreRepository();
  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .snapshots()
      .map((snap) =>
          repo.resolveContextFromData(snap.data()).businessId ?? '');
});
