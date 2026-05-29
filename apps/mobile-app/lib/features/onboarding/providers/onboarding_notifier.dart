import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
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

/// Manages all state transitions for the onboarding flow.
///
/// Rules:
/// - Never imports Firebase or Firestore directly — all async work goes
///   through [OnboardingService].
/// - Every method that can fail wraps its body in try/catch and writes
///   a localised [OnboardingState.errorMessage] instead of throwing.
/// - Only one [isLoading = true] is active at a time.
class OnboardingNotifier extends Notifier<OnboardingState> {
  late final OnboardingService _service;

  @override
  OnboardingState build() {
    _service = ref.read(onboardingServiceProvider);
    return const OnboardingState();
  }

  String _accountCreationErrorMessage(Object error) {
    if (error is SocketException ||
        (error is FirebaseAuthException &&
            error.code == 'network-request-failed')) {
      return _t(
        en: 'No internet connection. Please connect to the internet to continue and try again.',
        sw: 'Hakuna muunganisho wa intaneti. Tafadhali unganisha kwenye intaneti ili kuendelea na ujaribu tena.',
      );
    }

    if (error is FirebaseException) {
      if (error.code == 'permission-denied') {
        return _t(
          en: 'Your account was created, but the app could not save your profile data. Please try again.',
          sw: 'Akaunti yako imeundwa, lakini app haikuweza kuhifadhi taarifa zako. Tafadhali jaribu tena.',
        );
      }

      if (error.code == 'unavailable' || error.code == 'deadline-exceeded') {
        return _t(
          en: 'Firestore is temporarily unavailable. Please try again.',
          sw: 'Firestore haipatikani kwa sasa. Tafadhali jaribu tena.',
        );
      }
    }

    if (error is FirebaseAuthException && error.code == 'email-already-in-use') {
      return _t(
        en: 'This account already exists. Go back and sign in with your PIN.',
        sw: 'Akaunti hii tayari ipo. Rudi nyuma uingie kwa PIN yako.',
      );
    }

    return _t(
      en: 'Could not create your account. Please try again.',
      sw: 'Imeshindwa kuunda akaunti yako. Tafadhali jaribu tena.',
    );
  }

  // ─── SCREEN 1 — WELCOME + LANGUAGE ───────────────────────────────────────

  void selectLanguage(AppLanguage language) {
    LocalizationService.setLanguage(language);
    state = state.copyWith(language: language, clearError: true);
  }

  void advanceFromWelcome() {
    state = state.copyWith(
      currentStep: OnboardingStep.intro,
      clearError: true,
    );
  }

  // ─── SCREEN 2 — INTRO SLIDES ─────────────────────────────────────────────

  void advanceFromIntro() {
    state = state.copyWith(
      currentStep: OnboardingStep.phoneEntry,
      clearError: true,
    );
  }

  // ─── SCREEN 3 — PHONE ENTRY + LOOKUP ─────────────────────────────────────

  void setPhone(String phone) {
    state = state.copyWith(phone: phone, clearError: true);
  }

  /// Looks up the phone number in Firestore (no OTP).
  /// On success advances to the appropriate step based on the result:
  /// - [ReturningUser]     → [OnboardingStep.pinLogin]
  /// - [TeamMemberPending] → [OnboardingStep.teamMemberSetup]
  /// - [NewUser]           → [OnboardingStep.newUserInfo]
  Future<void> lookupPhone() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      // Explicit internet connection check
      final result = await InternetAddress.lookup('google.com');
      if (result.isEmpty || result[0].rawAddress.isEmpty) {
        throw const SocketException('No internet connection');
      }

      final lookupResult = await _service.lookupPhone(phone: state.phone);

