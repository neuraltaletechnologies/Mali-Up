import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/onboarding_state.dart';
import '../../domain/models/user_lookup_result.dart';
import '../../../auth/presentation/utils/pin_auth_password.dart';

// ─── PROVIDER ────────────────────────────────────────────────────────────────

final onboardingRepositoryProvider = Provider<OnboardingRepository>((ref) {
  return OnboardingRepository();
});

// ─── REPOSITORY ───────────────────────────────────────────────────────────────

/// Pure Firestore + Firebase Auth access layer for the onboarding flow.
///
/// Rules:
/// - No business logic lives here — only data reads/writes.
/// - The notifier never imports this class directly; it goes through [OnboardingService].
class OnboardingRepository {
  OnboardingRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  // ─── LOOKUP ───────────────────────────────────────────────────────────────

  /// Searches first the `users` collection, then the `team_members` collection
  /// group, for a document matching [phone].
  ///
  /// Priority:
  ///   1. Found in `users`           → [ReturningUser]  (already has PIN)
  ///   2. Found in `team_members`    → [TeamMemberPending] (needs to set PIN)
  ///   3. Not found                  → [NewUser]
  ///
  /// On any Firestore error the method silently returns [NewUser] and logs.
  Future<UserLookupResult> lookupByPhone(String phone) async {
    try {
      // ── 1. Check users collection ────────────────────────────────────────
      final userSnap = await _db
          .collection('users')
          .where('phone', isEqualTo: phone)
          .limit(1)
          .get();

      if (userSnap.docs.isNotEmpty) {
        final userDoc = userSnap.docs.first;
        final userData = userDoc.data();
        final userId = userDoc.id;

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
      }

      // ── 2. Check team_members collection group ────────────────────────────
      final memberSnap = await _db
          .collectionGroup('team_members')
          .where('phone', isEqualTo: phone)
          .limit(1)
          .get();

      if (memberSnap.docs.isNotEmpty) {
        final memberDoc = memberSnap.docs.first;
        final memberData = memberDoc.data();

        // Path: tenants/{ownerUid}/businesses/{bizId}/team_members/{memberId}
        final pathSegments = memberDoc.reference.path.split('/');
        final ownerUid = pathSegments.length > 1 ? pathSegments[1] : '';
        final bizId = pathSegments.length > 3 ? pathSegments[3] : '';

        // Fetch business name for the owner
        String bizName = '';
        if (ownerUid.isNotEmpty && bizId.isNotEmpty) {
          try {
            final bizDoc = await _db
                .collection('tenants')
                .doc(ownerUid)
                .collection('businesses')
                .doc(bizId)
                .get();
            bizName = (bizDoc.data()?['businessName'] as String?) ?? '';
          } catch (_) {}
        }

        return TeamMemberPending(
          memberId: memberDoc.id,
          name: (memberData['name'] as String?) ?? '',
          role: (memberData['role'] as String?) ?? '',
          businessName: bizName,
          ownerUid: ownerUid,
          businessId: bizId,
        );
      }

      return const NewUser();
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[OnboardingRepository.lookupByPhone] $e\n$st');
      }
      return const NewUser();
    }
  }

  // ─── AUTH — EXISTING USER ────────────────────────────────────────────────

  /// Signs in an existing user using the derived email + PIN-based password.
  ///
  /// Throws [FirebaseAuthException] on wrong PIN or user not found.
  Future<void> loginWithPin({
    required String phone,
    required String pin,
  }) async {
    final email = _emailFromPhone(phone);
    final password = buildAuthPasswordFromPin(pin);
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  // ─── AUTH — TEAM MEMBER FIRST-TIME SETUP ─────────────────────────────────

  /// Creates a Firebase Auth account for a team member and writes their user
  /// document to `users/{uid}`, then marks the team member record as active.
  ///
  /// Called when a [TeamMemberPending] user sets up their PIN for the first time.
  Future<void> createTeamMemberAccount({
    required String phone,
    required String pin,
    required String name,
    required String role,
    required String ownerUid,
    required String businessId,
    required String memberId,
  }) async {
    final email = _emailFromPhone(phone);
    final password = buildAuthPasswordFromPin(pin);

    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = cred.user!.uid;

    final parts = name.trim().split(RegExp(r'\s+'));
    final firstName = parts.isNotEmpty ? parts.first : '';
    final lastName = parts.length > 1 ? parts.skip(1).join(' ') : '';

    // Write user document
    await _db.collection('users').doc(uid).set({
      'phone': phone,
      'name': name,
      'firstName': firstName,
      'lastName': lastName,
      'role': role,
      'isTeamMember': true,
      'ownerUid': ownerUid,
      'businessId': businessId,
      'createdAt': FieldValue.serverTimestamp(),
      'lastActiveAt': FieldValue.serverTimestamp(),
    });

    // Mark team member record as active
    if (ownerUid.isNotEmpty && businessId.isNotEmpty && memberId.isNotEmpty) {
      try {
        await _db
            .collection('tenants')
            .doc(ownerUid)
            .collection('businesses')
            .doc(businessId)
            .collection('team_members')
            .doc(memberId)
            .update({
          'status': 'active',
          'acceptedAt': FieldValue.serverTimestamp(),
          'uid': uid,
        });
      } catch (e) {
        if (kDebugMode) debugPrint('[createTeamMemberAccount] activate: $e');
      }
    }
  }

  // ─── WRITE — USER ────────────────────────────────────────────────────────

  /// Creates or replaces the user document at `users/{userId}`.
  Future<void> saveUser({
    required String userId,
    required OnboardingState state,
  }) async {
    await _db.collection('users').doc(userId).set({
      'phone': state.phone,
      'name': state.fullName,
      'firstName': state.firstName,
      'lastName': state.lastName,
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
      'country': state.businessCountry,
      'region': state.businessRegion,
      'district': state.businessDistrict,
      'createdAt': FieldValue.serverTimestamp(),
      'lastActiveAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  // ─── AUTH — NEW USER ACCOUNT ─────────────────────────────────────────────

  /// Creates a Firebase Auth account for a brand-new owner user.
  /// Returns the new user's Firebase UID.
  Future<String> createNewUserAccount({
    required String phone,
    required String pin,
  }) async {
    final email = _emailFromPhone(phone);
    final password = buildAuthPasswordFromPin(pin);
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    return cred.user!.uid;
  }

  // ─── TOUCH ────────────────────────────────────────────────────────────────

  /// Updates `lastActiveAt` for returning users without touching other fields.
  Future<void> touchLastActive(String userId) async {
    try {
      await _db.collection('users').doc(userId).update({
        'lastActiveAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (kDebugMode) debugPrint('[OnboardingRepository.touchLastActive] $e');
    }
  }

  // ─── PRIVATE ─────────────────────────────────────────────────────────────

  /// Derives the Firebase Auth email from an E.164 phone number.
  /// Strips the leading '+' so the email is valid.
  String _emailFromPhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    return '$digits@mali.up';
  }
}
