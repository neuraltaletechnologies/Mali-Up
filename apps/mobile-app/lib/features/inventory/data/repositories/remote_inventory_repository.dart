import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/models/inventory_item.dart';
import '../mappers/inventory_mapper.dart';

class RemoteInventoryRepository {
  static const _collectionName = 'inventory_items';

  final FirebaseFirestore _firestore;
  final String uid;
  final String businessId;

  RemoteInventoryRepository({
    required this.uid,
    required this.businessId,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection => _firestore
      .collection('tenants')
      .doc(uid)
      .collection('businesses')
      .doc(businessId)
      .collection(_collectionName);

  Future<int> saveAndGetTimestamp(InventoryItem item) async {
    final data = {
      ...item.toFirestore(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    await _collection.doc(item.id).set(data, SetOptions(merge: true));
    final snap = await _collection.doc(item.id).get();
    final ts = snap.data()?['updatedAt'];
    if (ts is Timestamp) return ts.millisecondsSinceEpoch;
    return DateTime.now().millisecondsSinceEpoch;
  }

  /// Applies a quantity delta on top of the current server value.
  /// Used by ConflictResolver (Phase 3) for concurrent stock movements.
  Future<int> applyQuantityDeltaAndGetTimestamp(
    String id,
    double delta,
  ) async {
    await _collection.doc(id).update({
      'currentStock': FieldValue.increment(delta),
      'stock': FieldValue.increment(delta),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    final snap = await _collection.doc(id).get();
    final ts = snap.data()?['updatedAt'];
    if (ts is Timestamp) return ts.millisecondsSinceEpoch;
    return DateTime.now().millisecondsSinceEpoch;
  }

  Future<void> delete(String id) => _collection.doc(id).delete();

  Future<Map<String, dynamic>?> fetchRaw(String id) async {
    final snap = await _collection.doc(id).get();
    return snap.exists ? snap.data() : null;
  }

  Future<InventoryItem?> fetchById(String id) async {
    final data = await fetchRaw(id);
    if (data == null) return null;
    return InventoryMapper.fromFirestore(data, id);
  }

  Future<List<({String id, Map<String, dynamic> data})>> fetchUpdatedSince(
    int sinceMs,
  ) async {
    final snap = await _collection
        .where(
          'updatedAt',
          isGreaterThan: Timestamp.fromMillisecondsSinceEpoch(sinceMs),
        )
        .get();
    return snap.docs.map((d) => (id: d.id, data: d.data())).toList();
  }
}