      switch (lookupResult) {
        case final ReturningUser r:
          state = state.copyWith(
            isReturningUser: true,
            isTeamMember: false,
            existingUserId: r.userId,
            firstName: r.firstName,
            lastName: r.lastName,
            city: r.city,
            role: r.role,
            businessName: r.businessName,
            businessType: r.businessType,
            businessId: r.businessId,
            currentStep: OnboardingStep.pinLogin,
            isLoading: false,
          );

        case final TeamMemberPending t:
          final parts = t.name.trim().split(RegExp(r'\s+'));
          state = state.copyWith(
            isReturningUser: false,
            isTeamMember: true,
            teamMemberId: t.memberId,
            teamOwnerUid: t.ownerUid,
            businessId: t.businessId,
            businessName: t.businessName,
            inviteId: t.inviteId,
            memberEmail: t.email,
            firstName: parts.isNotEmpty ? parts.first : t.name,
            lastName: parts.length > 1 ? parts.skip(1).join(' ') : '',
            role: t.role,
            currentStep: OnboardingStep.teamMemberSetup,
            isLoading: false,
          );

        case NewUser():
          state = state.copyWith(
            isReturningUser: false,
            isTeamMember: false,
            currentStep: OnboardingStep.newUserInfo,
            isLoading: false,
          );
      }
    } on TimeoutException {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _t(
          en: 'The lookup server is taking too long. Check your connection or API host and try again.',
          sw: 'Seva ya kutafuta inachukua muda mrefu. Angalia muunganiko wako au API host kisha ujaribu tena.',
        ),
      );
    } on SocketException {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _t(
          en: 'Unable to reach the lookup server. Check your network or API host and try again.',
          sw: 'Imeshindikana kufikia seva ya kutafuta. Angalia mtandao wako au API host kisha ujaribu tena.',
        ),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _t(
          en: 'Could not look up your account. Check your connection and try again.',
          sw: 'Imeshindwa kutafuta akaunti yako. Angalia muunganiko na ujaribu tena.',
        ),
      );
    }
  }

  // ─── SCREEN 4A — EXISTING USER PIN LOGIN ─────────────────────────────────

  /// Signs the user in with their PIN, marks onboarding complete.
  Future<void> loginWithPin(String pin) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _service.loginWithPin(
        phone: state.phone,
        pin: pin,
        userId: state.existingUserId,
      );
      state = state.copyWith(
        pin: pin,
        currentStep: OnboardingStep.success,
        isComplete: true,
        isLoading: false,
      );
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _pinLoginError(e),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _t(
          en: 'Sign in failed. Please try again.',
          sw: 'Kuingia kumeshindwa. Tafadhali jaribu tena.',
        ),
      );
    }
  }

  // ─── SCREEN 4B — TEAM MEMBER SETUP ───────────────────────────────────────

  /// Called when a pending team member chooses to continue as themselves.
  /// Advances to the PIN setup step.
  void continueAsTeamMember() {
    state = state.copyWith(
      currentStep: OnboardingStep.pinSetup,
      clearError: true,
    );
  }

  /// Team member chose "start fresh" — clear invite state and route to new user.
  void startOverFromTeamMember() {
    state = state.copyWith(
      isTeamMember: false,
      teamMemberId: '',
      teamOwnerUid: '',
      inviteId: '',
      memberEmail: '',
      firstName: '',
      lastName: '',
      role: '',
      businessName: '',
      businessType: '',
      businessId: '',
      currentStep: OnboardingStep.newUserInfo,
      clearError: true,
    );
  }

  // ─── PIN RECOVERY ─────────────────────────────────────────────────────────

  /// Sends PIN recovery instructions. Returns the real email on file (if any).
  Future<String?> sendPinRecovery() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final email = await _service.sendPinRecovery(phone: state.phone);
      state = state.copyWith(isLoading: false);
      return email;
    } catch (_) {
      state = state.copyWith(isLoading: false);
      return null;
    }
  }

  /// Saves the team member's first-time PIN, creates their account, and
  /// marks onboarding complete.
  Future<void> saveTeamMemberPin(String pin) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _service.setupTeamMemberPin(
        phone: state.phone,
        pin: pin,
        name: state.fullName.isNotEmpty ? state.fullName : state.firstName,
        role: state.role,
        ownerUid: state.teamOwnerUid,
        businessId: state.businessId,
        memberId: state.teamMemberId,
        inviteId: state.inviteId,
      );
      state = state.copyWith(
        pin: pin,
        currentStep: OnboardingStep.success,
        isComplete: true,
        isLoading: false,
      );
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _accountCreationErrorMessage(e),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _accountCreationErrorMessage(e),
      );
    }
  }

  // ─── SCREEN 4C — NEW USER PERSONAL INFO ──────────────────────────────────

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
  void setBusinessCountry(String v) =>
      state = state.copyWith(businessCountry: v, clearError: true);
  void setBusinessRegion(String v) =>
      state = state.copyWith(businessRegion: v, clearError: true);
  void setBusinessDistrict(String v) =>
      state = state.copyWith(businessDistrict: v, clearError: true);

  void advanceFromBusinessDetails() {
    state = state.copyWith(
      currentStep: OnboardingStep.pinSetup,
      clearError: true,
    );
  }

  // ─── SCREEN 6 — PIN SETUP ────────────────────────────────────────────────

  void setPin(String v) =>
      state = state.copyWith(pin: v, clearError: true);
  void setConfirmPin(String v) =>
      state = state.copyWith(confirmPin: v, clearError: true);

  /// For new owners: creates Firebase Auth account, saves profiles, completes.
  Future<void> saveAndComplete() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final bizId = await _service.saveAndCompleteNewUser(state);
      state = state.copyWith(
        businessId: bizId,
        isLoading: false,
        isComplete: true,
        currentStep: OnboardingStep.success,
      );
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _accountCreationErrorMessage(e),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _accountCreationErrorMessage(e),
      );
    }
  }

  // ─── GLOBAL HELPERS ──────────────────────────────────────────────────────

  void clearError() => state = state.copyWith(clearError: true);

  void reset() {
    state = const OnboardingState();
  }

  // ─── PRIVATE HELPERS ─────────────────────────────────────────────────────

  bool get _sw => state.isSwahili;

  String _t({required String en, required String sw}) => _sw ? sw : en;

  String _pinLoginError(FirebaseAuthException e) {
    switch (e.code) {
      case 'wrong-password':
      case 'invalid-credential':
        return _t(
          en: 'Incorrect PIN. Please try again.',
          sw: 'PIN si sahihi. Tafadhali jaribu tena.',
        );
      case 'user-not-found':
        return _t(
          en: 'Account not found. Please register first.',
          sw: 'Akaunti haikupatikana. Tafadhali jisajili kwanza.',
        );
      case 'too-many-requests':
        return _t(
          en: 'Too many attempts. Please wait and try again.',
          sw: 'Majaribio mengi. Subiri kidogo kisha ujaribu tena.',
        );
      default:
        return _t(
          en: 'Sign in failed. Please try again.',
          sw: 'Kuingia kumeshindwa. Jaribu tena.',
        );
    }
  }
}
