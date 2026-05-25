// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'onboarding_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$OnboardingState {
  /// Language selection: 'en' or 'sw'
  String get language => throw _privateConstructorUsedError;

  /// Current screen step (1-7)
  int get currentStep => throw _privateConstructorUsedError;

  /// Phone number (without country code, e.g., "756123456")
  String get phone => throw _privateConstructorUsedError;

  /// First name of user
  String get firstName => throw _privateConstructorUsedError;

  /// Last name of user
  String get lastName => throw _privateConstructorUsedError;

  /// Business name
  String get businessName => throw _privateConstructorUsedError;

  /// Business type (e.g., "Retail", "Services", "Manufacturing")
  String get businessType => throw _privateConstructorUsedError;

  /// Password (min 8 chars, at least 1 number)
  String get password => throw _privateConstructorUsedError;

  /// 4-digit PIN
  String get pin => throw _privateConstructorUsedError;

  /// Is returning user (determined after phone lookup)
  bool get isReturningUser => throw _privateConstructorUsedError;

  /// Business details for returning users
  BusinessInfo? get businessInfo => throw _privateConstructorUsedError;

  /// OTP code entered by user
  String get otpCode => throw _privateConstructorUsedError;

  /// Number of OTP verification attempts
  int get otpAttempts => throw _privateConstructorUsedError;

  /// Whether user is in OTP cooldown period (after failed attempts)
  bool get otpInCooldown => throw _privateConstructorUsedError;

  /// Cooldown end timestamp (milliseconds since epoch)
  int get otpCooldownEndTime => throw _privateConstructorUsedError;

  /// OTP expiry timestamp (milliseconds since epoch)
  int get otpExpiryTime => throw _privateConstructorUsedError;

  /// Error message for OTP
  String get otpErrorMessage => throw _privateConstructorUsedError;

  /// User lookup result (populated after phone verification)
  UserLookupResult? get userLookupResult => throw _privateConstructorUsedError;

  /// General error message
  String get errorMessage => throw _privateConstructorUsedError;

  /// Create a copy of OnboardingState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $OnboardingStateCopyWith<OnboardingState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $OnboardingStateCopyWith<$Res> {
  factory $OnboardingStateCopyWith(
    OnboardingState value,
    $Res Function(OnboardingState) then,
  ) = _$OnboardingStateCopyWithImpl<$Res, OnboardingState>;
  @useResult
  $Res call({
    String language,
    int currentStep,
    String phone,
    String firstName,
    String lastName,
    String businessName,
    String businessType,
    String password,
    String pin,
    bool isReturningUser,
    BusinessInfo? businessInfo,
    String otpCode,
    int otpAttempts,
    bool otpInCooldown,
    int otpCooldownEndTime,
    int otpExpiryTime,
    String otpErrorMessage,
    UserLookupResult? userLookupResult,
    String errorMessage,
  });

  $BusinessInfoCopyWith<$Res>? get businessInfo;
  $UserLookupResultCopyWith<$Res>? get userLookupResult;
}

