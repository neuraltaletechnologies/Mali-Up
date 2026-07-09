import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/rbac/data/role_cache_service.dart';
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
///
/// Offline-first: every screen scoped by this id (customers, inventory,
/// sales, ...) reads from Drift, but Drift queries filter by businessId, so
/// if this stream never resolves on a cold offline start those screens render
/// empty. Firestore's own persistence cache is disabled app-wide (main.dart),
/// so `.snapshots()` cannot serve a cached value while offline — yield the
/// last-resolved businessId from [RoleCacheService] first, mirroring
/// `userProfileStreamProvider`'s offline-cache pattern.
final currentBusinessIdProvider = StreamProvider<String>((ref) async* {
  final authAsync = ref.watch(authStateProvider);
  if (authAsync.isLoading) {
    yield '';
    return;
  }
  final user = authAsync.valueOrNull;
  if (user == null) {
    yield '';
    return;
  }

  final cached = await RoleCacheService.loadBusinessId(user.uid);
  if (cached != null && cached.isNotEmpty) yield cached;

  final repo = ContextFirestoreRepository();
  await for (final snap in FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .snapshots()) {
    final businessId = repo.resolveContextFromData(snap.data()).businessId ?? '';
    // Offline, the listener fires an empty from-cache snapshot (persistence
    // is disabled app-wide, so the cache is always empty). That resolves to
    // '' and would clobber the cached businessId yielded above — blanking
    // every Drift-scoped screen. '' from the server, however, is
    // authoritative (no business yet) and must pass through.
    if (businessId.isEmpty && snap.metadata.isFromCache) continue;
    if (businessId.isNotEmpty) {
      unawaited(RoleCacheService.saveBusinessId(user.uid, businessId));
    }
    yield businessId;
  }
});
