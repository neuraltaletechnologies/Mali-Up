import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/onboarding_state.dart';
import '../../domain/models/pin_reset_result.dart';
import '../../domain/models/user_lookup_result.dart';
import '../../../rbac/data/audit_log_service.dart';
import '../repositories/onboarding_repository.dart';

// ─── PROVIDER ────────────────────────────────────────────────────────────────

final onboardingServiceProvider = Provider<OnboardingService>((ref) {
  return OnboardingService(
    repository: ref.read(onboardingRepositoryProvider),
  );
});

// ─── DRAFT ───────────────────────────────────────────────────────────────────

/// Persisted snapshot of a new user's partially-completed registration.
/// Restored on cold-start so the user can resume from where they left off.
class OnboardingDraft {
  const OnboardingDraft({
    required this.phone,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.city,
    required this.businessName,
    required this.businessType,
    required this.businessCountry,
    required this.businessRegion,
    required this.businessDistrict,
    required this.websiteUrl,
    required this.hasWebsite,
    required this.websiteInterest,
    required this.currentStep,
  });

  final String phone;
  final String firstName;
  final String lastName;
  final String email;
  final String city;
  final String businessName;
  final String businessType;
  final String businessCountry;
  final String businessRegion;
  final String businessDistrict;
  final String websiteUrl;
  final bool hasWebsite;
  final bool websiteInterest;
  final OnboardingStep currentStep;
}

// ─── SERVICE ──────────────────────────────────────────────────────────────────

/// Orchestrates the onboarding flow.
///
/// Authentication is PIN-based (phone → derive email+password). First-time
/// registration additionally requires Beem OTP phone verification (see
/// [sendOtp] / [verifyOtp]) before the account is created; returning-user
/// PIN login does not. All Firebase Auth and Firestore calls delegate to
/// [OnboardingRepository].
class OnboardingService {
  OnboardingService({required OnboardingRepository repository})
      : _repository = repository;

  final OnboardingRepository _repository;

  static const _completedKey = 'mali_onboarding_complete';

  // Draft keys — only written for new owners between personal-info and PIN steps.
  static const _draftPhone           = 'mali_ob_draft_phone';
  static const _draftFirstName       = 'mali_ob_draft_first_name';
  static const _draftLastName        = 'mali_ob_draft_last_name';
  static const _draftEmail           = 'mali_ob_draft_email';
  static const _draftCity            = 'mali_ob_draft_city';
  static const _draftBizName         = 'mali_ob_draft_biz_name';
  static const _draftBizType         = 'mali_ob_draft_biz_type';
  static const _draftBizCountry      = 'mali_ob_draft_biz_country';
  static const _draftBizRegion       = 'mali_ob_draft_biz_region';
  static const _draftBizDistrict     = 'mali_ob_draft_biz_district';
  static const _draftWebsiteUrl      = 'mali_ob_draft_website_url';
  static const _draftHasWebsite      = 'mali_ob_draft_has_website';
  static const _draftWebsiteInterest = 'mali_ob_draft_website_interest';
  static const _draftStep            = 'mali_ob_draft_step';

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
  /// [businessId] and [performedByName], when known from the preceding phone
  /// lookup, are used to record a best-effort `user_signed_in` activity entry
  /// — skipped silently if [businessId] is empty (e.g. unresolved for a
  /// returning team member).
  ///
  /// Throws [FirebaseAuthException] on wrong PIN — notifier shows error.
  Future<void> loginWithPin({
    required String phone,
    required String pin,
    required String userId,
    String businessId = '',
    String performedByName = '',
  }) async {
    await _repository.loginWithPin(phone: phone, pin: pin);
    await Future.wait([
      _repository.touchLastActive(userId),
      // Owner picked this business on the PIN screen (or it's their only one)
      // — make the dashboard open it rather than whatever was last active.
      _repository.setSelectedBusiness(userId, businessId),
      completeOnboarding(),
      AuditLogService().logSignIn(
        businessId: businessId,
        performedByUid: userId,
        performedByName: performedByName,
      ),
    ]);
  }

  // ─── OTP VERIFICATION (first-time registration only) ─────────────────────

  /// Requests a Beem OTP be sent to [phone]. Returns the pinId to pass to
  /// [verifyOtp].
  Future<String> sendOtp({required String phone}) {
    return _repository.sendOtp(phone);
  }

