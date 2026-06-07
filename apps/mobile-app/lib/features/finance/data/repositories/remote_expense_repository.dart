import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/models/expense.dart';
import '../mappers/expense_mapper.dart';

class RemoteExpenseRepository {
  static const _collectionName = 'expenses';

  final FirebaseFirestore _firestore;
  final String uid;
  final String businessId;

  RemoteExpenseRepository({
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

  Future<int> saveAndGetTimestamp(Expense expense) async {
    final data = {
      ...expense.toFirestore(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    await _collection.doc(expense.id).set(data, SetOptions(merge: true));
    final snap = await _collection.doc(expense.id).get();
    final ts = snap.data()?['updatedAt'];
    if (ts is Timestamp) return ts.millisecondsSinceEpoch;
    return DateTime.now().millisecondsSinceEpoch;
  }

  Future<void> delete(String id) => _collection.doc(id).delete();

  Future<Map<String, dynamic>?> fetchRaw(String id) async {
    final snap = await _collection.doc(id).get();
    return snap.exists ? snap.data() : null;
  }

  Future<Expense?> fetchById(String id) async {
    final data = await fetchRaw(id);
    if (data == null) return null;
    return ExpenseMapper.fromFirestore(data, id);
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
