// Immutable state for the onboarding flow.
//
// Written as a hand-rolled copyWith class so it compiles without build_runner.

import 'package:flutter/foundation.dart';

import '../../../../core/services/localization_service.dart';
import 'user_lookup_result.dart';

// ─── STEP ENUM ────────────────────────────────────────────────────────────────

/// Each value maps to one screen in the onboarding flow.
/// The [stepIndex] drives the GoRouter redirect guard — a user cannot jump
/// ahead of the step they have legitimately reached.
enum OnboardingStep {
  welcome(0),          // Screen 1 — language picker
  intro(1),            // Screen 2 — app intro slides
  phoneEntry(2),       // Screen 3 — phone number entry + lookup
  pinLogin(3),         // Screen 4A — existing user PIN login
  teamMemberSetup(3),  // Screen 4B — team member first-time PIN setup
  newUserInfo(3),      // Screen 4C — new user personal info
  businessDetails(4),  // Screen 5 — business details
  pinSetup(5),         // Screen 6 — set + confirm 4-digit PIN
  success(6);          // Screen 7 — success + dashboard entry

  const OnboardingStep(this.stepIndex);

  /// Minimum completed-step count needed to reach this screen.
  final int stepIndex;
}

// ─── STATE ────────────────────────────────────────────────────────────────────

class OnboardingState {
  const OnboardingState({
    // Screen 1 — Language
    this.currentStep = OnboardingStep.welcome,
    this.language = AppLanguage.english,

    // Screen 3 — Phone
    this.phone = '',

    // Screen 4A — Existing user PIN login
    this.isReturningUser = false,
    this.existingUserId = '',

    // Screen 4B — Team member setup
    this.isTeamMember = false,
    this.teamMemberId = '',
    this.teamOwnerUid = '',
    this.inviteId = '',
    this.memberEmail = '',

    // Screen 4A/4B/4C — user profile
    this.firstName = '',
    this.lastName = '',
    this.city = '',
    this.role = '',
    this.businessName = '',
    this.businessType = '',
    this.businessLogo = '',
    this.businessId = '',
    this.ownedBusinesses = const [],
    this.businessCountry = 'TZ',
    this.businessRegion = '',
    this.businessDistrict = '',
    this.email = '',
    this.websiteUrl = '',
    this.hasWebsite = false,
    this.websiteInterest = false,

    // Screen 6 — PIN setup
    this.pin = '',
    this.confirmPin = '',

    // Async / UI
    this.isLoading = false,
    this.errorMessage,

    // Flow completion
    this.isComplete = false,
  });

  // ── Screen 1 ──────────────────────────────────────────────────────────────
  final OnboardingStep currentStep;
  final AppLanguage language;

  // ── Screen 3 ──────────────────────────────────────────────────────────────
  final String phone;

  // ── Screen 4A — existing user ─────────────────────────────────────────────
  final bool isReturningUser;
  final String existingUserId;

  // ── Screen 4B — team member ───────────────────────────────────────────────
  final bool isTeamMember;

  /// Firestore document ID in the `team_members` subcollection.
  final String teamMemberId;

  /// UID of the business owner who added this team member.
  final String teamOwnerUid;

  /// Document ID in the top-level `pendingInvites` collection (empty if found
  /// via legacy `team_members` collectionGroup).
  final String inviteId;

  /// Email stored on the invite — used in PIN recovery flow.
  final String memberEmail;

  // ── Profile fields (populated by lookup or entered by new user) ───────────
  final String firstName;
  final String lastName;
  final String city;
  final String role;

  // ── Screen 5 ──────────────────────────────────────────────────────────────
  final String businessName;
  final String businessType;
  final String businessLogo;
  final String businessId;

  /// Businesses owned by a returning user (from the phone lookup). When this
  /// has more than one entry the PIN screen shows a picker; [businessId] holds
  /// the currently-selected one.
  final List<BusinessSummary> ownedBusinesses;

  final String businessCountry;  // ISO-2 code, default 'TZ'
  final String businessRegion;
  final String businessDistrict;
  final String email;
  final String websiteUrl;
  final bool hasWebsite;
  final bool websiteInterest;

  // ── Screen 6 ──────────────────────────────────────────────────────────────
  final String pin;
  final String confirmPin;

  // ── Async / UI ────────────────────────────────────────────────────────────
  final bool isLoading;
  final String? errorMessage;

  // ── Flow state ────────────────────────────────────────────────────────────
  final bool isComplete;

  // ─── DERIVED ──────────────────────────────────────────────────────────────

  bool get isSwahili => language == AppLanguage.swahili;

  String get fullName => '${firstName.trim()} ${lastName.trim()}'.trim();

