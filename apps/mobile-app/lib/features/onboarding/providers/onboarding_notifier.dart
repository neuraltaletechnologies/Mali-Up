import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/services/onboarding_service.dart';
import '../domain/models/onboarding_state.dart';
import '../domain/models/user_lookup_result.dart';
import '../../../core/services/localization_service.dart';

// ─── PROVIDER ────────────────────────────────────────────────────────────────

/// The single source of truth for the onboarding flow.
/// GoRouter's redirect function reads this provider to enforce step guards.
final onboardingNotifierProvider =
    NotifierProvider<OnboardingNotifier, OnboardingState>(
  OnboardingNotifier.new,
);

// ─── NOTIFIER ────────────────────────────────────────────────────────────────

/// Manages all state transitions for the 7-screen onboarding flow.
///
/// Rules:
/// - Never imports Firebase or Firestore directly — all async work goes
///   through [OnboardingService].
/// - Every method that can fail wraps its body in try/catch and writes
///   a localised [OnboardingState.errorMessage] instead of throwing.
/// - Only one [isLoading = true] is active at a time.
class OnboardingNotifier extends Notifier<OnboardingState> {
  late final OnboardingService _service;
  Timer? _cooldownTimer;

  @override
  OnboardingState build() {
    // Service is injected via the provider graph — no direct Firebase import.
    _service = ref.read(onboardingServiceProvider);
    ref.onDispose(() => _cooldownTimer?.cancel());
    return const OnboardingState();
  }

  // ─── SCREEN 1 — WELCOME + LANGUAGE ───────────────────────────────────────

  void selectLanguage(AppLanguage language) {
    // Also propagates to the global LocalizationService so non-Riverpod
    // widgets (e.g. text field hints) pick up the selection immediately.
    LocalizationService.setLanguage(language);
    state = state.copyWith(language: language, clearError: true);
  }

  void advanceFromWelcome() {
    state = state.copyWith(
      currentStep: OnboardingStep.phoneEntry,
      clearError: true,
    );
  }

  // ─── SCREEN 2 — PHONE ENTRY ───────────────────────────────────────────────

  void setPhone(String phone) {
    state = state.copyWith(phone: phone, clearError: true);
  }

