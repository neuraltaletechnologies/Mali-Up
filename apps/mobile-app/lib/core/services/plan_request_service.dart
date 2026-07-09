import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'plan_service.dart';

/// Kinds of plan requests the app can submit. Mirrored in firestore.rules and
/// the admin portal's plan-requests page.
enum PlanRequestType { enterpriseInquiry, paymentClaim }

extension PlanRequestTypeX on PlanRequestType {
  String get value => switch (this) {
        PlanRequestType.enterpriseInquiry => 'enterprise_inquiry',
        PlanRequestType.paymentClaim      => 'payment_claim',
      };
}

/// Writes upgrade/enterprise requests to the `plan_requests` collection so the
/// Mali Up team can see and act on them from the admin portal.
class PlanRequestService {
  static final _db = FirebaseFirestore.instance;

  /// Submits a plan request for the signed-in user. Enriches the request with
  /// the user's name/phone and selected business so admins can follow up
  /// without cross-referencing.
  static Future<void> submit({
    required PlanTier tier,
    required PlanRequestType type,
    String? note,
    String? paymentRef,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('Not signed in');
    }

    final userDoc = await _db.collection('users').doc(user.uid).get();
    final data = userDoc.data() ?? {};
    final businessId =
        (data['selectedBusinessId'] as String?)?.trim().isNotEmpty == true
            ? (data['selectedBusinessId'] as String).trim()
            : ((data['businessId'] as String?) ?? '');

    var businessName = '';
    if (businessId.isNotEmpty) {
      try {
        final bizDoc =
            await _db.collection('businesses').doc(businessId).get();
        businessName = (bizDoc.data()?['businessName'] as String?) ?? '';
      } catch (_) {
        // Business lookup is best-effort — the uid is enough for admins.
      }
    }

    await _db.collection('plan_requests').add({
      'uid': user.uid,
      'name': (data['name'] as String?) ?? '',
      'phone': (data['phone'] as String?) ?? '',
      'businessId': businessId,
      'businessName': businessName,
      'requestedTier': tier.name,
      'type': type.value,
      if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
      if (paymentRef != null && paymentRef.isNotEmpty) 'paymentRef': paymentRef,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Whether the signed-in user already has a pending request of [type].
  /// Used to avoid duplicate enterprise inquiries.
  static Future<bool> hasPending(PlanRequestType type) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    try {
      final snap = await _db
          .collection('plan_requests')
          .where('uid', isEqualTo: user.uid)
          .where('type', isEqualTo: type.value)
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();
      return snap.docs.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Live stream of the signed-in user's most recent pending request, or null
  /// if none — powers the "your request is being processed" banner.
  ///
  /// No `orderBy` here on purpose: `uid` + `status` equality filters alone
  /// don't need a composite Firestore index, matching [hasPending]'s query
  /// shape. There's normally at most one pending request at a time anyway.
  static Stream<PlanRequestSummary?> watchPending() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value(null);
    return _db
        .collection('plan_requests')
        .where('uid', isEqualTo: user.uid)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .snapshots()
        .map((snap) {
      if (snap.docs.isEmpty) return null;
      return PlanRequestSummary.fromFirestore(snap.docs.first.data());
    });
  }
}

/// Small summary of a pending plan request, enough to render a banner.
class PlanRequestSummary {
  final PlanTier tier;
  final PlanRequestType type;
  final String? paymentRef;

  const PlanRequestSummary({
    required this.tier,
    required this.type,
    this.paymentRef,
  });

  factory PlanRequestSummary.fromFirestore(Map<String, dynamic> data) {
    return PlanRequestSummary(
      tier: PlanTierX.fromString(data['requestedTier'] as String?),
      type: (data['type'] as String?) == 'enterprise_inquiry'
          ? PlanRequestType.enterpriseInquiry
          : PlanRequestType.paymentClaim,
      paymentRef: data['paymentRef'] as String?,
    );
  }
}

/// Whether the signed-in user has a pending plan request right now.
final pendingPlanRequestProvider =
    StreamProvider.autoDispose<PlanRequestSummary?>((ref) {
  return PlanRequestService.watchPending();
});
