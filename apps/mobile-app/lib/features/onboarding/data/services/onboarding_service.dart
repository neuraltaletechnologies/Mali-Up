import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/onboarding_state.dart';
import '../../domain/models/user_lookup_result.dart';
import '../repositories/onboarding_repository.dart';

// ─── PROVIDERS ────────────────────────────────────────────────────────────────

final onboardingServiceProvider = Provider<OnboardingService>((ref) {
  return OnboardingService(
    repository: ref.read(onboardingRepositoryProvider),
  );
});

// ─── RESULT TYPES ─────────────────────────────────────────────────────────────

/// Returned by [OnboardingService.verifyOtp].
class OtpVerifyResult {
  const OtpVerifyResult({
    required this.userId,
    required this.lookupResult,
  });

  final String userId;
  final UserLookupResult lookupResult;
}

/// Returned by [OnboardingService.sendOtp].
class SendOtpResult {
  const SendOtpResult({
    required this.verificationId,
    this.resendToken,
  });

  final String verificationId;
  final int? resendToken;
}

// ─── SERVICE ──────────────────────────────────────────────────────────────────

/// Orchestrates the full onboarding flow.
///
/// Responsibilities:
/// - Firebase Auth interactions (send OTP, verify OTP).
/// - Delegates all Firestore reads/writes to [OnboardingRepository].
/// - Manages the SharedPreferences `onboarding_complete` flag.
///
/// The [OnboardingNotifier] depends on this class through the Riverpod graph
/// and never imports Firebase directly.
class OnboardingService {
  OnboardingService({
    required OnboardingRepository repository,
    FirebaseAuth? auth,
  })  : _repository = repository,
        _auth = auth ?? FirebaseAuth.instance;

  final OnboardingRepository _repository;
  final FirebaseAuth _auth;

  static const _completedKey = 'mali_onboarding_complete';

  // ─── ONBOARDING STATUS ────────────────────────────────────────────────────

  /// Returns true if the user has previously completed the full flow.
  /// Called on app launch to decide whether to skip to the dashboard.
  Future<bool> checkOnboardingStatus() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_completedKey) ?? false;
  }

  // ─── SCREEN 2 — SEND OTP ─────────────────────────────────────────────────

  /// Triggers a Firebase SMS verification for [phone] (must be E.164 format).
  ///
  /// Throws on network or auth failure; the notifier converts the exception
  /// into a user-visible error string.
  Future<SendOtpResult> sendOtp({
    required String phone,
    int? resendToken,
  }) async {
    final completer = Completer<SendOtpResult>();

    await _auth.verifyPhoneNumber(
      phoneNumber: phone,
      forceResendingToken: resendToken,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (credential) async {
        // Auto-retrieval on Android — sign in silently; the OTP screen
        // will still get the result through verifyOtp().
        try {
          await _auth.signInWithCredential(credential);
        } catch (_) {}
      },
      verificationFailed: (e) {
        if (!completer.isCompleted) {
          completer.completeError(e);
        }
      },
      codeSent: (verificationId, newResendToken) {
        if (!completer.isCompleted) {
          completer.complete(SendOtpResult(
            verificationId: verificationId,
            resendToken: newResendToken,
          ));
        }
      },
      codeAutoRetrievalTimeout: (verificationId) {
        // The 60-second window closed — the ID is still valid for manual entry.
        if (!completer.isCompleted) {
          completer.complete(
            SendOtpResult(verificationId: verificationId),
          );
        }
      },
    );

    return completer.future;
  }

  // ─── SCREEN 3 — VERIFY OTP ───────────────────────────────────────────────

  /// Verifies the 6-digit [code] with Firebase Auth, then looks up the phone
  /// number in Firestore to decide if this is a returning or new user.
  ///
  /// Throws [FirebaseAuthException] for wrong/expired code — the notifier
  /// inspects the error code to produce localised copy.
  Future<OtpVerifyResult> verifyOtp({
    required String code,
    required String verificationId,
    required String phone,
  }) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: code,
    );

    final userCredential = await _auth.signInWithCredential(credential);
    final user = userCredential.user;
    if (user == null) throw Exception('Firebase Auth returned a null user.');

    // Firestore lookup — returns NewUser on any network failure (safe default).
    final lookupResult = await _repository.lookupByPhone(phone);

    return OtpVerifyResult(userId: user.uid, lookupResult: lookupResult);
  }

  // ─── SCREEN 4A — RETURNING USER ──────────────────────────────────────────

  /// Updates `lastActiveAt` for returning users and marks onboarding done.
  Future<void> continueAsReturningUser(String userId) async {
    await Future.wait([
      _repository.touchLastActive(userId),
      completeOnboarding(),
    ]);
  }

  // ─── SCREEN 6 — SAVE NEW USER ─────────────────────────────────────────────

  /// Writes the user's personal profile document to `users/{uid}`.
  ///
  /// Throws on Firestore write failure — the notifier shows a retry error
  /// and does NOT advance to the next screen.
  Future<void> saveNewUser(OnboardingState state) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('No authenticated user found.');
    await _repository.saveUser(userId: userId, state: state);
  }

  /// Creates the business profile document in `businesses/` and returns
  /// the auto-generated document ID (stored back into state.businessId).
  ///
  /// Throws on Firestore write failure — caller should retry, not advance.
  Future<String> saveBusinessProfile(OnboardingState state) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('No authenticated user found.');
    return _repository.saveBusinessProfile(userId: userId, state: state);
  }

  // ─── SCREEN 7 — COMPLETION ───────────────────────────────────────────────

  /// Persists the completion flag. GoRouter redirect observes
  /// [OnboardingState.isComplete] (set by the notifier) and navigates
  /// to `/dashboard` — this method just makes the flag survive a restart.
  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_completedKey, true);
    if (kDebugMode) debugPrint('[OnboardingService] onboarding complete ✓');
  }

  /// Resets the completion flag — for testing or re-onboarding flows.
  Future<void> resetOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_completedKey);
  }
}
