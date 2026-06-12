import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/models/debt.dart';

class RemoteDebtRepository {
  static const _collectionName = 'debts';

  final FirebaseFirestore _firestore;
  final String uid;
  final String businessId;

  RemoteDebtRepository({
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

  // ─── Debt operations ───────────────────────────────────────────────────────

  Future<int> saveAndGetTimestamp(Debt debt) async {
    final data = {
      ...debt.toFirestore(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    await _collection.doc(debt.id).set(data, SetOptions(merge: true));
    final snap = await _collection.doc(debt.id).get();
    final ts = snap.data()?['updatedAt'];
    if (ts is Timestamp) return ts.millisecondsSinceEpoch;
    return DateTime.now().millisecondsSinceEpoch;
  }

  Future<void> delete(String id) => _collection.doc(id).delete();

  Future<Map<String, dynamic>?> fetchRaw(String id) async {
    final snap = await _collection.doc(id).get();
    return snap.exists ? snap.data() : null;
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

  // ─── DebtPayment operations ────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> _paymentsCollection(
          String debtId) =>
      _collection.doc(debtId).collection('payments');

  Future<int> savePaymentAndGetTimestamp(
    String debtId,
    DebtPayment payment,
  ) async {
    final data = {
      ...payment.toFirestore(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    await _paymentsCollection(debtId)
        .doc(payment.id)
        .set(data, SetOptions(merge: true));
    final snap = await _paymentsCollection(debtId).doc(payment.id).get();
    final ts = snap.data()?['updatedAt'] ?? snap.data()?['createdAt'];
    if (ts is Timestamp) return ts.millisecondsSinceEpoch;
    return DateTime.now().millisecondsSinceEpoch;
  }

  Future<void> deletePayment(String debtId, String paymentId) =>
      _paymentsCollection(debtId).doc(paymentId).delete();

  Future<List<({String id, Map<String, dynamic> data})>> fetchPaymentsForDebt(
    String debtId,
  ) async {
    final snap =
        await _paymentsCollection(debtId).orderBy('date', descending: true).get();
    return snap.docs.map((d) => (id: d.id, data: d.data())).toList();
  }

  Future<List<({String id, Map<String, dynamic> data})>>
      fetchPaymentsUpdatedSince(
    String debtId,
    int sinceMs,
  ) async {
    final snap = await _paymentsCollection(debtId)
        .where('updatedAt',
            isGreaterThan: Timestamp.fromMillisecondsSinceEpoch(sinceMs))
        .get();
    return snap.docs.map((d) => (id: d.id, data: d.data())).toList();
  }
}
