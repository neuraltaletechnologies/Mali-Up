import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/onboarding_state.dart';
import '../../domain/models/user_lookup_result.dart';
import '../repositories/onboarding_repository.dart';

// ─── PROVIDER ────────────────────────────────────────────────────────────────

final onboardingServiceProvider = Provider<OnboardingService>((ref) {
  return OnboardingService(
    repository: ref.read(onboardingRepositoryProvider),
  );
});

// ─── SERVICE ──────────────────────────────────────────────────────────────────

/// Orchestrates the onboarding flow.
///
/// No OTP — authentication is PIN-based (phone → derive email+password).
/// All Firebase Auth and Firestore calls delegate to [OnboardingRepository].
class OnboardingService {
  OnboardingService({required OnboardingRepository repository})
      : _repository = repository;

  final OnboardingRepository _repository;

  static const _completedKey = 'mali_onboarding_complete';

  // ─── ONBOARDING STATUS ────────────────────────────────────────────────────

  Future<bool> checkOnboardingStatus() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_completedKey) ?? false;
  }

  // ─── SCREEN 3 — PHONE LOOKUP ─────────────────────────────────────────────

  /// Looks up [phone] in Firestore and returns the appropriate [UserLookupResult].
  Future<UserLookupResult> lookupPhone({required String phone}) {
    return _repository.lookupByPhone(phone);
  }

  // ─── SCREEN 4A — EXISTING USER PIN LOGIN ─────────────────────────────────

  /// Signs in with [pin], touches lastActiveAt, marks onboarding complete.
  ///
  /// Throws [FirebaseAuthException] on wrong PIN — notifier shows error.
  Future<void> loginWithPin({
    required String phone,
    required String pin,
    required String userId,
  }) async {
    await _repository.loginWithPin(phone: phone, pin: pin);
    await Future.wait([
      _repository.touchLastActive(userId),
      completeOnboarding(),
    ]);
  }

  // ─── SCREEN 4B — TEAM MEMBER FIRST-TIME SETUP ────────────────────────────

  /// Creates a Firebase Auth account + user document for a pending team member,
  /// marks the invite record as accepted, then marks onboarding complete.
  Future<void> setupTeamMemberPin({
    required String phone,
    required String pin,
    required String name,
    required String role,
    required String ownerUid,
    required String businessId,
    required String memberId,
    String inviteId = '',
  }) async {
    await _repository.createTeamMemberAccount(
      phone: phone,
      pin: pin,
      name: name,
      role: role,
      ownerUid: ownerUid,
      businessId: businessId,
      memberId: memberId,
      inviteId: inviteId,
    );
    await completeOnboarding();
  }

  // ─── PIN RECOVERY ─────────────────────────────────────────────────────────

  /// Triggers a PIN recovery flow. Returns the real email on file (if any).
  Future<String?> sendPinRecovery({required String phone}) {
    return _repository.sendPinRecovery(phone: phone);
  }

  // ─── SCREEN 6 — NEW OWNER ACCOUNT CREATION ───────────────────────────────

  /// Creates a Firebase Auth account (email = phone@mali.up, password derived
  /// from PIN), writes user + business profiles to Firestore, marks complete.
  /// Returns the auto-generated business document ID.
  Future<String> saveAndCompleteNewUser(OnboardingState state) async {
    final uid = await _repository.createNewUserAccount(
      phone: state.phone,
      pin: state.pin,
    );
    final bizId = await _repository.saveBusinessProfile(userId: uid, state: state);
    await _repository.saveUser(userId: uid, state: state, businessId: bizId);
    await completeOnboarding();
    if (kDebugMode) debugPrint('[OnboardingService] new user saved uid=$uid');
    return bizId;
  }

  // ─── COMPLETION ──────────────────────────────────────────────────────────

  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_completedKey, true);
    if (kDebugMode) debugPrint('[OnboardingService] onboarding complete ✓');
  }

  Future<void> resetOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_completedKey);
  }
}
