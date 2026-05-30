// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'onboarding_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$OnboardingState {

/// Language selection: 'en' or 'sw'
 String get language;/// Current screen step (1-7)
 int get currentStep;/// Phone number (without country code, e.g., "756123456")
 String get phone;/// First name of user
 String get firstName;/// Last name of user
 String get lastName;/// Business name
 String get businessName;/// Business type (e.g., "Retail", "Services", "Manufacturing")
 String get businessType;/// Password (min 8 chars, at least 1 number)
 String get password;/// 4-digit PIN
 String get pin;/// Is returning user (determined after phone lookup)
 bool get isReturningUser;/// Business details for returning users
 BusinessInfo? get businessInfo;/// OTP code entered by user
 String get otpCode;/// Number of OTP verification attempts
 int get otpAttempts;/// Whether user is in OTP cooldown period (after failed attempts)
 bool get otpInCooldown;/// Cooldown end timestamp (milliseconds since epoch)
 int get otpCooldownEndTime;/// OTP expiry timestamp (milliseconds since epoch)
 int get otpExpiryTime;/// Error message for OTP
 String get otpErrorMessage;/// User lookup result (populated after phone verification)
 UserLookupResult? get userLookupResult;/// General error message
 String get errorMessage;
/// Create a copy of OnboardingState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OnboardingStateCopyWith<OnboardingState> get copyWith => _$OnboardingStateCopyWithImpl<OnboardingState>(this as OnboardingState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OnboardingState&&(identical(other.language, language) || other.language == language)&&(identical(other.currentStep, currentStep) || other.currentStep == currentStep)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.firstName, firstName) || other.firstName == firstName)&&(identical(other.lastName, lastName) || other.lastName == lastName)&&(identical(other.businessName, businessName) || other.businessName == businessName)&&(identical(other.businessType, businessType) || other.businessType == businessType)&&(identical(other.password, password) || other.password == password)&&(identical(other.pin, pin) || other.pin == pin)&&(identical(other.isReturningUser, isReturningUser) || other.isReturningUser == isReturningUser)&&(identical(other.businessInfo, businessInfo) || other.businessInfo == businessInfo)&&(identical(other.otpCode, otpCode) || other.otpCode == otpCode)&&(identical(other.otpAttempts, otpAttempts) || other.otpAttempts == otpAttempts)&&(identical(other.otpInCooldown, otpInCooldown) || other.otpInCooldown == otpInCooldown)&&(identical(other.otpCooldownEndTime, otpCooldownEndTime) || other.otpCooldownEndTime == otpCooldownEndTime)&&(identical(other.otpExpiryTime, otpExpiryTime) || other.otpExpiryTime == otpExpiryTime)&&(identical(other.otpErrorMessage, otpErrorMessage) || other.otpErrorMessage == otpErrorMessage)&&(identical(other.userLookupResult, userLookupResult) || other.userLookupResult == userLookupResult)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage));
}


@override
int get hashCode => Object.hashAll([runtimeType,language,currentStep,phone,firstName,lastName,businessName,businessType,password,pin,isReturningUser,businessInfo,otpCode,otpAttempts,otpInCooldown,otpCooldownEndTime,otpExpiryTime,otpErrorMessage,userLookupResult,errorMessage]);

@override
String toString() {
  return 'OnboardingState(language: $language, currentStep: $currentStep, phone: $phone, firstName: $firstName, lastName: $lastName, businessName: $businessName, businessType: $businessType, password: $password, pin: $pin, isReturningUser: $isReturningUser, businessInfo: $businessInfo, otpCode: $otpCode, otpAttempts: $otpAttempts, otpInCooldown: $otpInCooldown, otpCooldownEndTime: $otpCooldownEndTime, otpExpiryTime: $otpExpiryTime, otpErrorMessage: $otpErrorMessage, userLookupResult: $userLookupResult, errorMessage: $errorMessage)';
}


}