  /// Normalises the phone number to E.164 and sends the Firebase OTP.
  /// On success advances to [OnboardingStep.otpVerify] and starts the
  /// 30-second resend cooldown.
  Future<void> sendOtp() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _service.sendOtp(phone: state.phone);
      state = state.copyWith(
        verificationId: result.verificationId,
        resendToken: result.resendToken,
        currentStep: OnboardingStep.otpVerify,
        otpAttempts: 0,
        isOtpLocked: false,
        isLoading: false,
      );
      _startResendCooldown();
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _firebaseAuthMessage(e),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _t(
          en: 'Could not send code. Check your connection and try again.',
          sw: 'Imeshindwa kutuma msimbo. Angalia muunganiko na ujaribu tena.',
        ),
      );
    }
  }

  // ─── SCREEN 3 — OTP VERIFICATION ─────────────────────────────────────────

  /// Verifies [code] against Firebase Auth, then calls [OnboardingService]
  /// to look up the phone number in Firestore.
  ///
  /// On success:
  /// - Returning user → sets state fields from [ReturningUser] and advances
  ///   to [OnboardingStep.returningUser].
  /// - New user → advances to [OnboardingStep.newUserInfo].
  ///
  /// On failure:
  /// - Increments [otpAttempts]; locks input at 3 failures.
  /// - Wrong code and expired code produce distinct error messages.
  Future<void> verifyOtp(String code) async {
    if (state.isOtpLocked) return;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final result = await _service.verifyOtp(
        code: code,
        verificationId: state.verificationId,
        phone: state.phone,
      );

      _cooldownTimer?.cancel(); // OTP accepted — cooldown no longer relevant.

      switch (result.lookupResult) {
        case ReturningUser r:
          state = state.copyWith(
            isReturningUser: true,
            existingUserId: r.userId,
            firstName: r.firstName,
            lastName: r.lastName,
            city: r.city,
            role: r.role,
            businessName: r.businessName,
            businessType: r.businessType,
            businessId: r.businessId,
            currentStep: OnboardingStep.returningUser,
            isLoading: false,
          );

        case NewUser():
          state = state.copyWith(
            isReturningUser: false,
            currentStep: OnboardingStep.newUserInfo,
            isLoading: false,
          );
      }
    } on FirebaseAuthException catch (e) {
      _handleOtpFailure(e);
    } catch (e) {
      _handleOtpFailure(null);
    }
  }

  void _handleOtpFailure(FirebaseAuthException? e) {
    final attempts = state.otpAttempts + 1;
    final locked = attempts >= 3;
    state = state.copyWith(
      otpAttempts: attempts,
      isOtpLocked: locked,
      isLoading: false,
      errorMessage: locked
          ? _t(
              en: 'Too many attempts. Tap "Resend" to get a new code.',
              sw: 'Majaribio mengi mno. Bonyeza "Tuma Upya" kupata msimbo mpya.',
            )
          : _otpErrorMessage(e),
    );
  }

  /// Resends the OTP using the stored phone number and resend token.
  /// Respects the 30-second cooldown — no-op if called too early.
  Future<void> resendOtp() async {
    if (state.resendCooldownSeconds > 0) return;
    state = state.copyWith(
      otpAttempts: 0,
      isOtpLocked: false,
      clearError: true,
    );
    await sendOtp();
  }

  void _startResendCooldown() {
    _cooldownTimer?.cancel();
    state = state.copyWith(resendCooldownSeconds: 30);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      final remaining = state.resendCooldownSeconds - 1;
      if (remaining <= 0) {
        t.cancel();
        state = state.copyWith(resendCooldownSeconds: 0);
      } else {
        state = state.copyWith(resendCooldownSeconds: remaining);
      }
    });
  }

  // ─── SCREEN 4A — RETURNING USER ──────────────────────────────────────────

  /// The user chose to continue with their existing account.
  /// Touches lastActiveAt in Firestore and marks onboarding complete.
  Future<void> continueAsReturningUser() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _service.continueAsReturningUser(state.existingUserId);
      state = state.copyWith(
        currentStep: OnboardingStep.success,
        isComplete: true,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _t(
          en: 'Something went wrong. Please try again.',
          sw: 'Hitilafu imetokea. Tafadhali jaribu tena.',
        ),
      );
    }
  }

  /// The user confirmed "that's not me" — reset personal + business fields
  /// and fall through to the new-user registration path.
  void startOverAsNewUser() {
    state = state.copyWith(
      isReturningUser: false,
      existingUserId: '',
      firstName: '',
      lastName: '',
      city: '',
      role: '',
      businessName: '',
      businessType: '',
      businessId: '',
      currentStep: OnboardingStep.newUserInfo,
      clearError: true,
    );
  }

  // ─── SCREEN 4B — NEW USER PERSONAL INFO ──────────────────────────────────

  void setFirstName(String v) =>
      state = state.copyWith(firstName: v, clearError: true);
  void setLastName(String v) =>
      state = state.copyWith(lastName: v, clearError: true);
  void setCity(String v) =>
      state = state.copyWith(city: v, clearError: true);
  void setRole(String v) =>
      state = state.copyWith(role: v, clearError: true);

  void advanceFromPersonalInfo() {
    state = state.copyWith(
      currentStep: OnboardingStep.businessDetails,
      clearError: true,
    );
  }

  // ─── SCREEN 5 — BUSINESS DETAILS ─────────────────────────────────────────

  void setBusinessName(String v) =>
      state = state.copyWith(businessName: v, clearError: true);
  void setBusinessType(String v) =>
      state = state.copyWith(businessType: v, clearError: true);

  void advanceFromBusinessDetails() {
    state = state.copyWith(
      currentStep: OnboardingStep.passwordPin,
      clearError: true,
    );
  }

  // ─── SCREEN 6 — PASSWORD + PIN ────────────────────────────────────────────

  void setPassword(String v) =>
      state = state.copyWith(password: v, clearError: true);
  void setPin(String v) =>
      state = state.copyWith(pin: v, clearError: true);

  /// Saves the user profile and business profile to Firestore, then marks
  /// onboarding as complete and advances to the success screen.
  ///
  /// If either write fails the error is shown inline and the screen does NOT
  /// advance — the user can retry safely (writes are idempotent via .set()).
  Future<void> saveAndComplete() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _service.saveNewUser(state);
      final bizId = await _service.saveBusinessProfile(state);
      await _service.completeOnboarding();

      state = state.copyWith(
        businessId: bizId,
        isLoading: false,
        isComplete: true,
        currentStep: OnboardingStep.success,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _t(
          en: 'Could not save your profile. Please try again.',
          sw: 'Imeshindwa kuhifadhi wasifu wako. Tafadhali jaribu tena.',
        ),
      );
    }
  }

  // ─── GLOBAL HELPERS ──────────────────────────────────────────────────────

  void clearError() => state = state.copyWith(clearError: true);

  /// Full reset — used when the user navigates back to the splash or
  /// when a sign-out event fires mid-flow.
  void reset() {
    _cooldownTimer?.cancel();
    state = const OnboardingState();
  }

  // ─── PRIVATE HELPERS ─────────────────────────────────────────────────────

  bool get _sw => state.isSwahili;

  String _t({required String en, required String sw}) => _sw ? sw : en;

  String _otpErrorMessage(FirebaseAuthException? e) {
    final code = e?.code ?? '';
    if (code == 'invalid-verification-code') {
      return _t(
        en: 'Incorrect code. Please check and try again.',
        sw: 'Msimbo si sahihi. Angalia na ujaribu tena.',
      );
    }
    if (code == 'session-expired' || code == 'code-expired') {
      return _t(
        en: 'Code has expired. Tap "Resend" to get a fresh one.',
        sw: 'Msimbo umeisha muda wake. Bonyeza "Tuma Upya" kupata mpya.',
      );
    }
    return _t(
      en: 'Verification failed. Please try again.',
      sw: 'Uhakiki umeshindwa. Tafadhali jaribu tena.',
    );
  }

  String _firebaseAuthMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-phone-number':
        return _t(
          en: 'Invalid phone number. Please check and try again.',
          sw: 'Namba ya simu si sahihi. Angalia na ujaribu tena.',
        );
      case 'too-many-requests':
        return _t(
          en: 'Too many requests. Please wait a moment and try again.',
          sw: 'Maombi mengi sana. Subiri kidogo kisha ujaribu tena.',
        );
      case 'quota-exceeded':
        return _t(
          en: 'SMS quota exceeded. Please try again later.',
          sw: 'Ukomo wa SMS umefikiwa. Jaribu tena baadaye.',
        );
      default:
        return _t(
          en: 'Could not send code. Please try again.',
          sw: 'Imeshindwa kutuma msimbo. Jaribu tena.',
        );
    }
  }
}
