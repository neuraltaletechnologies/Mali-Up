import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/onboarding_state.dart';
import '../../domain/models/user_lookup_result.dart';
import '../../../auth/presentation/utils/pin_auth_password.dart';
import '../../../../core/services/api_service.dart';

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

  /// Searches for a document matching [phone] via secure backend bridge.
  Future<UserLookupResult> lookupByPhone(String phone) async {
    // Propagate network/back-end errors so the UI can show an error quickly
    // instead of silently treating failures as "new user" and waiting.
    final response = await ApiService.post('/auth/lookup', {'phone': phone});
    final type = response['type'] as String;

    if (type == 'RETURNING_USER') {
      final user = response['user'] as Map<String, dynamic>;
      final business = response['business'] as Map<String, dynamic>?;
      final fullName = (user['name'] as String?) ?? '';
      final parts = fullName.trim().split(RegExp(r'\s+'));

      return ReturningUser(
        userId: user['id'] as String,
        name: fullName,
        firstName: parts.isNotEmpty ? parts.first : '',
        lastName: parts.length > 1 ? parts.skip(1).join(' ') : '',
        phone: (user['phone'] as String?) ?? phone,
        city: (user['city'] as String?) ?? '',
        role: (user['role'] as String?) ?? '',
        businessName: business?['name'] as String? ?? '',
        businessType: business?['type'] as String? ?? '',
        businessId: business?['id'] as String? ?? '',
      );
    }

    if (type == 'TEAM_MEMBER_PENDING') {
      final invite = response['invite'] as Map<String, dynamic>;
      return TeamMemberPending(
        memberId: (invite['memberId'] as String?) ?? '',
        name: (invite['name'] as String?) ?? '',
        role: (invite['role'] as String?) ?? '',
        businessName: (invite['businessName'] as String?) ?? '',
        ownerUid: (invite['ownerUid'] as String?) ?? '',
        businessId: (invite['businessId'] as String?) ?? '',
        inviteId: (invite['id'] as String?) ?? '',
        email: (invite['email'] as String?) ?? '',
      );
    }

    return const NewUser();
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

  /// Creates a Firebase Auth account for a team member, writes their user
  /// document to `users/{uid}`, marks the `team_members` record as active,
  /// and marks the `pendingInvites` record as accepted (if [inviteId] given).
  Future<void> createTeamMemberAccount({
    required String phone,
    required String pin,
    required String name,
    required String role,
    required String ownerUid,
    required String businessId,
    required String memberId,
    String inviteId = '',
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

    // Mark team_member record as active
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

    // Mark pendingInvite as accepted
    if (inviteId.isNotEmpty) {
      try {
        await _db.collection('pendingInvites').doc(inviteId).update({
          'status': 'accepted',
          'pinCreated': true,
          'acceptedAt': FieldValue.serverTimestamp(),
          'uid': uid,
        });
      } catch (e) {
        if (kDebugMode) debugPrint('[createTeamMemberAccount] invite: $e');
      }
    }
  }

  // ─── PIN RECOVERY ─────────────────────────────────────────────────────────

  /// Looks up the email stored against this phone number via backend bridge
  /// and triggers a recovery flow.
  /// Returns the obscured email found (for display), or null if nothing was found.
  Future<String?> sendPinRecovery({required String phone}) async {
    try {
      final response = await ApiService.post('/auth/recovery', {'phone': phone});
      
      // The backend handles the recovery logic and returns an obscured email
      return response['email'] as String?;
    } catch (e) {
      if (kDebugMode) debugPrint('[sendPinRecovery] $e');
      return null;
    }
  }

  // ─── WRITE — USER ────────────────────────────────────────────────────────

  /// Creates or replaces the user document at `users/{userId}`.
  Future<void> saveUser({
    required String userId,
    required OnboardingState state,
    required String businessId,
  }) async {
    final businesses = [
      {
        'id': businessId,
        'name': state.businessName,
        'category': state.businessType,
        'placeOfBusiness': state.city,
        'createdAt': FieldValue.serverTimestamp(),
      },
    ];

    await _db.collection('users').doc(userId).set({
      'phone': state.phone,
      'name': state.fullName,
      'firstName': state.firstName,
      'lastName': state.lastName,
      'city': state.city,
      'role': state.role,
      'language': state.isSwahili ? 'sw' : 'en',
      'businessName': state.businessName,
      'businessType': state.businessType,
      'defaultAccountType': 'business',
      'accountTypes': ['business'],
      'usagePreference': 'business',
      'defaultContext': 'business:$businessId',
      'selectedBusinessId': businessId,
      'businesses': businesses,
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

    await _db
        .collection('tenants')
        .doc(userId)
        .collection('businesses')
        .doc(ref.id)
        .set({
          'id': ref.id,
          'businessName': state.businessName,
          'businessType': state.businessType,
          'businessCategory': state.businessType,
          'placeOfBusiness': state.city,
          'ownerName': state.fullName,
          'ownerUid': userId,
          'accountType': 'business',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'plan': 'Trial',
          'isActive': true,
          'subscriptionStatus': 'trial',
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
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return cred.user!.uid;
    } on FirebaseAuthException catch (e) {
      if (e.code != 'email-already-in-use') rethrow;
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return cred.user!.uid;
    }
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
