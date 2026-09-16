/// Result of a Firestore phone-number lookup performed during onboarding.
///
/// Use a `switch` or pattern-match to branch the router:
/// ```dart
/// switch (result) {
///   ReturningUser r  => // go to /pin-login, show PIN entry
///   TeamMemberPending t => // go to /team-setup, show profile + set PIN
///   NewUser()        => // go to /new-user, collect personal + business info
/// }
/// ```
sealed class UserLookupResult {
  const UserLookupResult();
}

/// One business owned by a [ReturningUser]. Used to render the business
/// picker on the PIN login screen when an owner has more than one.
final class BusinessSummary {
  const BusinessSummary({
    required this.id,
    required this.name,
    this.type = '',
    this.logoUrl,
    this.plan = '',
    this.planExpiresAt,
  });

  /// Firestore document ID in the `businesses` collection.
  final String id;
  final String name;
  final String type;

  /// Logo URL — null/empty falls back to an initials avatar.
  final String? logoUrl;

  /// Raw `plan` string from the `businesses` doc (e.g. `growth`, `business`,
  /// or `''`/`Trial` for a starter). The PIN screen resolves it to a tier
  /// label; an expired paid plan (see [planExpiresAt]) is shown as free.
  final String plan;

  /// `planExpiresAt` from the `businesses` doc, if set — a paid [plan] whose
  /// expiry is in the past has effectively reverted to the free tier.
  final DateTime? planExpiresAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BusinessSummary &&
          other.id == id &&
          other.name == name &&
          other.type == type &&
          other.logoUrl == logoUrl &&
          other.plan == plan &&
          other.planExpiresAt == planExpiresAt);

  @override
  int get hashCode => Object.hash(id, name, type, logoUrl, plan, planExpiresAt);
}

/// The phone number maps to an existing user document in the `users` collection.
/// This user already has a Firebase Auth account and a PIN.
/// Both business owners and previously-activated team members fall here.
final class ReturningUser extends UserLookupResult {
  const ReturningUser({
    required this.userId,
    required this.name,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.city,
    required this.role,
    required this.businessName,
    required this.businessType,
    required this.businessId,
    this.businessLogo,
    this.businesses = const [],
    this.phoneVerified = false,
  });

  /// Firestore document ID in the `users` collection.
  final String userId;

  /// Full name as stored in the `name` field ("Amina Njoroge").
  final String name;
  final String firstName;
  final String lastName;

  /// E.164 phone number (+255XXXXXXXXX).
  final String phone;

  final String city;
  final String role;

  // Business info — may be empty strings if the user has no business doc yet.
  final String businessName;
  final String businessType;

  /// Firestore document ID in the `businesses` collection. Empty if no biz.
  final String businessId;

  /// Business logo URL — null/empty falls back to an initials avatar.
  final String? businessLogo;

  /// Every business this user owns (`ownerUid == userId`), newest-relevant
  /// first. Contains a single entry (matching the `business*` fields above)
  /// for the common one-business case; the PIN screen shows a picker when
  /// there is more than one. Empty when the user owns no business doc.
  final List<BusinessSummary> businesses;

  /// Whether this account already Beem-verified its phone. False (missing
  /// field) for any account created before the OTP rollout — PinLoginScreen
  /// shows the OTP step (before PIN entry) once, then never asks again.
  final bool phoneVerified;

  @override
  String toString() =>
      'ReturningUser(userId: $userId, name: $name, businessName: $businessName)';
}

/// The phone number matches a team member added by an owner, but this member
/// has NOT yet set up their own account (no entry in the top-level `users`
/// collection, no Firebase Auth account, no PIN).
/// First time they sign in they see their profile and set a PIN.
final class TeamMemberPending extends UserLookupResult {
  const TeamMemberPending({
    required this.memberId,
    required this.name,
    required this.role,
    required this.businessName,
    required this.ownerUid,
    required this.businessId,
    this.inviteId = '',
    this.email = '',
  });

  /// Firestore document ID in the `team_members` subcollection.
  final String memberId;

  /// Name as entered by the owner when adding this team member.
  final String name;

  /// Role string (e.g. 'manager', 'cashier') — see [TeamRole].
  final String role;

  /// Business name owned by the owner who added this member.
  final String businessName;

  /// UID of the owner — needed to activate the member's record.
  final String ownerUid;

  /// Business document ID under the owner's tenant — needed to update status.
  final String businessId;

  /// Document ID in the top-level `pendingInvites` collection.
  /// Empty string when found via legacy `team_members` collectionGroup.
  final String inviteId;

  /// Email on file for this invite — used in PIN recovery flow.
  final String email;

  @override
  String toString() =>
      'TeamMemberPending(memberId: $memberId, name: $name, role: $role, inviteId: $inviteId)';
}

/// No document exists for this phone — the user is registering for the first time.
final class NewUser extends UserLookupResult {
  const NewUser();

  @override
  String toString() => 'NewUser()';
}
