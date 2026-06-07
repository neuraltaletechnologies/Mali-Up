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

  CollectionReference<Map<String, dynamic>> get _collection => _firestore
      .collection('tenants')
      .doc(uid)
      .collection('businesses')
      .doc(businessId)
      .collection(_collectionName);

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
