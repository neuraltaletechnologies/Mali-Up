import 'dart:async';
import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/services/onboarding_service.dart';
import '../domain/models/onboarding_state.dart';
import '../domain/models/pin_reset_result.dart';
import '../domain/models/user_lookup_result.dart';
import '../../../core/services/device_integrity_service.dart';
import '../../../core/services/error_reporter.dart';
import '../../../core/services/localization_service.dart';
import '../../../core/services/sentry_metrics_service.dart';
import '../../rbac/data/role_cache_service.dart';

export '../data/services/onboarding_service.dart' show OnboardingDraft;

// ─── BOOTSTRAP PROVIDER ──────────────────────────────────────────────────────

/// Seeded by [main.dart] via ProviderScope.overrides before the first frame so
/// the router knows immediately whether to skip to /dashboard.
///
/// Usage in main.dart:
/// ```dart
/// ProviderScope(
///   overrides: [
///     onboardingBootstrapProvider.overrideWithValue(hasCompletedOnboarding),
///   ],
///   child: MaliUpApp(),
/// )
/// ```
final onboardingBootstrapProvider = Provider<bool>((_) => false);

/// When true on cold-start (onboarding was previously completed but there is no
/// active Firebase session — i.e. the user logged out then closed the app),
/// the notifier initialises at the phone-entry step so the router can send the
/// user straight to /phone without replaying the language + intro screens.
final onboardingPhoneEntryBootstrapProvider = Provider<bool>((_) => false);