/// @nodoc
abstract mixin class $OnboardingStateCopyWith<$Res>  {
  factory $OnboardingStateCopyWith(OnboardingState value, $Res Function(OnboardingState) _then) = _$OnboardingStateCopyWithImpl;
@useResult
$Res call({
 String language, int currentStep, String phone, String firstName, String lastName, String businessName, String businessType, String password, String pin, bool isReturningUser, BusinessInfo? businessInfo, String otpCode, int otpAttempts, bool otpInCooldown, int otpCooldownEndTime, int otpExpiryTime, String otpErrorMessage, UserLookupResult? userLookupResult, String errorMessage
});


$BusinessInfoCopyWith<$Res>? get businessInfo;$UserLookupResultCopyWith<$Res>? get userLookupResult;

}
/// @nodoc
class _$OnboardingStateCopyWithImpl<$Res>
    implements $OnboardingStateCopyWith<$Res> {
  _$OnboardingStateCopyWithImpl(this._self, this._then);

  final OnboardingState _self;
  final $Res Function(OnboardingState) _then;

/// Create a copy of OnboardingState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? language = null,Object? currentStep = null,Object? phone = null,Object? firstName = null,Object? lastName = null,Object? businessName = null,Object? businessType = null,Object? password = null,Object? pin = null,Object? isReturningUser = null,Object? businessInfo = freezed,Object? otpCode = null,Object? otpAttempts = null,Object? otpInCooldown = null,Object? otpCooldownEndTime = null,Object? otpExpiryTime = null,Object? otpErrorMessage = null,Object? userLookupResult = freezed,Object? errorMessage = null,}) {
  return _then(_self.copyWith(
language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,currentStep: null == currentStep ? _self.currentStep : currentStep // ignore: cast_nullable_to_non_nullable
as int,phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,firstName: null == firstName ? _self.firstName : firstName // ignore: cast_nullable_to_non_nullable
as String,lastName: null == lastName ? _self.lastName : lastName // ignore: cast_nullable_to_non_nullable
as String,businessName: null == businessName ? _self.businessName : businessName // ignore: cast_nullable_to_non_nullable
as String,businessType: null == businessType ? _self.businessType : businessType // ignore: cast_nullable_to_non_nullable
as String,password: null == password ? _self.password : password // ignore: cast_nullable_to_non_nullable
as String,pin: null == pin ? _self.pin : pin // ignore: cast_nullable_to_non_nullable
as String,isReturningUser: null == isReturningUser ? _self.isReturningUser : isReturningUser // ignore: cast_nullable_to_non_nullable
as bool,businessInfo: freezed == businessInfo ? _self.businessInfo : businessInfo // ignore: cast_nullable_to_non_nullable
as BusinessInfo?,otpCode: null == otpCode ? _self.otpCode : otpCode // ignore: cast_nullable_to_non_nullable
as String,otpAttempts: null == otpAttempts ? _self.otpAttempts : otpAttempts // ignore: cast_nullable_to_non_nullable
as int,otpInCooldown: null == otpInCooldown ? _self.otpInCooldown : otpInCooldown // ignore: cast_nullable_to_non_nullable
as bool,otpCooldownEndTime: null == otpCooldownEndTime ? _self.otpCooldownEndTime : otpCooldownEndTime // ignore: cast_nullable_to_non_nullable
as int,otpExpiryTime: null == otpExpiryTime ? _self.otpExpiryTime : otpExpiryTime // ignore: cast_nullable_to_non_nullable
as int,otpErrorMessage: null == otpErrorMessage ? _self.otpErrorMessage : otpErrorMessage // ignore: cast_nullable_to_non_nullable
as String,userLookupResult: freezed == userLookupResult ? _self.userLookupResult : userLookupResult // ignore: cast_nullable_to_non_nullable
as UserLookupResult?,errorMessage: null == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String,
  ));
}
/// Create a copy of OnboardingState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BusinessInfoCopyWith<$Res>? get businessInfo {
    if (_self.businessInfo == null) {
    return null;
  }

  return $BusinessInfoCopyWith<$Res>(_self.businessInfo!, (value) {
    return _then(_self.copyWith(businessInfo: value));
  });
}/// Create a copy of OnboardingState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UserLookupResultCopyWith<$Res>? get userLookupResult {
    if (_self.userLookupResult == null) {
    return null;
  }

  return $UserLookupResultCopyWith<$Res>(_self.userLookupResult!, (value) {
    return _then(_self.copyWith(userLookupResult: value));
  });
}
}


