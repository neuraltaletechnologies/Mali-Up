/// Result of a Firestore phone-number lookup performed after OTP verification.
///
/// Use a `switch` or pattern-match on the sealed class to branch the router:
/// ```dart
/// switch (result) {
///   ReturningUser r => // go to /returning, populate state from r
///   NewUser()      => // go to /new-user
/// }
/// ```
sealed class UserLookupResult {
  const UserLookupResult();
}

/// The phone number maps to an existing user + business document.
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

  @override
  String toString() =>
      'ReturningUser(userId: $userId, name: $name, businessName: $businessName)';
}

/// No document exists for this phone — the user is registering for the first time.
final class NewUser extends UserLookupResult {
  const NewUser();

  @override
  String toString() => 'NewUser()';
}
