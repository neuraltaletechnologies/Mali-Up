import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CatalogSubmissionService
//
// Writes user-contributed products and categories to the shared
// `catalog_community_submissions` Firestore collection so admins can
// review, edit, and optionally promote them to the master catalog.
//
// The document ID is deterministic  — slugified-name + normalised-biz-type
// — so multiple businesses submitting the same product auto-increment the
// submissionCount rather than creating duplicates.
//
// Writes are fire-and-forget (best effort). A failure here never blocks
// the main save flow.
// ─────────────────────────────────────────────────────────────────────────────

const _col = 'catalog_community_submissions';

class CatalogSubmissionService {
  final FirebaseFirestore _firestore;

  CatalogSubmissionService([FirebaseFirestore? fs])
      : _firestore = fs ?? FirebaseFirestore.instance;

  // ── Submit a custom product ────────────────────────────────────────────────

  Future<void> submitProduct({
    required String productName,
    required String businessType,      // normalised key ("retail", "pharmacy"…)
    required String businessTypeName,  // first human-readable label
    required String submittedByUid,
    required String submittedByBusinessId,
    String categorySlug = '',
    String unit = 'Piece',
    String description = '',
  }) async {
    if (productName.trim().isEmpty) return;
    final docId = 'p_${_slug(productName)}_$businessType';
    await _upsert(
      docId: docId,
      base: {
        'type': 'product',
        'productName': productName.trim(),
        'businessType': businessType,
        'businessTypeName': businessTypeName,
        'categorySlug': categorySlug,
        'unit': unit,
        'description': description,
        'submittedByUid': submittedByUid,
        'submittedByBusinessId': submittedByBusinessId,
      },
    );
  }

  // ── Submit a custom category ───────────────────────────────────────────────

  Future<void> submitCategory({
    required String categoryName,
    required String businessType,
    required String businessTypeName,
    required String submittedByUid,
    required String submittedByBusinessId,
  }) async {
    if (categoryName.trim().isEmpty) return;
    final docId = 'c_${_slug(categoryName)}_$businessType';
    await _upsert(
      docId: docId,
      base: {
        'type': 'category',
        'productName': categoryName.trim(), // reuses productName field for uniform sorting
        'categoryName': categoryName.trim(),
        'businessType': businessType,
        'businessTypeName': businessTypeName,
        'submittedByUid': submittedByUid,
        'submittedByBusinessId': submittedByBusinessId,
      },
    );
  }

  // ── Internal ───────────────────────────────────────────────────────────────

  Future<void> _upsert({
    required String docId,
    required Map<String, dynamic> base,
  }) async {
    final ref = _firestore.collection(_col).doc(docId);
    await _firestore.runTransaction<void>((txn) async {
      final snap = await txn.get(ref);
      if (snap.exists) {
        txn.update(ref, {
          ...base,
          'submissionCount': FieldValue.increment(1),
          'lastSeenAt': FieldValue.serverTimestamp(),
        });
      } else {
        txn.set(ref, {
          ...base,
          'status': 'pending',
          'submissionCount': 1,
          'firstSeenAt': FieldValue.serverTimestamp(),
          'lastSeenAt': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  String _slug(String s) => s
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final catalogSubmissionServiceProvider =
    Provider<CatalogSubmissionService>((ref) => CatalogSubmissionService());