/// Adds pattern-matching-related methods to [OnboardingState].
extension OnboardingStatePatterns on OnboardingState {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OnboardingState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OnboardingState() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OnboardingState value)  $default,){
final _that = this;
switch (_that) {
case _OnboardingState():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OnboardingState value)?  $default,){
final _that = this;
switch (_that) {
case _OnboardingState() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String language,  int currentStep,  String phone,  String firstName,  String lastName,  String businessName,  String businessType,  String password,  String pin,  bool isReturningUser,  BusinessInfo? businessInfo,  String otpCode,  int otpAttempts,  bool otpInCooldown,  int otpCooldownEndTime,  int otpExpiryTime,  String otpErrorMessage,  UserLookupResult? userLookupResult,  String errorMessage)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OnboardingState() when $default != null:
return $default(_that.language,_that.currentStep,_that.phone,_that.firstName,_that.lastName,_that.businessName,_that.businessType,_that.password,_that.pin,_that.isReturningUser,_that.businessInfo,_that.otpCode,_that.otpAttempts,_that.otpInCooldown,_that.otpCooldownEndTime,_that.otpExpiryTime,_that.otpErrorMessage,_that.userLookupResult,_that.errorMessage);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String language,  int currentStep,  String phone,  String firstName,  String lastName,  String businessName,  String businessType,  String password,  String pin,  bool isReturningUser,  BusinessInfo? businessInfo,  String otpCode,  int otpAttempts,  bool otpInCooldown,  int otpCooldownEndTime,  int otpExpiryTime,  String otpErrorMessage,  UserLookupResult? userLookupResult,  String errorMessage)  $default,) {final _that = this;
switch (_that) {
case _OnboardingState():
return $default(_that.language,_that.currentStep,_that.phone,_that.firstName,_that.lastName,_that.businessName,_that.businessType,_that.password,_that.pin,_that.isReturningUser,_that.businessInfo,_that.otpCode,_that.otpAttempts,_that.otpInCooldown,_that.otpCooldownEndTime,_that.otpExpiryTime,_that.otpErrorMessage,_that.userLookupResult,_that.errorMessage);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String language,  int currentStep,  String phone,  String firstName,  String lastName,  String businessName,  String businessType,  String password,  String pin,  bool isReturningUser,  BusinessInfo? businessInfo,  String otpCode,  int otpAttempts,  bool otpInCooldown,  int otpCooldownEndTime,  int otpExpiryTime,  String otpErrorMessage,  UserLookupResult? userLookupResult,  String errorMessage)?  $default,) {final _that = this;
switch (_that) {
case _OnboardingState() when $default != null:
return $default(_that.language,_that.currentStep,_that.phone,_that.firstName,_that.lastName,_that.businessName,_that.businessType,_that.password,_that.pin,_that.isReturningUser,_that.businessInfo,_that.otpCode,_that.otpAttempts,_that.otpInCooldown,_that.otpCooldownEndTime,_that.otpExpiryTime,_that.otpErrorMessage,_that.userLookupResult,_that.errorMessage);case _:
  return null;

}
}

}

/// @nodoc


