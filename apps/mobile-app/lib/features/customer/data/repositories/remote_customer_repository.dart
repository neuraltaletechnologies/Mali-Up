import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/models/customer.dart';
import '../mappers/customer_mapper.dart';

class RemoteCustomerRepository {
  static const _collectionName = 'customers';

  final FirebaseFirestore _firestore;
  final String uid;
  final String businessId;

  RemoteCustomerRepository({
    required this.uid,
    required this.businessId,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('businesses').doc(businessId).collection(_collectionName);

  Future<int> saveAndGetTimestamp(Customer customer) async {
    final data = {
      ...customer.toFirestore(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    await _collection.doc(customer.id).set(data, SetOptions(merge: true));
    final snap = await _collection.doc(customer.id).get();
    final ts = snap.data()?['updatedAt'];
    if (ts is Timestamp) return ts.millisecondsSinceEpoch;
    return DateTime.now().millisecondsSinceEpoch;
  }

  /// Applies a balance delta via FieldValue.increment so offline sales from
  /// concurrent sessions compose correctly (mirrors the inventory
  /// quantity_delta op). Also stamps lastTransactionDate like online sales do.
  Future<int> applyBalanceDeltaAndGetTimestamp(String id, double delta) async {
    await _collection.doc(id).set({
      'balance': FieldValue.increment(delta),
      'lastTransactionDate': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
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

  Future<Customer?> fetchById(String id) async {
    final data = await fetchRaw(id);
    if (data == null) return null;
    return CustomerMapper.fromFirestore(data, id);
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
