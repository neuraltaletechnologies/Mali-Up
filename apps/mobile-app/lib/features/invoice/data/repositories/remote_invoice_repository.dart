import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/models/invoice.dart';
import '../mappers/invoice_mapper.dart';

/// Firestore-backed remote invoice store.
/// Called only by SyncService (Phase 3) — never directly from the UI.
/// All writes use merge semantics so partial updates are safe.
class RemoteInvoiceRepository {
  static const _collectionName = 'sales_invoices';

  final FirebaseFirestore _firestore;
  final String uid;
  final String businessId;

  RemoteInvoiceRepository({
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

  // ─── Writes ────────────────────────────────────────────────────────────────

  /// Saves an invoice to Firestore and returns the committed server timestamp.
  Future<int> saveAndGetTimestamp(Invoice invoice) async {
    final data = {
      ...invoice.toFirestore(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    await _collection
        .doc(invoice.id)
        .set(data, SetOptions(merge: true));

    // Read back the committed server timestamp for conflict tracking
    final snap = await _collection.doc(invoice.id).get();
    final ts = snap.data()?['updatedAt'];
    if (ts is Timestamp) return ts.millisecondsSinceEpoch;
    return DateTime.now().millisecondsSinceEpoch;
  }

  Future<void> delete(String id) => _collection.doc(id).delete();

  // ─── Reads (used by SyncService for conflict detection + full pull) ────────

  Future<Map<String, dynamic>?> fetchRaw(String id) async {
    final snap = await _collection.doc(id).get();
    return snap.exists ? snap.data() : null;
  }

  Future<Invoice?> fetchById(String id) async {
    final data = await fetchRaw(id);
    if (data == null) return null;
    return InvoiceMapper.fromFirestore(data, id);
  }

  /// Fetches all invoices whose [updatedAt] is after [sinceMs].
  /// Used for the incremental pull during each sync cycle.
  Future<List<({String id, Map<String, dynamic> data})>> fetchUpdatedSince(
    int sinceMs,
  ) async {
    final snap = await _collection
        .where(
          'updatedAt',
          isGreaterThan: Timestamp.fromMillisecondsSinceEpoch(sinceMs),
        )
        .get();
    return snap.docs
        .map((d) => (id: d.id, data: d.data()))
        .toList();
  }
}