class _OnboardingState extends OnboardingState {
  const _OnboardingState({required this.language, required this.currentStep, required this.phone, required this.firstName, required this.lastName, required this.businessName, required this.businessType, required this.password, required this.pin, required this.isReturningUser, required this.businessInfo, required this.otpCode, required this.otpAttempts, required this.otpInCooldown, required this.otpCooldownEndTime, required this.otpExpiryTime, required this.otpErrorMessage, required this.userLookupResult, required this.errorMessage}): super._();
  

/// Language selection: 'en' or 'sw'
@override final  String language;
/// Current screen step (1-7)
@override final  int currentStep;
/// Phone number (without country code, e.g., "756123456")
@override final  String phone;
/// First name of user
@override final  String firstName;
/// Last name of user
@override final  String lastName;
/// Business name
@override final  String businessName;
/// Business type (e.g., "Retail", "Services", "Manufacturing")
@override final  String businessType;
/// Password (min 8 chars, at least 1 number)
@override final  String password;
/// 4-digit PIN
@override final  String pin;
/// Is returning user (determined after phone lookup)
@override final  bool isReturningUser;
/// Business details for returning users
@override final  BusinessInfo? businessInfo;
/// OTP code entered by user
@override final  String otpCode;
/// Number of OTP verification attempts
@override final  int otpAttempts;
/// Whether user is in OTP cooldown period (after failed attempts)
@override final  bool otpInCooldown;
/// Cooldown end timestamp (milliseconds since epoch)
@override final  int otpCooldownEndTime;
/// OTP expiry timestamp (milliseconds since epoch)
@override final  int otpExpiryTime;
/// Error message for OTP
@override final  String otpErrorMessage;
/// User lookup result (populated after phone verification)
@override final  UserLookupResult? userLookupResult;
/// General error message
@override final  String errorMessage;

/// Create a copy of OnboardingState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OnboardingStateCopyWith<_OnboardingState> get copyWith => __$OnboardingStateCopyWithImpl<_OnboardingState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OnboardingState&&(identical(other.language, language) || other.language == language)&&(identical(other.currentStep, currentStep) || other.currentStep == currentStep)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.firstName, firstName) || other.firstName == firstName)&&(identical(other.lastName, lastName) || other.lastName == lastName)&&(identical(other.businessName, businessName) || other.businessName == businessName)&&(identical(other.businessType, businessType) || other.businessType == businessType)&&(identical(other.password, password) || other.password == password)&&(identical(other.pin, pin) || other.pin == pin)&&(identical(other.isReturningUser, isReturningUser) || other.isReturningUser == isReturningUser)&&(identical(other.businessInfo, businessInfo) || other.businessInfo == businessInfo)&&(identical(other.otpCode, otpCode) || other.otpCode == otpCode)&&(identical(other.otpAttempts, otpAttempts) || other.otpAttempts == otpAttempts)&&(identical(other.otpInCooldown, otpInCooldown) || other.otpInCooldown == otpInCooldown)&&(identical(other.otpCooldownEndTime, otpCooldownEndTime) || other.otpCooldownEndTime == otpCooldownEndTime)&&(identical(other.otpExpiryTime, otpExpiryTime) || other.otpExpiryTime == otpExpiryTime)&&(identical(other.otpErrorMessage, otpErrorMessage) || other.otpErrorMessage == otpErrorMessage)&&(identical(other.userLookupResult, userLookupResult) || other.userLookupResult == userLookupResult)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage));
}


@override
int get hashCode => Object.hashAll([runtimeType,language,currentStep,phone,firstName,lastName,businessName,businessType,password,pin,isReturningUser,businessInfo,otpCode,otpAttempts,otpInCooldown,otpCooldownEndTime,otpExpiryTime,otpErrorMessage,userLookupResult,errorMessage]);

@override
String toString() {
  return 'OnboardingState(language: $language, currentStep: $currentStep, phone: $phone, firstName: $firstName, lastName: $lastName, businessName: $businessName, businessType: $businessType, password: $password, pin: $pin, isReturningUser: $isReturningUser, businessInfo: $businessInfo, otpCode: $otpCode, otpAttempts: $otpAttempts, otpInCooldown: $otpInCooldown, otpCooldownEndTime: $otpCooldownEndTime, otpExpiryTime: $otpExpiryTime, otpErrorMessage: $otpErrorMessage, userLookupResult: $userLookupResult, errorMessage: $errorMessage)';
}


}

