import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/rbac/data/rbac_providers.dart';
import '../../features/team/domain/models/team_member.dart';
import '../database/app_database.dart';
import '../sync/offline_policy_notifier.dart';
import '../sync/sync_service.dart';
import 'business_id_provider.dart';
import 'database_provider.dart';

export 'database_provider.dart' show appDatabaseProvider;

/// Single [SyncService] instance for the active session.
/// Rebuilt when uid or businessId changes (sign-out / business switch).
///
/// Scoped to the tenant-owner UID: Firestore data lives under
/// `tenants/{ownerUid}/…`, so team members must sync against the owner's
/// tenant rather than their own (empty) one.
final syncServiceProvider = Provider<SyncService>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final uid = ref.watch(tenantOwnerUidProvider) ??
      FirebaseAuth.instance.currentUser?.uid ??
      '';
  final bizId = ref.watch(currentBusinessIdProvider).valueOrNull ?? '';
  final offlinePolicy = ref.read(offlinePolicyProvider);

  // DataScope.own team members (e.g. a driver who should only see their own
  // vehicle's records) sync against their own Firebase Auth UID rather than
  // the full tenant — see SyncService.scopeReadsToUid and firestore.rules.
  final member = ref.watch(currentMemberProvider).valueOrNull;
  final scopeReadsToUid = member?.dataScope == DataScope.own
      ? FirebaseAuth.instance.currentUser?.uid
      : null;

  final service = SyncService(
    db: db,
    uid: uid,
    businessId: bizId,
    offlinePolicy: offlinePolicy,
    scopeReadsToUid: scopeReadsToUid,
  );

  // Keep alive until the provider is disposed (widget tree torn down or
  // the uid/bizId invalidates it).
  ref.onDispose(service.dispose);

  // Start listening for connectivity and run an initial sync cycle.
  // Runs asynchronously — the UI doesn't wait for it.
  if (uid.isNotEmpty && bizId.isNotEmpty) {
    service.start();
  }

  return service;
});

/// [OfflinePolicyNotifier] — initialized once per session.
final offlinePolicyProvider = ChangeNotifierProvider<OfflinePolicyNotifier>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final notifier = OfflinePolicyNotifier(db: db);
  notifier.initialize();
  return notifier;
});

/// Current [SyncState] — rebuilds the UI whenever it changes.
final syncStateProvider = Provider<SyncState>((ref) {
  final service = ref.watch(syncServiceProvider);
  // Bridge ChangeNotifier → Riverpod. The listener is removed on dispose so
  // re-evaluations don't accumulate duplicate listeners causing N×M rebuilds.
  void notify() => ref.invalidateSelf();
  service.addListener(notify);
  ref.onDispose(() => service.removeListener(notify));
  return service.state;
});

/// Live count of pending + processing + conflict queue entries.
/// Drives the sync badge and the "Waiting to sync" UX copy.
final pendingSyncCountProvider = StreamProvider<int>((ref) {
  return ref.watch(syncServiceProvider).pendingCountStream;
});

/// Convenience: true when there are unsynced local changes.
final hasPendingSyncProvider = Provider<bool>((ref) {
  return (ref.watch(pendingSyncCountProvider).valueOrNull ?? 0) > 0;
});

/// Live count of queue entries stuck in 'failed' status.
final syncFailedCountProvider = StreamProvider<int>((ref) {
  return ref.watch(appDatabaseProvider).syncQueueDao.watchFailedCount();
});

/// Live count of queue entries in 'conflict' status.
final syncConflictCountProvider = StreamProvider<int>((ref) {
  return ref.watch(appDatabaseProvider).syncQueueDao.watchConflictCount();
});

/// True when sync is erroring or there are unresolved failed/conflict queue
/// entries — drives the "sync problem" notification alert. Deliberately not
/// keyed per-entry: a business sees one consolidated alert, not one per
/// failed queue item.
final syncHasProblemsProvider = Provider<bool>((ref) {
  final state = ref.watch(syncStateProvider);
  final failed = ref.watch(syncFailedCountProvider).valueOrNull ?? 0;
  final conflict = ref.watch(syncConflictCountProvider).valueOrNull ?? 0;
  return state == SyncState.error || failed > 0 || conflict > 0;
});

typedef AppDb = AppDatabase;