  /// Progress fraction 0.0–1.0 for linear progress indicators (capped at step 5).
  double get progressFraction =>
      (currentStep.stepIndex.clamp(0, 5) / 5.0);

  /// "Step 2 of 6" — used in screen headers.
  String get stepLabel =>
      'Step ${(currentStep.stepIndex + 1).clamp(1, 6)} of 6';

  // ─── copyWith ─────────────────────────────────────────────────────────────

  OnboardingState copyWith({
    OnboardingStep? currentStep,
    AppLanguage? language,
    String? phone,
    bool? isReturningUser,
    String? existingUserId,
    bool? isTeamMember,
    String? teamMemberId,
    String? teamOwnerUid,
    String? inviteId,
    String? memberEmail,
    String? firstName,
    String? lastName,
    String? city,
    String? role,
    String? businessName,
    String? businessType,
    String? businessLogo,
    String? businessId,
    List<BusinessSummary>? ownedBusinesses,
    String? businessCountry,
    String? businessRegion,
    String? businessDistrict,
    String? email,
    String? websiteUrl,
    bool? hasWebsite,
    bool? websiteInterest,
    String? pin,
    String? confirmPin,
    bool? isLoading,
    // Use clearError: true to set errorMessage to null.
    String? errorMessage,
    bool clearError = false,
    bool? isComplete,
  }) {
    return OnboardingState(
      currentStep: currentStep ?? this.currentStep,
      language: language ?? this.language,
      phone: phone ?? this.phone,
      isReturningUser: isReturningUser ?? this.isReturningUser,
      existingUserId: existingUserId ?? this.existingUserId,
      isTeamMember: isTeamMember ?? this.isTeamMember,
      teamMemberId: teamMemberId ?? this.teamMemberId,
      teamOwnerUid: teamOwnerUid ?? this.teamOwnerUid,
      inviteId: inviteId ?? this.inviteId,
      memberEmail: memberEmail ?? this.memberEmail,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      city: city ?? this.city,
      role: role ?? this.role,
      businessName: businessName ?? this.businessName,
      businessType: businessType ?? this.businessType,
      businessLogo: businessLogo ?? this.businessLogo,
      businessId: businessId ?? this.businessId,
      ownedBusinesses: ownedBusinesses ?? this.ownedBusinesses,
      businessCountry: businessCountry ?? this.businessCountry,
      businessRegion: businessRegion ?? this.businessRegion,
      businessDistrict: businessDistrict ?? this.businessDistrict,
      email: email ?? this.email,
      websiteUrl: websiteUrl ?? this.websiteUrl,
      hasWebsite: hasWebsite ?? this.hasWebsite,
      websiteInterest: websiteInterest ?? this.websiteInterest,
      pin: pin ?? this.pin,
      confirmPin: confirmPin ?? this.confirmPin,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isComplete: isComplete ?? this.isComplete,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OnboardingState &&
        other.currentStep == currentStep &&
        other.language == language &&
        other.phone == phone &&
        other.isReturningUser == isReturningUser &&
        other.existingUserId == existingUserId &&
        other.isTeamMember == isTeamMember &&
        other.teamMemberId == teamMemberId &&
        other.teamOwnerUid == teamOwnerUid &&
        other.inviteId == inviteId &&
        other.memberEmail == memberEmail &&
        other.firstName == firstName &&
        other.lastName == lastName &&
        other.city == city &&
        other.role == role &&
        other.businessName == businessName &&
        other.businessType == businessType &&
        other.businessLogo == businessLogo &&
        other.businessId == businessId &&
        listEquals(other.ownedBusinesses, ownedBusinesses) &&
        other.businessCountry == businessCountry &&
        other.businessRegion == businessRegion &&
        other.businessDistrict == businessDistrict &&
        other.email == email &&
        other.websiteUrl == websiteUrl &&
        other.hasWebsite == hasWebsite &&
        other.websiteInterest == websiteInterest &&
        other.pin == pin &&
        other.confirmPin == confirmPin &&
        other.isLoading == isLoading &&
        other.errorMessage == errorMessage &&
        other.isComplete == isComplete;
  }

  @override
  int get hashCode => Object.hashAll([
        currentStep, language, phone,
        isReturningUser, existingUserId,
        isTeamMember, teamMemberId, teamOwnerUid, inviteId, memberEmail,
        firstName, lastName, city, role,
        businessName, businessType, businessLogo, businessId,
        Object.hashAll(ownedBusinesses),
        businessCountry, businessRegion, businessDistrict, email,
        websiteUrl, hasWebsite, websiteInterest,
        pin, confirmPin, isLoading, errorMessage, isComplete,
      ]);
}