/// @nodoc
abstract mixin class _$OnboardingStateCopyWith<$Res> implements $OnboardingStateCopyWith<$Res> {
  factory _$OnboardingStateCopyWith(_OnboardingState value, $Res Function(_OnboardingState) _then) = __$OnboardingStateCopyWithImpl;
@override @useResult
$Res call({
 String language, int currentStep, String phone, String firstName, String lastName, String businessName, String businessType, String password, String pin, bool isReturningUser, BusinessInfo? businessInfo, String otpCode, int otpAttempts, bool otpInCooldown, int otpCooldownEndTime, int otpExpiryTime, String otpErrorMessage, UserLookupResult? userLookupResult, String errorMessage
});


@override $BusinessInfoCopyWith<$Res>? get businessInfo;@override $UserLookupResultCopyWith<$Res>? get userLookupResult;

}
/// @nodoc
class __$OnboardingStateCopyWithImpl<$Res>
    implements _$OnboardingStateCopyWith<$Res> {
  __$OnboardingStateCopyWithImpl(this._self, this._then);

  final _OnboardingState _self;
  final $Res Function(_OnboardingState) _then;

/// Create a copy of OnboardingState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? language = null,Object? currentStep = null,Object? phone = null,Object? firstName = null,Object? lastName = null,Object? businessName = null,Object? businessType = null,Object? password = null,Object? pin = null,Object? isReturningUser = null,Object? businessInfo = freezed,Object? otpCode = null,Object? otpAttempts = null,Object? otpInCooldown = null,Object? otpCooldownEndTime = null,Object? otpExpiryTime = null,Object? otpErrorMessage = null,Object? userLookupResult = freezed,Object? errorMessage = null,}) {
  return _then(_OnboardingState(
language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,currentStep: null == currentStep ? _self.currentStep : currentStep // ignore: cast_nullable_to_non_nullable
as int,phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,firstName: null == firstName ? _self.firstName : firstName // ignore: cast_nullable_to_non_nullable
as String,lastName: null == lastName ? _self.lastName : lastName // ignore: cast_nullable_to_non_nullable
as String,businessName: null == businessName ? _self.businessName : businessName // ignore: cast_nullable_to_non_nullable
as String,businessType: null == businessType ? _self.businessType : businessType // ignore: cast_nullable_to_non_nullable
as String,password: null == password ? _self.password : password // ignore: cast_nullable_to_non_nullable
as String,pin: null == pin ? _self.pin : pin // ignore: cast_nullable_to_non_nullable
as String,isReturningUser: null == isReturningUser ? _self.isReturningUser : isReturningUser // ignore: cast_nullable_to_non_nullable
as bool,businessInfo: freezed == businessInfo ? _self.businessInfo : businessInfo // ignore: cast_nullable_to_non_nullable
as BusinessInfo?,otpCode: null == otpCode ? _self.otpCode : otpCode // ignore: cast_nullable_to_non_nullable
as String,otpAttempts: null == otpAttempts ? _self.otpAttempts : otpAttempts // ignore: cast_nullable_to_non_nullable
as int,otpInCooldown: null == otpInCooldown ? _self.otpInCooldown : otpInCooldown // ignore: cast_nullable_to_non_nullable
as bool,otpCooldownEndTime: null == otpCooldownEndTime ? _self.otpCooldownEndTime : otpCooldownEndTime // ignore: cast_nullable_to_non_nullable
as int,otpExpiryTime: null == otpExpiryTime ? _self.otpExpiryTime : otpExpiryTime // ignore: cast_nullable_to_non_nullable
as int,otpErrorMessage: null == otpErrorMessage ? _self.otpErrorMessage : otpErrorMessage // ignore: cast_nullable_to_non_nullable
as String,userLookupResult: freezed == userLookupResult ? _self.userLookupResult : userLookupResult // ignore: cast_nullable_to_non_nullable
as UserLookupResult?,errorMessage: null == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

/// Create a copy of OnboardingState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BusinessInfoCopyWith<$Res>? get businessInfo {
    if (_self.businessInfo == null) {
    return null;
  }

  return $BusinessInfoCopyWith<$Res>(_self.businessInfo!, (value) {
    return _then(_self.copyWith(businessInfo: value));
  });
}/// Create a copy of OnboardingState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UserLookupResultCopyWith<$Res>? get userLookupResult {
    if (_self.userLookupResult == null) {
    return null;
  }

  return $UserLookupResultCopyWith<$Res>(_self.userLookupResult!, (value) {
    return _then(_self.copyWith(userLookupResult: value));
  });
}
}

/// @nodoc
mixin _$BusinessInfo {

 String get businessId; String get businessName; String get businessType; String get city; String? get logo;
/// Create a copy of BusinessInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BusinessInfoCopyWith<BusinessInfo> get copyWith => _$BusinessInfoCopyWithImpl<BusinessInfo>(this as BusinessInfo, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BusinessInfo&&(identical(other.businessId, businessId) || other.businessId == businessId)&&(identical(other.businessName, businessName) || other.businessName == businessName)&&(identical(other.businessType, businessType) || other.businessType == businessType)&&(identical(other.city, city) || other.city == city)&&(identical(other.logo, logo) || other.logo == logo));
}


@override
int get hashCode => Object.hash(runtimeType,businessId,businessName,businessType,city,logo);

@override
String toString() {
  return 'BusinessInfo(businessId: $businessId, businessName: $businessName, businessType: $businessType, city: $city, logo: $logo)';
}


}

