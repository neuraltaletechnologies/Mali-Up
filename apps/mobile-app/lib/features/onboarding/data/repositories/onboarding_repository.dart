import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/onboarding_state.dart';
import '../../domain/models/user_lookup_result.dart';
import '../../../auth/presentation/utils/pin_auth_password.dart';
import '../../../team/domain/models/team_member.dart';
import '../../../../core/utils/phone_number_utils.dart';

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
  OnboardingRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _db = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  // ─── LOOKUP ───────────────────────────────────────────────────────────────

  /// Searches for a document matching [phone] directly in Firestore.
  Future<UserLookupResult> lookupByPhone(String phone) async {
    try {
      final canonicalPhone = PhoneNumberUtils.canonical(phone);
      final variants = PhoneNumberUtils.lookupVariants(phone);
      final userFuture = _lookupUserByPhone(variants);
      final inviteFuture = _lookupPendingInviteByPhone(variants);

      final memberFuture = _lookupTeamMemberByPhone(variants);

      final results = await Future.wait([
        userFuture,
        inviteFuture,
        memberFuture,
      ]);

      final userDoc =
          results[0] as QueryDocumentSnapshot<Map<String, dynamic>>?;
      final inviteDoc =
          results[1] as QueryDocumentSnapshot<Map<String, dynamic>>?;
      final memberSnap = results[2] as QuerySnapshot<Map<String, dynamic>>?;

      if (userDoc != null) {
        final userData = userDoc.data();
        final userId = userDoc.id;

        final businessSnap = await _db
            .collection('businesses')
            .where('ownerUid', isEqualTo: userId)
            .limit(1)
            .get();

        String businessName = '';
        String businessType = '';
        String businessId = '';
        String? businessLogo;

        if (businessSnap.docs.isNotEmpty) {
          final businessDoc = businessSnap.docs[0];
          final businessData = businessDoc.data();
          businessId = businessDoc.id;
          businessName = (businessData['businessName'] as String?) ?? '';
          businessType = (businessData['businessType'] as String?) ?? '';
          businessLogo = (businessData['logoUrl'] as String?)?.trim();
        }

        final fullName = (userData['name'] as String?) ?? '';
        final parts = fullName.trim().split(RegExp(r'\s+'));

        return ReturningUser(
          userId: userId,
          name: fullName,
          firstName: parts.isNotEmpty ? parts.first : '',
          lastName: parts.length > 1 ? parts.skip(1).join(' ') : '',
          phone:
              (userData['phone'] as String?) ??
              (userData['phoneNumber'] as String?) ??
              canonicalPhone,
          city: (userData['city'] as String?) ?? '',
          role: (userData['role'] as String?) ?? '',
          businessName: businessName,
          businessType: businessType,
          businessId: businessId,
          businessLogo: businessLogo,
        );
      }

      if (inviteDoc != null) {
        final invite = inviteDoc.data();
        return TeamMemberPending(
          memberId: (invite['memberId'] as String?) ?? '',
          name: (invite['fullName'] as String?) ?? '',
          role: (invite['role'] as String?) ?? '',
          businessName: (invite['businessName'] as String?) ?? '',
          ownerUid: (invite['ownerUid'] as String?) ?? '',
          businessId: (invite['businessId'] as String?) ?? '',
          inviteId: inviteDoc.id,
          email: (invite['email'] as String?) ?? '',
        );
      }

      if (memberSnap != null && memberSnap.docs.isNotEmpty) {
        final memberDoc = memberSnap.docs[0];
        final memberData = memberDoc.data();
        // Path: businesses/{bizId}/staff/{staffId}
        final pathSegments = memberDoc.reference.path.split('/');
        final bizId = pathSegments.length > 1 ? pathSegments[1] : '';
        final ownerUid = (memberData['invitedBy'] as String?) ?? '';

        // Fetch business name and the matching pendingInvite in parallel.
        final inviteFuture = _db
            .collection('pendingInvites')
            .where('memberId', isEqualTo: memberDoc.id)
            .where('status', isEqualTo: 'pending')
            .limit(1)
            .get();
        final bizFuture = bizId.isNotEmpty
            ? _db.collection('businesses').doc(bizId).get()
            : null;

        final inviteSnap2 = await inviteFuture;
        final bizDoc = bizFuture != null ? await bizFuture : null;

        final businessName = (bizDoc?.data()?['businessName'] as String?) ?? '';
        final inviteId = inviteSnap2.docs.isNotEmpty
            ? inviteSnap2.docs.first.id
            : '';
        final email = inviteSnap2.docs.isNotEmpty
            ? (inviteSnap2.docs.first.data()['email'] as String?) ?? ''
            : (memberData['email'] as String?) ?? '';

        return TeamMemberPending(
          memberId: memberDoc.id,
          name: (memberData['name'] as String?) ?? '',
          role: (memberData['role'] as String?) ?? '',
          businessName: businessName,
          ownerUid: ownerUid,
          businessId: bizId,
          inviteId: inviteId,
          email: email,
        );
      }

      return const NewUser();
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[OnboardingRepository.lookupByPhone] $e\n$st');
      }
      // Rethrow so the notifier can show an error message rather than silently
      // routing returning users into the new-account creation flow.
      rethrow;
    }
  }

  // ─── AUTH — EXISTING USER ────────────────────────────────────────────────

  /// Signs in an existing user using the derived email + PIN-based password.
  ///
  /// First tries the derived phone email. If the account was migrated to the
  /// user's real email (see [updateAuthEmail]), falls back to the Firestore
  /// email lookup so returning users aren't locked out after migration.
  ///
  /// Throws [FirebaseAuthException] on wrong PIN or user not found.
  Future<void> loginWithPin({
    required String phone,
    required String pin,
  }) async {
    final canonicalPhone = PhoneNumberUtils.canonical(phone);
    final password = buildAuthPasswordFromPin(phone: canonicalPhone, pin: pin);
    final profileEmails = await _fetchUserAuthEmails(phone);
    final candidates = <String>{_emailFromPhone(phone), ...profileEmails};

    FirebaseAuthException? lastError;
    for (final email in candidates) {
      try {
        await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        return;
      } on FirebaseAuthException catch (e) {
        lastError = e;
        // With email-enumeration protection Firebase reports a missing account
        // as invalid-credential, so legacy identifiers must still be tried.
        if (e.code != 'user-not-found' &&
            e.code != 'invalid-credential' &&
            e.code != 'wrong-password') {
          rethrow;
        }
      }
    }
    throw lastError!;
  }

  // ─── AUTH — TEAM MEMBER FIRST-TIME SETUP ─────────────────────────────────

  /// Creates a Firebase Auth account for a team member, then writes their user
  /// document, activates the `team_members` record, creates the `memberAccess`
  /// doc, and marks the `pendingInvites` record as accepted — all in a single
  /// atomic Firestore batch so no partial state is possible.
  ///
  /// Idempotent: if the Firebase Auth account already exists (retry after a
  /// previous network failure), we sign in and let the batch self-heal any
  /// missing Firestore documents.
  Future<void> createTeamMemberAccount({
    required String phone,
    required String pin,
    required String name,
    required String role,
    required String ownerUid,
    required String businessId,
    required String memberId,
    String inviteId = '',
    String realEmail = '',
  }) async {
    final email = _emailFromPhone(phone);
    final password = buildAuthPasswordFromPin(phone: phone, pin: pin);

    UserCredential cred;
    try {
      cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      if (e.code != 'email-already-in-use') rethrow;
      // Account was created in a prior attempt but Firestore writes may have
      // been partial.  Sign in and let the batch below self-heal the docs.
      cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    }
    final uid = cred.user!.uid;

    final parts = name.trim().split(RegExp(r'\s+'));
    final firstName = parts.isNotEmpty ? parts.first : '';
    final lastName = parts.length > 1 ? parts.skip(1).join(' ') : '';

    final batch = _db.batch();

    // 1. User profile — memberId lets currentMemberProvider locate the
    //    team_member doc directly without a collection-group query.
    batch.set(_db.collection('users').doc(uid), {
      'phone': phone,
      'name': name,
      'firstName': firstName,
      'lastName': lastName,
      'email': realEmail,
      'role': role,
      'isTeamMember': true,
      'ownerUid': ownerUid,
      'businessId': businessId,
      'memberId': memberId,
      'createdAt': FieldValue.serverTimestamp(),
      'lastActiveAt': FieldValue.serverTimestamp(),
    });

    // 2. Worker profile document.
    batch.set(_db.collection('workers').doc(uid), {
      'name': name,
      'firstName': firstName,
      'lastName': lastName,
      'phone': phone,
      'createdAt': FieldValue.serverTimestamp(),
    });

    if (businessId.isNotEmpty && memberId.isNotEmpty) {
      // Read the invite's actual permissions via a limited *query* (not a direct
      // .doc().get()) — Firestore rules only allow reading this collection's staff
      // docs pre-acceptance through limit(1) queries; a direct get() by ID is
      // owner/self-only and this caller isn't either yet. Falling back to
      // defaultPermissionsFor(role) would silently wipe out an owner's custom
      // permission selection (defaultPermissionsFor('custom') is empty).
      final existingStaffSnap = await _db
          .collection('businesses')
          .doc(businessId)
          .collection('staff')
          .where('phone', isEqualTo: phone)
          .limit(1)
          .get();
      final existingPermissions = existingStaffSnap.docs.isNotEmpty
          ? ((existingStaffSnap.docs.first.data()['permissions'] as List?)
                    ?.map((p) => p.toString())
                    .toList() ??
                const <String>[])
          : defaultPermissionsFor(
              TeamRole.fromString(role),
            ).map((p) => p.name).toList();

      // 3. Activate the staff record and stamp workerUid. Role/permissions are
      //    left untouched — they were already set correctly by the owner when
      //    the invite was created. (Firestore rules also only permit
      //    status/acceptedAt/workerUid/updatedAt/email to change here.)
      batch.set(
        _db
            .collection('businesses')
            .doc(businessId)
            .collection('staff')
            .doc(memberId),
        {
          'status': 'active',
          'workerUid': uid,
          'acceptedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          if (realEmail.isNotEmpty) 'email': realEmail,
        },
        SetOptions(merge: true),
      );

      // 3a. Create the UID-keyed pointer doc at staff/{uid}.
      // isStaffWithAny() in Firestore rules looks up businesses/{bizId}/staff/{auth.uid}
      // directly. Permissions are mirrored here from the owner-controlled doc; the
      // Firestore rule enforces equality so the worker cannot self-elevate.
      batch.set(
        _db
            .collection('businesses')
            .doc(businessId)
            .collection('staff')
            .doc(uid),
        {
          'workerUid': uid,
          'memberId': memberId,
          'permissions': existingPermissions,
          'phone': phone,
          'status': 'active',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );
    }

    // 4. Mark pendingInvite as accepted.
    if (inviteId.isNotEmpty) {
      batch.set(_db.collection('pendingInvites').doc(inviteId), {
        'status': 'accepted',
        'pinCreated': true,
        'acceptedAt': FieldValue.serverTimestamp(),
        'uid': uid,
      }, SetOptions(merge: true));
    }

    try {
      await batch.commit();
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[OnboardingRepository.createTeamMemberAccount] batch commit failed '
          'for member=$memberId owner=$ownerUid phone=$phone: $e',
        );
      }
      rethrow;
    }
  }

  // ─── PIN RECOVERY ─────────────────────────────────────────────────────────

  /// Sends a Firebase password reset email to the user's real Auth email when
  /// the account was migrated away from its derived phone email.
  ///
  /// Returns the display email (shown to the user in the UI) on success,
  /// or null if recovery cannot proceed.
  Future<String?> sendPinRecovery({required String phone}) async {
    try {
      final derivedEmail = _emailFromPhone(phone);
      final emails = await _fetchUserAuthEmails(phone);
      final candidates = <String>{
        ...emails.where((email) => !email.endsWith('@mali.up')),
        derivedEmail,
        ...emails,
      };

      FirebaseAuthException? lastError;
      for (final email in candidates) {
        try {
          await _auth.sendPasswordResetEmail(email: email);
          return email;
        } on FirebaseAuthException catch (e) {
          lastError = e;
          if (e.code != 'user-not-found' && e.code != 'invalid-credential') {
            rethrow;
          }
        }
      }
      if (lastError != null) throw lastError;
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('[sendPinRecovery] $e');
      return null;
    }
  }

  /// Updates the current Firebase Auth user's email to [email].
  ///
  /// Called immediately after [createNewUserAccount] so that Firebase's
  /// password reset emails go to an inbox the user can actually access,
  /// rather than the derived `phone@mali.up` address. Silently ignores
  /// errors (e.g. email already taken) — the derived email remains as a
  /// fallback for [loginWithPin].
  Future<void> updateAuthEmail(String email) async {
    if (email.isEmpty) return;
    try {
      await _auth.currentUser?.verifyBeforeUpdateEmail(email);
    } catch (e) {
      if (kDebugMode) debugPrint('[OnboardingRepository.updateAuthEmail] $e');
    }
  }

  // ─── WRITE — USER ────────────────────────────────────────────────────────

  /// Creates or replaces the user document at `users/{userId}`.
  Future<void> saveUser({
    required String userId,
    required OnboardingState state,
    required String businessId,
  }) async {
    await _db.collection('users').doc(userId).set({
      'phone': PhoneNumberUtils.canonical(state.phone),
      'authEmail': _emailFromPhone(state.phone),
      'name': state.fullName,
      'firstName': state.firstName,
      'lastName': state.lastName,
      'email': state.email,
      'language': state.isSwahili ? 'sw' : 'en',
      'isTeamMember': false,
      'selectedBusinessId': businessId,
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
      'ownerUid': userId,
      'ownerName': state.fullName,
      'businessName': state.businessName,
      'businessCategory': state.businessType,
      'city': state.city,
      'region': state.businessRegion,
      'district': state.businessDistrict,
      'country': state.businessCountry,
      'websiteUrl': state.websiteUrl,
      'hasWebsite': state.hasWebsite,
      'websiteInterest': state.websiteInterest,
      'plan': 'Trial',
      'isActive': true,
      'subscriptionStatus': 'trial',
      'staffCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
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
    final password = buildAuthPasswordFromPin(phone: phone, pin: pin);
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

  /// Deletes the currently signed-in Firebase Auth user, if any.
  Future<void> deleteCurrentAuthUser() async {
    try {
      await _auth.currentUser?.delete();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[OnboardingRepository.deleteCurrentAuthUser] $e');
      }
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
    return PhoneNumberUtils.authEmail(phone);
  }

  /// Looks up possible Firebase Auth identifiers saved by different app
  /// generations. Contact/recovery emails are included as legacy fallbacks.
  Future<List<String>> _fetchUserAuthEmails(String phone) async {
    try {
      final doc = await _lookupUserByPhone(
        PhoneNumberUtils.lookupVariants(phone),
      );
      if (doc == null) return const [];
      final data = doc.data();
      return <String>{
        for (final field in ['authEmail', 'email', 'recoveryEmail'])
          if ((data[field] as String?)?.trim().isNotEmpty == true)
            (data[field] as String).trim().toLowerCase(),
      }.toList(growable: false);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[OnboardingRepository._fetchUserAuthEmails] $e');
      }
      return const [];
    }
  }

  Future<QueryDocumentSnapshot<Map<String, dynamic>>?> _lookupUserByPhone(
    List<String> variants,
  ) async {
    for (final field in ['phone', 'phoneNumber']) {
      for (final variant in variants) {
        final snap = await _db
            .collection('users')
            .where(field, isEqualTo: variant)
            .limit(1)
            .get();
        if (snap.docs.isNotEmpty) return snap.docs.first;
      }
    }
    return null;
  }

  Future<QueryDocumentSnapshot<Map<String, dynamic>>?>
  _lookupPendingInviteByPhone(List<String> variants) async {
    for (final variant in variants) {
      final snap = await _db
          .collection('pendingInvites')
          .where('phoneNumber', isEqualTo: variant)
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();
      if (snap.docs.isNotEmpty) return snap.docs.first;
    }
    return null;
  }

  // ─── GUARD ────────────────────────────────────────────────────────────────

  /// Returns the existing `selectedBusinessId` for [uid] if the user document
  /// already exists in Firestore, or null if this is a genuinely new user.
  /// Used to prevent overwriting data when a returning user accidentally
  /// reaches the new-user registration flow.
  Future<String?> getExistingBusinessId(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (!doc.exists) return null;
      final bizId = doc.data()?['selectedBusinessId'] as String?;
      return (bizId != null && bizId.isNotEmpty) ? bizId : null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[OnboardingRepository.getExistingBusinessId] $e');
      }
      return null;
    }
  }

  Future<QuerySnapshot<Map<String, dynamic>>?> _lookupTeamMemberByPhone(
    List<String> variants,
  ) async {
    try {
      for (final phone in variants) {
        final snap = await _db
            .collectionGroup('staff')
            .where('phone', isEqualTo: phone)
            .limit(1)
            .get();
        if (snap.docs.isNotEmpty) return snap;
      }
      return null;
    } on FirebaseException catch (e) {
      // `failed-precondition` = missing collectionGroup index.
      // `permission-denied`   = query requires auth (user is pre-login).
      // Both are non-fatal — skip this fallback and continue lookup.
      if (e.code == 'failed-precondition' || e.code == 'permission-denied') {
        if (kDebugMode) {
          debugPrint(
            '[OnboardingRepository] team_members lookup skipped (${e.code})',
          );
        }
        return null;
      }
      rethrow;
    }
  }
}