/// @nodoc
class _$OnboardingStateCopyWithImpl<$Res, $Val extends OnboardingState>
    implements $OnboardingStateCopyWith<$Res> {
  _$OnboardingStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of OnboardingState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? language = null,
    Object? currentStep = null,
    Object? phone = null,
    Object? firstName = null,
    Object? lastName = null,
    Object? businessName = null,
    Object? businessType = null,
    Object? password = null,
    Object? pin = null,
    Object? isReturningUser = null,
    Object? businessInfo = freezed,
    Object? otpCode = null,
    Object? otpAttempts = null,
    Object? otpInCooldown = null,
    Object? otpCooldownEndTime = null,
    Object? otpExpiryTime = null,
    Object? otpErrorMessage = null,
    Object? userLookupResult = freezed,
    Object? errorMessage = null,
  }) {
    return _then(
      _value.copyWith(
            language: null == language
                ? _value.language
                : language // ignore: cast_nullable_to_non_nullable
                      as String,
            currentStep: null == currentStep
                ? _value.currentStep
                : currentStep // ignore: cast_nullable_to_non_nullable
                      as int,
            phone: null == phone
                ? _value.phone
                : phone // ignore: cast_nullable_to_non_nullable
                      as String,
            firstName: null == firstName
                ? _value.firstName
                : firstName // ignore: cast_nullable_to_non_nullable
                      as String,
            lastName: null == lastName
                ? _value.lastName
                : lastName // ignore: cast_nullable_to_non_nullable
                      as String,
            businessName: null == businessName
                ? _value.businessName
                : businessName // ignore: cast_nullable_to_non_nullable
                      as String,
            businessType: null == businessType
                ? _value.businessType
                : businessType // ignore: cast_nullable_to_non_nullable
                      as String,
            password: null == password
                ? _value.password
                : password // ignore: cast_nullable_to_non_nullable
                      as String,
            pin: null == pin
                ? _value.pin
                : pin // ignore: cast_nullable_to_non_nullable
                      as String,
            isReturningUser: null == isReturningUser
                ? _value.isReturningUser
                : isReturningUser // ignore: cast_nullable_to_non_nullable
                      as bool,
            businessInfo: freezed == businessInfo
                ? _value.businessInfo
                : businessInfo // ignore: cast_nullable_to_non_nullable
                      as BusinessInfo?,
            otpCode: null == otpCode
                ? _value.otpCode
                : otpCode // ignore: cast_nullable_to_non_nullable
                      as String,
            otpAttempts: null == otpAttempts
                ? _value.otpAttempts
                : otpAttempts // ignore: cast_nullable_to_non_nullable
                      as int,
            otpInCooldown: null == otpInCooldown
                ? _value.otpInCooldown
                : otpInCooldown // ignore: cast_nullable_to_non_nullable
                      as bool,
            otpCooldownEndTime: null == otpCooldownEndTime
                ? _value.otpCooldownEndTime
                : otpCooldownEndTime // ignore: cast_nullable_to_non_nullable
                      as int,
            otpExpiryTime: null == otpExpiryTime
                ? _value.otpExpiryTime
                : otpExpiryTime // ignore: cast_nullable_to_non_nullable
                      as int,
            otpErrorMessage: null == otpErrorMessage
                ? _value.otpErrorMessage
                : otpErrorMessage // ignore: cast_nullable_to_non_nullable
                      as String,
            userLookupResult: freezed == userLookupResult
                ? _value.userLookupResult
                : userLookupResult // ignore: cast_nullable_to_non_nullable
                      as UserLookupResult?,
            errorMessage: null == errorMessage
                ? _value.errorMessage
                : errorMessage // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }

  /// Create a copy of OnboardingState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $BusinessInfoCopyWith<$Res>? get businessInfo {
    if (_value.businessInfo == null) {
      return null;
    }

    return $BusinessInfoCopyWith<$Res>(_value.businessInfo!, (value) {
      return _then(_value.copyWith(businessInfo: value) as $Val);
    });
  }

  /// Create a copy of OnboardingState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $UserLookupResultCopyWith<$Res>? get userLookupResult {
    if (_value.userLookupResult == null) {
      return null;
    }

    return $UserLookupResultCopyWith<$Res>(_value.userLookupResult!, (value) {
      return _then(_value.copyWith(userLookupResult: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$OnboardingStateImplCopyWith<$Res>
    implements $OnboardingStateCopyWith<$Res> {
  factory _$$OnboardingStateImplCopyWith(
    _$OnboardingStateImpl value,
    $Res Function(_$OnboardingStateImpl) then,
  ) = __$$OnboardingStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String language,
    int currentStep,
    String phone,
    String firstName,
    String lastName,
    String businessName,
    String businessType,
    String password,
    String pin,
    bool isReturningUser,
    BusinessInfo? businessInfo,
    String otpCode,
    int otpAttempts,
    bool otpInCooldown,
    int otpCooldownEndTime,
    int otpExpiryTime,
    String otpErrorMessage,
    UserLookupResult? userLookupResult,
    String errorMessage,
  });

  @override
  $BusinessInfoCopyWith<$Res>? get businessInfo;
  @override
  $UserLookupResultCopyWith<$Res>? get userLookupResult;
}

/// @nodoc
class __$$OnboardingStateImplCopyWithImpl<$Res>
    extends _$OnboardingStateCopyWithImpl<$Res, _$OnboardingStateImpl>
    implements _$$OnboardingStateImplCopyWith<$Res> {
  __$$OnboardingStateImplCopyWithImpl(
    _$OnboardingStateImpl _value,
    $Res Function(_$OnboardingStateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of OnboardingState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? language = null,
    Object? currentStep = null,
    Object? phone = null,
    Object? firstName = null,
    Object? lastName = null,
    Object? businessName = null,
    Object? businessType = null,
    Object? password = null,
    Object? pin = null,
    Object? isReturningUser = null,
    Object? businessInfo = freezed,
    Object? otpCode = null,
    Object? otpAttempts = null,
    Object? otpInCooldown = null,
    Object? otpCooldownEndTime = null,
    Object? otpExpiryTime = null,
    Object? otpErrorMessage = null,
    Object? userLookupResult = freezed,
    Object? errorMessage = null,
  }) {
    return _then(
      _$OnboardingStateImpl(
        language: null == language
            ? _value.language
            : language // ignore: cast_nullable_to_non_nullable
                  as String,
        currentStep: null == currentStep
            ? _value.currentStep
            : currentStep // ignore: cast_nullable_to_non_nullable
                  as int,
        phone: null == phone
            ? _value.phone
            : phone // ignore: cast_nullable_to_non_nullable
                  as String,
        firstName: null == firstName
            ? _value.firstName
            : firstName // ignore: cast_nullable_to_non_nullable
                  as String,
        lastName: null == lastName
            ? _value.lastName
            : lastName // ignore: cast_nullable_to_non_nullable
                  as String,
        businessName: null == businessName
            ? _value.businessName
            : businessName // ignore: cast_nullable_to_non_nullable
                  as String,
        businessType: null == businessType
            ? _value.businessType
            : businessType // ignore: cast_nullable_to_non_nullable
                  as String,
        password: null == password
            ? _value.password
            : password // ignore: cast_nullable_to_non_nullable
                  as String,
        pin: null == pin
            ? _value.pin
            : pin // ignore: cast_nullable_to_non_nullable
                  as String,
        isReturningUser: null == isReturningUser
            ? _value.isReturningUser
            : isReturningUser // ignore: cast_nullable_to_non_nullable
                  as bool,
        businessInfo: freezed == businessInfo
            ? _value.businessInfo
            : businessInfo // ignore: cast_nullable_to_non_nullable
                  as BusinessInfo?,
        otpCode: null == otpCode
            ? _value.otpCode
            : otpCode // ignore: cast_nullable_to_non_nullable
                  as String,
        otpAttempts: null == otpAttempts
            ? _value.otpAttempts
            : otpAttempts // ignore: cast_nullable_to_non_nullable
                  as int,
        otpInCooldown: null == otpInCooldown
            ? _value.otpInCooldown
            : otpInCooldown // ignore: cast_nullable_to_non_nullable
                  as bool,
        otpCooldownEndTime: null == otpCooldownEndTime
            ? _value.otpCooldownEndTime
            : otpCooldownEndTime // ignore: cast_nullable_to_non_nullable
                  as int,
        otpExpiryTime: null == otpExpiryTime
            ? _value.otpExpiryTime
            : otpExpiryTime // ignore: cast_nullable_to_non_nullable
                  as int,
        otpErrorMessage: null == otpErrorMessage
            ? _value.otpErrorMessage
            : otpErrorMessage // ignore: cast_nullable_to_non_nullable
                  as String,
        userLookupResult: freezed == userLookupResult
            ? _value.userLookupResult
            : userLookupResult // ignore: cast_nullable_to_non_nullable
                  as UserLookupResult?,
        errorMessage: null == errorMessage
            ? _value.errorMessage
            : errorMessage // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$OnboardingStateImpl extends _OnboardingState {
  const _$OnboardingStateImpl({
    required this.language,
    required this.currentStep,
    required this.phone,
    required this.firstName,
    required this.lastName,
    required this.businessName,
    required this.businessType,
    required this.password,
    required this.pin,
    required this.isReturningUser,
    required this.businessInfo,
    required this.otpCode,
    required this.otpAttempts,
    required this.otpInCooldown,
    required this.otpCooldownEndTime,
    required this.otpExpiryTime,
    required this.otpErrorMessage,
    required this.userLookupResult,
    required this.errorMessage,
  }) : super._();

  /// Language selection: 'en' or 'sw'
  @override
  final String language;

  /// Current screen step (1-7)
  @override
  final int currentStep;

  /// Phone number (without country code, e.g., "756123456")
  @override
  final String phone;

  /// First name of user
  @override
  final String firstName;

  /// Last name of user
  @override
  final String lastName;

  /// Business name
  @override
  final String businessName;

  /// Business type (e.g., "Retail", "Services", "Manufacturing")
  @override
  final String businessType;

  /// Password (min 8 chars, at least 1 number)
  @override
  final String password;

  /// 4-digit PIN
  @override
  final String pin;

  /// Is returning user (determined after phone lookup)
  @override
  final bool isReturningUser;

  /// Business details for returning users
  @override
  final BusinessInfo? businessInfo;

  /// OTP code entered by user
  @override
  final String otpCode;

  /// Number of OTP verification attempts
  @override
  final int otpAttempts;

  /// Whether user is in OTP cooldown period (after failed attempts)
  @override
  final bool otpInCooldown;

  /// Cooldown end timestamp (milliseconds since epoch)
  @override
  final int otpCooldownEndTime;

  /// OTP expiry timestamp (milliseconds since epoch)
  @override
  final int otpExpiryTime;

  /// Error message for OTP
  @override
  final String otpErrorMessage;

  /// User lookup result (populated after phone verification)
  @override
  final UserLookupResult? userLookupResult;

  /// General error message
  @override
  final String errorMessage;

  @override
  String toString() {
    return 'OnboardingState(language: $language, currentStep: $currentStep, phone: $phone, firstName: $firstName, lastName: $lastName, businessName: $businessName, businessType: $businessType, password: $password, pin: $pin, isReturningUser: $isReturningUser, businessInfo: $businessInfo, otpCode: $otpCode, otpAttempts: $otpAttempts, otpInCooldown: $otpInCooldown, otpCooldownEndTime: $otpCooldownEndTime, otpExpiryTime: $otpExpiryTime, otpErrorMessage: $otpErrorMessage, userLookupResult: $userLookupResult, errorMessage: $errorMessage)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OnboardingStateImpl &&
            (identical(other.language, language) ||
                other.language == language) &&
            (identical(other.currentStep, currentStep) ||
                other.currentStep == currentStep) &&
            (identical(other.phone, phone) || other.phone == phone) &&
            (identical(other.firstName, firstName) ||
                other.firstName == firstName) &&
            (identical(other.lastName, lastName) ||
                other.lastName == lastName) &&
            (identical(other.businessName, businessName) ||
                other.businessName == businessName) &&
            (identical(other.businessType, businessType) ||
                other.businessType == businessType) &&
            (identical(other.password, password) ||
                other.password == password) &&
            (identical(other.pin, pin) || other.pin == pin) &&
            (identical(other.isReturningUser, isReturningUser) ||
                other.isReturningUser == isReturningUser) &&
            (identical(other.businessInfo, businessInfo) ||
                other.businessInfo == businessInfo) &&
            (identical(other.otpCode, otpCode) || other.otpCode == otpCode) &&
            (identical(other.otpAttempts, otpAttempts) ||
                other.otpAttempts == otpAttempts) &&
            (identical(other.otpInCooldown, otpInCooldown) ||
                other.otpInCooldown == otpInCooldown) &&
            (identical(other.otpCooldownEndTime, otpCooldownEndTime) ||
                other.otpCooldownEndTime == otpCooldownEndTime) &&
            (identical(other.otpExpiryTime, otpExpiryTime) ||
                other.otpExpiryTime == otpExpiryTime) &&
            (identical(other.otpErrorMessage, otpErrorMessage) ||
                other.otpErrorMessage == otpErrorMessage) &&
            (identical(other.userLookupResult, userLookupResult) ||
                other.userLookupResult == userLookupResult) &&
            (identical(other.errorMessage, errorMessage) ||
                other.errorMessage == errorMessage));
  }

  @override
  int get hashCode => Object.hashAll([
    runtimeType,
    language,
    currentStep,
    phone,
    firstName,
    lastName,
    businessName,
    businessType,
    password,
    pin,
    isReturningUser,
    businessInfo,
    otpCode,
    otpAttempts,
    otpInCooldown,
    otpCooldownEndTime,
    otpExpiryTime,
    otpErrorMessage,
    userLookupResult,
    errorMessage,
  ]);

  /// Create a copy of OnboardingState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$OnboardingStateImplCopyWith<_$OnboardingStateImpl> get copyWith =>
      __$$OnboardingStateImplCopyWithImpl<_$OnboardingStateImpl>(
        this,
        _$identity,
      );
}

abstract class _OnboardingState extends OnboardingState {
  const factory _OnboardingState({
    required final String language,
    required final int currentStep,
    required final String phone,
    required final String firstName,
    required final String lastName,
    required final String businessName,
    required final String businessType,
    required final String password,
    required final String pin,
    required final bool isReturningUser,
    required final BusinessInfo? businessInfo,
    required final String otpCode,
    required final int otpAttempts,
    required final bool otpInCooldown,
    required final int otpCooldownEndTime,
    required final int otpExpiryTime,
    required final String otpErrorMessage,
    required final UserLookupResult? userLookupResult,
    required final String errorMessage,
  }) = _$OnboardingStateImpl;
  const _OnboardingState._() : super._();

  /// Language selection: 'en' or 'sw'
  @override
  String get language;

  /// Current screen step (1-7)
  @override
  int get currentStep;

  /// Phone number (without country code, e.g., "756123456")
  @override
  String get phone;

  /// First name of user
  @override
  String get firstName;

  /// Last name of user
  @override
  String get lastName;

  /// Business name
  @override
  String get businessName;

  /// Business type (e.g., "Retail", "Services", "Manufacturing")
  @override
  String get businessType;

  /// Password (min 8 chars, at least 1 number)
  @override
  String get password;

  /// 4-digit PIN
  @override
  String get pin;

  /// Is returning user (determined after phone lookup)
  @override
  bool get isReturningUser;

  /// Business details for returning users
  @override
  BusinessInfo? get businessInfo;

  /// OTP code entered by user
  @override
  String get otpCode;

  /// Number of OTP verification attempts
  @override
  int get otpAttempts;

  /// Whether user is in OTP cooldown period (after failed attempts)
  @override
  bool get otpInCooldown;

  /// Cooldown end timestamp (milliseconds since epoch)
  @override
  int get otpCooldownEndTime;

  /// OTP expiry timestamp (milliseconds since epoch)
  @override
  int get otpExpiryTime;

  /// Error message for OTP
  @override
  String get otpErrorMessage;

  /// User lookup result (populated after phone verification)
  @override
  UserLookupResult? get userLookupResult;

  /// General error message
  @override
  String get errorMessage;

  /// Create a copy of OnboardingState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$OnboardingStateImplCopyWith<_$OnboardingStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$BusinessInfo {
  String get businessId => throw _privateConstructorUsedError;
  String get businessName => throw _privateConstructorUsedError;
  String get businessType => throw _privateConstructorUsedError;
  String get city => throw _privateConstructorUsedError;
  String? get logo => throw _privateConstructorUsedError;

  /// Create a copy of BusinessInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $BusinessInfoCopyWith<BusinessInfo> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BusinessInfoCopyWith<$Res> {
  factory $BusinessInfoCopyWith(
    BusinessInfo value,
    $Res Function(BusinessInfo) then,
  ) = _$BusinessInfoCopyWithImpl<$Res, BusinessInfo>;
  @useResult
  $Res call({
    String businessId,
    String businessName,
    String businessType,
    String city,
    String? logo,
  });
}

/// @nodoc
class _$BusinessInfoCopyWithImpl<$Res, $Val extends BusinessInfo>
    implements $BusinessInfoCopyWith<$Res> {
  _$BusinessInfoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of BusinessInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? businessId = null,
    Object? businessName = null,
    Object? businessType = null,
    Object? city = null,
    Object? logo = freezed,
  }) {
    return _then(
      _value.copyWith(
            businessId: null == businessId
                ? _value.businessId
                : businessId // ignore: cast_nullable_to_non_nullable
                      as String,
            businessName: null == businessName
                ? _value.businessName
                : businessName // ignore: cast_nullable_to_non_nullable
                      as String,
            businessType: null == businessType
                ? _value.businessType
                : businessType // ignore: cast_nullable_to_non_nullable
                      as String,
            city: null == city
                ? _value.city
                : city // ignore: cast_nullable_to_non_nullable
                      as String,
            logo: freezed == logo
                ? _value.logo
                : logo // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$BusinessInfoImplCopyWith<$Res>
    implements $BusinessInfoCopyWith<$Res> {
  factory _$$BusinessInfoImplCopyWith(
    _$BusinessInfoImpl value,
    $Res Function(_$BusinessInfoImpl) then,
  ) = __$$BusinessInfoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String businessId,
    String businessName,
    String businessType,
    String city,
    String? logo,
  });
}

/// @nodoc
class __$$BusinessInfoImplCopyWithImpl<$Res>
    extends _$BusinessInfoCopyWithImpl<$Res, _$BusinessInfoImpl>
    implements _$$BusinessInfoImplCopyWith<$Res> {
  __$$BusinessInfoImplCopyWithImpl(
    _$BusinessInfoImpl _value,
    $Res Function(_$BusinessInfoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of BusinessInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? businessId = null,
    Object? businessName = null,
    Object? businessType = null,
    Object? city = null,
    Object? logo = freezed,
  }) {
    return _then(
      _$BusinessInfoImpl(
        businessId: null == businessId
            ? _value.businessId
            : businessId // ignore: cast_nullable_to_non_nullable
                  as String,
        businessName: null == businessName
            ? _value.businessName
            : businessName // ignore: cast_nullable_to_non_nullable
                  as String,
        businessType: null == businessType
            ? _value.businessType
            : businessType // ignore: cast_nullable_to_non_nullable
                  as String,
        city: null == city
            ? _value.city
            : city // ignore: cast_nullable_to_non_nullable
                  as String,
        logo: freezed == logo
            ? _value.logo
            : logo // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc

class _$BusinessInfoImpl implements _BusinessInfo {
  const _$BusinessInfoImpl({
    required this.businessId,
    required this.businessName,
    required this.businessType,
    required this.city,
    required this.logo,
  });

  @override
  final String businessId;
  @override
  final String businessName;
  @override
  final String businessType;
  @override
  final String city;
  @override
  final String? logo;

  @override
  String toString() {
    return 'BusinessInfo(businessId: $businessId, businessName: $businessName, businessType: $businessType, city: $city, logo: $logo)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BusinessInfoImpl &&
            (identical(other.businessId, businessId) ||
                other.businessId == businessId) &&
            (identical(other.businessName, businessName) ||
                other.businessName == businessName) &&
            (identical(other.businessType, businessType) ||
                other.businessType == businessType) &&
            (identical(other.city, city) || other.city == city) &&
            (identical(other.logo, logo) || other.logo == logo));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    businessId,
    businessName,
    businessType,
    city,
    logo,
  );

  /// Create a copy of BusinessInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BusinessInfoImplCopyWith<_$BusinessInfoImpl> get copyWith =>
      __$$BusinessInfoImplCopyWithImpl<_$BusinessInfoImpl>(this, _$identity);
}

abstract class _BusinessInfo implements BusinessInfo {
  const factory _BusinessInfo({
    required final String businessId,
    required final String businessName,
    required final String businessType,
    required final String city,
    required final String? logo,
  }) = _$BusinessInfoImpl;

  @override
  String get businessId;
  @override
  String get businessName;
  @override
  String get businessType;
  @override
  String get city;
  @override
  String? get logo;

  /// Create a copy of BusinessInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BusinessInfoImplCopyWith<_$BusinessInfoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