/// @nodoc
abstract mixin class $BusinessInfoCopyWith<$Res>  {
  factory $BusinessInfoCopyWith(BusinessInfo value, $Res Function(BusinessInfo) _then) = _$BusinessInfoCopyWithImpl;
@useResult
$Res call({
 String businessId, String businessName, String businessType, String city, String? logo
});




}
/// @nodoc
class _$BusinessInfoCopyWithImpl<$Res>
    implements $BusinessInfoCopyWith<$Res> {
  _$BusinessInfoCopyWithImpl(this._self, this._then);

  final BusinessInfo _self;
  final $Res Function(BusinessInfo) _then;

/// Create a copy of BusinessInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? businessId = null,Object? businessName = null,Object? businessType = null,Object? city = null,Object? logo = freezed,}) {
  return _then(_self.copyWith(
businessId: null == businessId ? _self.businessId : businessId // ignore: cast_nullable_to_non_nullable
as String,businessName: null == businessName ? _self.businessName : businessName // ignore: cast_nullable_to_non_nullable
as String,businessType: null == businessType ? _self.businessType : businessType // ignore: cast_nullable_to_non_nullable
as String,city: null == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String,logo: freezed == logo ? _self.logo : logo // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [BusinessInfo].
extension BusinessInfoPatterns on BusinessInfo {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BusinessInfo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BusinessInfo() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BusinessInfo value)  $default,){
final _that = this;
switch (_that) {
case _BusinessInfo():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BusinessInfo value)?  $default,){
final _that = this;
switch (_that) {
case _BusinessInfo() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String businessId,  String businessName,  String businessType,  String city,  String? logo)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BusinessInfo() when $default != null:
return $default(_that.businessId,_that.businessName,_that.businessType,_that.city,_that.logo);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String businessId,  String businessName,  String businessType,  String city,  String? logo)  $default,) {final _that = this;
switch (_that) {
case _BusinessInfo():
return $default(_that.businessId,_that.businessName,_that.businessType,_that.city,_that.logo);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String businessId,  String businessName,  String businessType,  String city,  String? logo)?  $default,) {final _that = this;
switch (_that) {
case _BusinessInfo() when $default != null:
return $default(_that.businessId,_that.businessName,_that.businessType,_that.city,_that.logo);case _:
  return null;

}
}

}

/// @nodoc


class _BusinessInfo implements BusinessInfo {
  const _BusinessInfo({required this.businessId, required this.businessName, required this.businessType, required this.city, required this.logo});
  

@override final  String businessId;
@override final  String businessName;
@override final  String businessType;
@override final  String city;
@override final  String? logo;

/// Create a copy of BusinessInfo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BusinessInfoCopyWith<_BusinessInfo> get copyWith => __$BusinessInfoCopyWithImpl<_BusinessInfo>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BusinessInfo&&(identical(other.businessId, businessId) || other.businessId == businessId)&&(identical(other.businessName, businessName) || other.businessName == businessName)&&(identical(other.businessType, businessType) || other.businessType == businessType)&&(identical(other.city, city) || other.city == city)&&(identical(other.logo, logo) || other.logo == logo));
}


@override
int get hashCode => Object.hash(runtimeType,businessId,businessName,businessType,city,logo);

@override
String toString() {
  return 'BusinessInfo(businessId: $businessId, businessName: $businessName, businessType: $businessType, city: $city, logo: $logo)';
}


}

/// @nodoc
abstract mixin class _$BusinessInfoCopyWith<$Res> implements $BusinessInfoCopyWith<$Res> {
  factory _$BusinessInfoCopyWith(_BusinessInfo value, $Res Function(_BusinessInfo) _then) = __$BusinessInfoCopyWithImpl;
@override @useResult
$Res call({
 String businessId, String businessName, String businessType, String city, String? logo
});




}
/// @nodoc
class __$BusinessInfoCopyWithImpl<$Res>
    implements _$BusinessInfoCopyWith<$Res> {
  __$BusinessInfoCopyWithImpl(this._self, this._then);

  final _BusinessInfo _self;
  final $Res Function(_BusinessInfo) _then;

/// Create a copy of BusinessInfo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? businessId = null,Object? businessName = null,Object? businessType = null,Object? city = null,Object? logo = freezed,}) {
  return _then(_BusinessInfo(
businessId: null == businessId ? _self.businessId : businessId // ignore: cast_nullable_to_non_nullable
as String,businessName: null == businessName ? _self.businessName : businessName // ignore: cast_nullable_to_non_nullable
as String,businessType: null == businessType ? _self.businessType : businessType // ignore: cast_nullable_to_non_nullable
as String,city: null == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String,logo: freezed == logo ? _self.logo : logo // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
