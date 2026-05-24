import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_lookup_result.freezed.dart';

/// Sealed class representing result of phone number lookup
@freezed
abstract class UserLookupResult with _$UserLookupResult {
  /// User found in system - returning user
  const factory UserLookupResult.returningUser({
    required String userId,
    required String firstName,
    required String lastName,
    required String businessId,
    required String businessName,
    required String businessType,
    required String city,
    required String? businessLogo,
  }) = ReturningUser;

  /// User not found - new user path
  const factory UserLookupResult.newUser() = NewUser;
}
