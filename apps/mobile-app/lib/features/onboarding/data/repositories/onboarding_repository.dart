import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/onboarding_state.dart';
import '../../domain/models/user_lookup_result.dart';

// ─── PROVIDER ────────────────────────────────────────────────────────────────

final onboardingRepositoryProvider = Provider<OnboardingRepository>((ref) {
  return OnboardingRepository();
});

// ─── REPOSITORY ───────────────────────────────────────────────────────────────

/// Pure Firestore access layer for the onboarding flow.
///
/// Rules:
/// - No business logic lives here — only data reads/writes.
/// - The notifier never imports this class directly; it goes through [OnboardingService].
/// - All Firestore field names match the spec exactly:
///   `phone`, `name`, `city`, `role`, `businessName`, `businessType`,
///   `createdAt`, `lastActiveAt`.
class OnboardingRepository {
  OnboardingRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  // ─── LOOKUP ───────────────────────────────────────────────────────────────

  /// Searches the `users` collection for a document matching [phone].
  ///
  /// If found, also fetches the matching `businesses` document.
  /// Returns [ReturningUser] or [NewUser].
  ///
  /// On any Firestore error the method silently returns [NewUser] and logs
  /// the exception — the flow must not block a real new user on a network blip.
  Future<UserLookupResult> lookupByPhone(String phone) async {
    try {
      final userSnap = await _db
          .collection('users')
          .where('phone', isEqualTo: phone)
          .limit(1)
          .get();

      if (userSnap.docs.isEmpty) return const NewUser();

      final userDoc = userSnap.docs.first;
      final userData = userDoc.data();
      final userId = userDoc.id;

      // Parallel fetch: businesses doc for this owner
      final bizSnap = await _db
          .collection('businesses')
          .where('ownerId', isEqualTo: userId)
          .limit(1)
          .get();

      String bizName = '';
      String bizType = '';
      String bizId = '';

      if (bizSnap.docs.isNotEmpty) {
        final biz = bizSnap.docs.first;
        bizName = (biz.data()['businessName'] as String?) ?? '';
        bizType = (biz.data()['businessType'] as String?) ?? '';
        bizId = biz.id;
      }

      final fullName = (userData['name'] as String?) ?? '';
      final parts = fullName.trim().split(RegExp(r'\s+'));

      return ReturningUser(
        userId: userId,
        name: fullName,
        firstName: parts.isNotEmpty ? parts.first : '',
        lastName: parts.length > 1 ? parts.skip(1).join(' ') : '',
        phone: (userData['phone'] as String?) ?? phone,
        city: (userData['city'] as String?) ?? '',
        role: (userData['role'] as String?) ?? '',
        businessName: bizName,
        businessType: bizType,
        businessId: bizId,
      );
    } catch (e, st) {
      // Firestore failure → treat as new user, never block the flow.
      if (kDebugMode) {
        debugPrint('[OnboardingRepository.lookupByPhone] $e\n$st');
      }
      return const NewUser();
    }
  }

  // ─── WRITE — USER ────────────────────────────────────────────────────────

  /// Creates or replaces the user document at `users/{userId}`.
  ///
  /// Field names are the canonical set defined in the data spec.
  Future<void> saveUser({
    required String userId,
    required OnboardingState state,
  }) async {
    await _db.collection('users').doc(userId).set({
      'phone': state.phone,
      'name': state.fullName,
      'city': state.city,
      'role': state.role,
      'language': state.isSwahili ? 'sw' : 'en',
      'createdAt': FieldValue.serverTimestamp(),
      'lastActiveAt': FieldValue.serverTimestamp(),
    });
  }

  // ─── WRITE — BUSINESS ─────────────────────────────────────────────────────

  /// Creates a new document in the `businesses` collection.
  /// Returns the auto-generated document ID.
  Future<String> saveBusinessProfile({
    required String userId,
    required OnboardingState state,
  }) async {
    final ref = _db.collection('businesses').doc();
    await ref.set({
      'ownerId': userId,
      'businessName': state.businessName,
      'businessType': state.businessType,
      'city': state.city,
      'createdAt': FieldValue.serverTimestamp(),
      'lastActiveAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  // ─── TOUCH ────────────────────────────────────────────────────────────────

  /// Updates `lastActiveAt` for returning users without touching other fields.
  Future<void> touchLastActive(String userId) async {
    try {
      await _db.collection('users').doc(userId).update({
        'lastActiveAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Non-critical — swallow silently.
      if (kDebugMode) debugPrint('[OnboardingRepository.touchLastActive] $e');
    }
  }
}
