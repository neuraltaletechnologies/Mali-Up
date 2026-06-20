import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/models/team_member.dart';

class RemoteTeamRepository {
  static const _collectionName = 'staff';

  final FirebaseFirestore _firestore;
  final String uid;
  final String businessId;

  RemoteTeamRepository({
    required this.uid,
    required this.businessId,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('businesses').doc(businessId).collection(_collectionName);

  Future<int> saveAndGetTimestamp(TeamMember member) async {
    final data = {
      ...member.toFirestore(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    await _collection.doc(member.id).set(data, SetOptions(merge: true));
    final snap = await _collection.doc(member.id).get();
    final ts = snap.data()?['updatedAt'];
    if (ts is Timestamp) return ts.millisecondsSinceEpoch;
    return DateTime.now().millisecondsSinceEpoch;
  }

  Future<void> delete(String id) => _collection.doc(id).delete();

  Future<Map<String, dynamic>?> fetchRaw(String id) async {
    final snap = await _collection.doc(id).get();
    return snap.exists ? snap.data() : null;
  }

  /// Returns all team members (used for initial bootstrap pull).
  Future<List<({String id, Map<String, dynamic> data})>> fetchAll() async {
    final snap =
        await _collection.orderBy('invitedAt').get();
    return snap.docs.map((d) => (id: d.id, data: d.data())).toList();
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