  /// Verifies [code] against [pinId] for [phone].
  Future<bool> verifyOtp({
    required String phone,
    required String pinId,
    required String code,
  }) {
    return _repository.verifyOtp(phone: phone, pinId: pinId, code: code);
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
    String email = '',
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
      realEmail: email,
    );
    await completeOnboarding();
  }

  // ─── PIN RECOVERY ─────────────────────────────────────────────────────────

  /// Step 1 — emails a recovery magic link to the address on file.
  Future<PinResetRequestResult> requestPinReset({
    required String phone,
    required String language,
  }) {
    return _repository.requestPinReset(phone: phone, language: language);
  }

  /// Step 2 — validates a token from the magic link.
  Future<PinResetTokenInfo> validatePinResetToken(String token) {
    return _repository.validatePinResetToken(token);
  }

  /// Step 3 — sets the new PIN-derived password. [phone] must be the canonical
  /// value from [validatePinResetToken].
  Future<PinResetConfirmResult> confirmPinReset({
    required String token,
    required String phone,
    required String newPin,
  }) {
    return _repository.confirmPinReset(
      token: token,
      phone: phone,
      newPin: newPin,
    );
  }

  // ─── SCREEN 6 — NEW OWNER ACCOUNT CREATION ───────────────────────────────

  /// Creates a Firebase Auth account (email = phone@mali.up, password derived
  /// from PIN), writes user + business profiles to Firestore, marks complete.
  /// Returns the auto-generated business document ID.
  ///
  /// Guard: if the Firebase Auth email already existed AND the user document
  /// already exists in Firestore, we skip all writes and just complete
  /// onboarding — preventing duplicate business documents and profile overwrites
  /// for returning users who accidentally re-entered the registration flow.
  Future<String> saveAndCompleteNewUser(OnboardingState state) async {
    final uid = await _repository.createNewUserAccount(
      phone: state.phone,
      pin: state.pin,
    );

    // Check whether this uid already has a fully-set-up Firestore profile.
    final existingBizId = await _repository.getExistingBusinessId(uid);
    if (existingBizId != null) {
      if (kDebugMode) {
        debugPrint(
          '[OnboardingService] returning user re-entered new-user flow — '
          'skipping writes, completing onboarding. uid=$uid biz=$existingBizId',
        );
      }
      await Future.wait([completeOnboarding(), clearDraft()]);
      return existingBizId;
    }

    try {
      final bizId = await _repository.saveBusinessProfile(
        userId: uid,
        state: state,
      );
      await _repository.saveUser(userId: uid, state: state, businessId: bizId);
      await Future.wait([completeOnboarding(), clearDraft()]);
      if (kDebugMode) debugPrint('[OnboardingService] new user saved uid=$uid');
      return bizId;
    } catch (e) {
      await _repository.deleteCurrentAuthUser();
      if (kDebugMode) {
        debugPrint('[OnboardingService] rolling back new user uid=$uid: $e');
      }
      rethrow;
    }
  }

  // ─── DRAFT PERSISTENCE ───────────────────────────────────────────────────

  /// Loads a previously-saved new-user draft from [prefs].
  /// Called in main.dart before runApp so the result can be seeded into
  /// [onboardingDraftBootstrapProvider] synchronously.
  /// Returns null if no in-progress registration draft exists.
  static OnboardingDraft? loadDraft(SharedPreferences prefs) {
    final stepName = prefs.getString(_draftStep);
    if (stepName == null) return null;
    final step = OnboardingStep.values.where((s) => s.name == stepName).firstOrNull;
    if (step == null) return null;
    return OnboardingDraft(
      phone:           prefs.getString(_draftPhone)     ?? '',
      firstName:       prefs.getString(_draftFirstName) ?? '',
      lastName:        prefs.getString(_draftLastName)  ?? '',
      email:           prefs.getString(_draftEmail)     ?? '',
      city:            prefs.getString(_draftCity)      ?? '',
      businessName:    prefs.getString(_draftBizName)   ?? '',
      businessType:    prefs.getString(_draftBizType)   ?? '',
      businessCountry: prefs.getString(_draftBizCountry) ?? 'TZ',
      businessRegion:  prefs.getString(_draftBizRegion)   ?? '',
      businessDistrict:prefs.getString(_draftBizDistrict) ?? '',
      websiteUrl:      prefs.getString(_draftWebsiteUrl)  ?? '',
      hasWebsite:      prefs.getBool(_draftHasWebsite)    ?? false,
      websiteInterest: prefs.getBool(_draftWebsiteInterest) ?? false,
      currentStep:     step,
    );
  }

  /// Persists the in-progress new-user draft.  Fire-and-forget from the notifier.
  Future<void> saveDraft(OnboardingState state) async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setString(_draftPhone,           state.phone),
      prefs.setString(_draftFirstName,       state.firstName),
      prefs.setString(_draftLastName,        state.lastName),
      prefs.setString(_draftEmail,           state.email),
      prefs.setString(_draftCity,            state.city),
      prefs.setString(_draftBizName,         state.businessName),
      prefs.setString(_draftBizType,         state.businessType),
      prefs.setString(_draftBizCountry,      state.businessCountry),
      prefs.setString(_draftBizRegion,       state.businessRegion),
      prefs.setString(_draftBizDistrict,     state.businessDistrict),
      prefs.setString(_draftWebsiteUrl,      state.websiteUrl),
      prefs.setBool(_draftHasWebsite,        state.hasWebsite),
      prefs.setBool(_draftWebsiteInterest,   state.websiteInterest),
      prefs.setString(_draftStep,            state.currentStep.name),
    ]);
  }

  /// Removes the draft — called when registration succeeds or is reset.
  Future<void> clearDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.remove(_draftPhone),
      prefs.remove(_draftFirstName),
      prefs.remove(_draftLastName),
      prefs.remove(_draftEmail),
      prefs.remove(_draftCity),
      prefs.remove(_draftBizName),
      prefs.remove(_draftBizType),
      prefs.remove(_draftBizCountry),
      prefs.remove(_draftBizRegion),
      prefs.remove(_draftBizDistrict),
      prefs.remove(_draftWebsiteUrl),
      prefs.remove(_draftHasWebsite),
      prefs.remove(_draftWebsiteInterest),
      prefs.remove(_draftStep),
    ]);
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
    await clearDraft();
  }
}