/// Pre-loaded new-user registration draft.  Seeded by main.dart so the notifier
/// can restore the user's partially-completed personal/business info on cold-start.
final onboardingDraftBootstrapProvider = Provider<OnboardingDraft?>((_) => null);

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
    final startAtPhoneEntry = ref.read(onboardingPhoneEntryBootstrapProvider);
    if (startAtPhoneEntry) {
      // Onboarding was completed before but there is no active session (logged
      // out then app was killed). Skip language + intro and land at phone entry.
      return const OnboardingState(currentStep: OnboardingStep.phoneEntry);
    }
    // If main.dart seeded the bootstrap provider as true, the user has already
    // completed onboarding — start in a done state so the router redirects
    // immediately to /dashboard without any intermediate flicker.
    final alreadyComplete = ref.read(onboardingBootstrapProvider);
    if (!alreadyComplete) {
      final draft = ref.read(onboardingDraftBootstrapProvider);
      if (draft != null) {
        return OnboardingState(
          currentStep:     draft.currentStep,
          phone:           draft.phone,
          firstName:       draft.firstName,
          lastName:        draft.lastName,
          email:           draft.email,
          city:            draft.city,
          businessName:    draft.businessName,
          businessType:    draft.businessType,
          businessCountry: draft.businessCountry,
          businessRegion:  draft.businessRegion,
          businessDistrict:draft.businessDistrict,
          websiteUrl:      draft.websiteUrl,
          hasWebsite:      draft.hasWebsite,
          websiteInterest: draft.websiteInterest,
        );
      }
    }
    return OnboardingState(isComplete: alreadyComplete);
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
      // 15-second guard: Firestore will throw SocketException on its own if
      // there is no network, so we don't need an InternetAddress.lookup check
      // (which is unreliable on emulators and restricted networks).
      final lookupResult = await _service
          .lookupPhone(phone: state.phone)
          .timeout(const Duration(seconds: 15));

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
            businessLogo: r.businessLogo ?? '',
            businessId: r.businessId,
            ownedBusinesses: r.businesses,
            currentStep: OnboardingStep.pinLogin,
            isLoading: false,
          );
          // Pre-warm the role cache so that when loginWithPin fires
          // Firebase Auth's authStateChanges, userProfileStreamProvider
          // gets an immediate cache hit and permissionsLoaded settles
          // synchronously — preventing the shell from mounting with
          // PermissionService.denied() on a device with no prior cache.
          unawaited(
            RoleCacheService.save(r.userId, {'isTeamMember': false}).catchError(
              (Object e) {
                if (kDebugMode) debugPrint('[Onboarding] role cache pre-warm failed: $e');
              },
            ),
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
    } on TimeoutException catch (e, st) {
      ErrorReporter.captureException(e, stackTrace: st);
      SentryMetricsService.authFailure('phone_lookup', 'timeout');
      state = state.copyWith(
        isLoading: false,
        errorMessage: _t(
          en: 'The server is taking too long. Check your connection and try again.',
          sw: 'Seva inachukua muda mrefu. Angalia muunganiko wako na ujaribu tena.',
        ),
      );
    } on SocketException catch (e, st) {
      ErrorReporter.captureException(e, stackTrace: st);
      SentryMetricsService.authFailure('phone_lookup', 'network');
      state = state.copyWith(
        isLoading: false,
        errorMessage: _t(
          en: 'Unable to reach the server. Check your network and try again.',
          sw: 'Imeshindikana kufikia seva . Angalia mtandao wako na ujaribu tena.',
        ),
      );
    } catch (e, st) {
      ErrorReporter.captureException(e, stackTrace: st);
      SentryMetricsService.authFailure('phone_lookup', 'unknown');
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
        businessId: state.businessId,
        performedByName: state.fullName,
      );
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        unawaited(DeviceIntegrityService.checkAndLog(
          businessId: state.businessId,
          performedByUid: uid,
        ));
      }
      SentryMetricsService.authSuccess('pin_login');
      state = state.copyWith(
        pin: pin,
        currentStep: OnboardingStep.success,
        isComplete: true,
        isLoading: false,
      );
    } on FirebaseAuthException catch (e, st) {
      ErrorReporter.captureException(e, stackTrace: st);
      SentryMetricsService.authFailure('pin_login', e.code);
      state = state.copyWith(
        isLoading: false,
        errorMessage: _pinLoginError(e),
      );
    } catch (e, st) {
      ErrorReporter.captureException(e, stackTrace: st);
      SentryMetricsService.authFailure('pin_login', 'unknown');
      state = state.copyWith(
        isLoading: false,
        errorMessage: _t(
          en: 'Sign in failed. Please try again.',
          sw: 'Kuingia kumeshindwa. Tafadhali jaribu tena.',
        ),
      );
    }
  }

  /// Owner tapped a business in the PIN-screen picker. Mirrors the chosen
  /// business into the `business*` fields so [loginWithPin] signs them in
  /// against it and the dashboard opens it.
  void selectLoginBusiness(String businessId) {
    if (businessId == state.businessId) return;
    BusinessSummary? match;
    for (final b in state.ownedBusinesses) {
      if (b.id == businessId) {
        match = b;
        break;
      }
    }
    if (match == null) return;
    state = state.copyWith(
      businessId: match.id,
      businessName: match.name,
      businessType: match.type,
      businessLogo: match.logoUrl ?? '',
      clearError: true,
    );
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

  /// Step 1 — asks the backend to email a recovery magic link for [state.phone].
  Future<PinResetRequestResult> requestPinReset() async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _service.requestPinReset(
      phone: state.phone,
      language: _sw ? 'sw' : 'en',
    );
    state = state.copyWith(isLoading: false);
    return result;
  }

  /// Step 2 — validates a token opened from the magic link.
  Future<PinResetTokenInfo> validatePinResetToken(String token) {
    return _service.validatePinResetToken(token);
  }

  /// Step 3 — sets the new PIN. On success, seeds phone + runs the returning-user
  /// lookup so the PIN login screen renders correctly, and sets [pinJustReset]
  /// so it shows a confirmation toast.
  Future<PinResetConfirmResult> confirmPinReset({
    required String token,
    required String phone,
    required String newPin,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _service.confirmPinReset(
      token: token,
      phone: phone,
      newPin: newPin,
    );
    if (result == PinResetConfirmResult.ok) {
      state = state.copyWith(phone: phone, isLoading: false, pinJustReset: true);
      // Populates isReturningUser / currentStep / name / businesses so the
      // router lets /pin-login through and the greeting card is filled in.
      await lookupPhone();
    } else {
      state = state.copyWith(isLoading: false);
    }
    return result;
  }

  /// Clears the one-shot [OnboardingState.pinJustReset] flag once the PIN login
  /// screen has shown its confirmation.
  void clearPinJustReset() {
    if (state.pinJustReset) state = state.copyWith(pinJustReset: false);
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
        email: state.email,
      );
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        unawaited(DeviceIntegrityService.checkAndLog(
          businessId: state.businessId,
          performedByUid: uid,
        ));
      }
      SentryMetricsService.authSuccess('team_member_setup');
      state = state.copyWith(
        pin: pin,
        currentStep: OnboardingStep.success,
        isComplete: true,
        isLoading: false,
      );
    } on FirebaseFunctionsException catch (e, st) {
      ErrorReporter.captureException(e, stackTrace: st);
      SentryMetricsService.authFailure('team_member_setup', e.code);
      state = state.copyWith(
        // Send them back to the OTP step rather than leaving otpVerified
        // true with no way to pass consumeOtpVerification again.
        otpVerified: e.code == 'failed-precondition' ? false : state.otpVerified,
        isLoading: false,
        errorMessage: e.code == 'failed-precondition'
            ? _t(
                en: 'Phone verification expired. Please verify your number again.',
                sw: 'Uthibitisho wa namba ya simu umeisha muda. Tafadhali thibitisha namba yako tena.',
              )
            : _accountCreationErrorMessage(e),
      );
    } on FirebaseAuthException catch (e, st) {
      ErrorReporter.captureException(e, stackTrace: st);
      SentryMetricsService.authFailure('team_member_setup', e.code);
      state = state.copyWith(
        isLoading: false,
        errorMessage: _accountCreationErrorMessage(e),
      );
    } catch (e, st) {
      ErrorReporter.captureException(e, stackTrace: st);
      SentryMetricsService.authFailure('team_member_setup', 'unknown');
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
  void setEmail(String v) =>
      state = state.copyWith(email: v, clearError: true);

  void advanceFromPersonalInfo() {
    state = state.copyWith(
      currentStep: OnboardingStep.businessDetails,
      clearError: true,
    );
    _service.saveDraft(state);
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
  void setWebsiteUrl(String v) =>
      state = state.copyWith(websiteUrl: v, clearError: true);
  void setHasWebsite(bool v) =>
      state = state.copyWith(hasWebsite: v, clearError: true);
  void setWebsiteInterest(bool v) =>
      state = state.copyWith(websiteInterest: v, clearError: true);

  void advanceFromBusinessDetails() {
    state = state.copyWith(
      currentStep: OnboardingStep.pinSetup,
      clearError: true,
    );
    _service.saveDraft(state);
  }

  // ─── OTP VERIFICATION (first-time registration only) ────────────────────
  //
  // Shared by Screen 6 (new owner) and Screen 4B (team member first PIN
  // setup) — both are pre-auth account-creation flows. Returning-user PIN
  // login is untouched. See BEEM_OTP_INTEGRATION.md.

  /// Requests a Beem OTP be sent to [OnboardingState.phone]. Returns true on
  /// success (state.otpPinId is set); false on failure (state.errorMessage
  /// is set).
  Future<bool> sendOtp() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final pinId = await _service.sendOtp(phone: state.phone);
      state = state.copyWith(otpPinId: pinId, isLoading: false);
      return true;
    } on FirebaseFunctionsException catch (e, st) {
      ErrorReporter.captureException(e, stackTrace: st);
      SentryMetricsService.authFailure('otp_send', e.code);
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.code == 'resource-exhausted'
            ? _t(
                en: 'Too many attempts. Please wait a few minutes and try again.',
                sw: 'Majaribio mengi. Subiri dakika chache kisha ujaribu tena.',
              )
            : _t(
                en: 'Could not send the verification code. Please try again.',
                sw: 'Imeshindwa kutuma msimbo wa uthibitisho. Tafadhali jaribu tena.',
              ),
      );
      return false;
    } catch (e, st) {
      ErrorReporter.captureException(e, stackTrace: st);
      SentryMetricsService.authFailure('otp_send', 'unknown');
      state = state.copyWith(
        isLoading: false,
        errorMessage: _t(
          en: 'Could not send the verification code. Please try again.',
          sw: 'Imeshindwa kutuma msimbo wa uthibitisho. Tafadhali jaribu tena.',
        ),
      );
      return false;
    }
  }

  /// Verifies [code] against the pending Beem pinId. Sets
  /// [OnboardingState.otpVerified] on success.
  Future<bool> verifyOtp(String code) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final ok = await _service.verifyOtp(
        phone: state.phone,
        pinId: state.otpPinId,
        code: code,
      );
      if (ok) {
        state = state.copyWith(otpVerified: true, isLoading: false);
        return true;
      }
      state = state.copyWith(
        isLoading: false,
        errorMessage: _t(
          en: 'Incorrect code. Please try again.',
          sw: 'Msimbo si sahihi. Tafadhali jaribu tena.',
        ),
      );
      return false;
    } on FirebaseFunctionsException catch (e, st) {
      ErrorReporter.captureException(e, stackTrace: st);
      SentryMetricsService.authFailure('otp_verify', e.code);
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.code == 'resource-exhausted'
            ? _t(
                en: 'Too many attempts. Please request a new code and try again.',
                sw: 'Majaribio mengi. Omba msimbo mpya kisha ujaribu tena.',
              )
            : _t(
                en: 'Could not verify the code. Please try again.',
                sw: 'Imeshindwa kuthibitisha msimbo. Tafadhali jaribu tena.',
              ),
      );
      return false;
    } catch (e, st) {
      ErrorReporter.captureException(e, stackTrace: st);
      SentryMetricsService.authFailure('otp_verify', 'unknown');
      state = state.copyWith(
        isLoading: false,
        errorMessage: _t(
          en: 'Could not verify the code. Please try again.',
          sw: 'Imeshindwa kuthibitisha msimbo. Tafadhali jaribu tena.',
        ),
      );
      return false;
    }
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
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        unawaited(DeviceIntegrityService.checkAndLog(
          businessId: bizId,
          performedByUid: uid,
        ));
      }
      SentryMetricsService.authSuccess('new_owner_registration');
      state = state.copyWith(
        businessId: bizId,
        isLoading: false,
        isComplete: true,
        currentStep: OnboardingStep.success,
      );
    } on FirebaseFunctionsException catch (e, st) {
      ErrorReporter.captureException(e, stackTrace: st);
      SentryMetricsService.authFailure('new_owner_registration', e.code);
      state = state.copyWith(
        // Send them back to the OTP step rather than leaving otpVerified
        // true with no way to pass consumeOtpVerification again.
        otpVerified: e.code == 'failed-precondition' ? false : state.otpVerified,
        isLoading: false,
        errorMessage: e.code == 'failed-precondition'
            ? _t(
                en: 'Phone verification expired. Please verify your number again.',
                sw: 'Uthibitisho wa namba ya simu umeisha muda. Tafadhali thibitisha namba yako tena.',
              )
            : _accountCreationErrorMessage(e),
      );
    } on FirebaseAuthException catch (e, st) {
      ErrorReporter.captureException(e, stackTrace: st);
      SentryMetricsService.authFailure('new_owner_registration', e.code);
      state = state.copyWith(
        isLoading: false,
        errorMessage: _accountCreationErrorMessage(e),
      );
    } catch (e, st) {
      ErrorReporter.captureException(e, stackTrace: st);
      SentryMetricsService.authFailure('new_owner_registration', 'unknown');
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
    _service.clearDraft();
  }

  /// Resets session state but keeps the user at the phone-entry step so the
  /// router sends them to /phone instead of replaying language + intro.
  /// Use this on logout / account switch rather than [reset].
  void resetToPhoneEntry() {
    state = const OnboardingState(currentStep: OnboardingStep.phoneEntry);
    _service.clearDraft();
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
