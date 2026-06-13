import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/business_id_provider.dart';
import '../../../../core/providers/sync_provider.dart';
import '../../../rbac/data/rbac_providers.dart' show tenantOwnerUidProvider;
import '../../data/repositories/sync_inventory_repository.dart';
import '../../domain/models/inventory_item.dart';

final inventoryRepositoryProvider =
    Provider<SyncInventoryRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  // Use the tenant-owner UID so team members' writes target the owner's
  // Firestore tenant, not their own empty tenant.
  final uid = ref.watch(tenantOwnerUidProvider) ??
      FirebaseAuth.instance.currentUser?.uid ??
      '';
  final bizId = ref.watch(currentBusinessIdProvider).valueOrNull ?? '';
  final policy = ref.watch(offlinePolicyProvider);
  return SyncInventoryRepository(db: db, uid: uid, businessId: bizId, policy: policy);
});

/// Live stream of all active non-deleted inventory items, ordered by name.
/// Backed by Drift — works fully offline.
final inventoryProvider = StreamProvider<List<InventoryItem>>((ref) {
  return ref.watch(inventoryRepositoryProvider).watchAll();
});

final lowStockItemsProvider = StreamProvider<List<InventoryItem>>((ref) {
  return ref.watch(inventoryRepositoryProvider).watchLowStock();
});

final lowStockCountProvider = Provider<int>((ref) {
  return ref.watch(lowStockItemsProvider).valueOrNull?.length ?? 0;
});

final totalInventoryValueProvider = FutureProvider<double>((ref) {
  return ref.watch(inventoryRepositoryProvider).getTotalInventoryValue();
});

final inventoryItemProvider =
    FutureProvider.family<InventoryItem?, String>((ref, id) {
  return ref.watch(inventoryRepositoryProvider).getById(id);
});
