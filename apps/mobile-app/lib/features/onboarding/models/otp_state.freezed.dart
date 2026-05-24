// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'otp_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$OtpState {
  /// OTP code entered
  String get code => throw _privateConstructorUsedError;

  /// Number of failed attempts
  int get attempts => throw _privateConstructorUsedError;

  /// Max allowed attempts before lockout
  int get maxAttempts => throw _privateConstructorUsedError;

  /// Whether account is locked due to too many attempts
  bool get isLocked => throw _privateConstructorUsedError;

  /// Timestamp when lockout expires (milliseconds since epoch)
  int get lockoutExpiryTime => throw _privateConstructorUsedError;

  /// Cooldown duration in seconds (30 seconds standard)
  int get cooldownDurationSeconds => throw _privateConstructorUsedError;

  /// OTP expiry time (milliseconds since epoch)
  int get expiryTime => throw _privateConstructorUsedError;

  /// Whether OTP is expired
  bool get isExpired => throw _privateConstructorUsedError;

  /// Error message
  String get errorMessage => throw _privateConstructorUsedError;

  /// Is waiting for server response
  bool get isLoading => throw _privateConstructorUsedError;

  /// Create a copy of OtpState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $OtpStateCopyWith<OtpState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $OtpStateCopyWith<$Res> {
  factory $OtpStateCopyWith(OtpState value, $Res Function(OtpState) then) =
      _$OtpStateCopyWithImpl<$Res, OtpState>;
  @useResult
  $Res call({
    String code,
    int attempts,
    int maxAttempts,
    bool isLocked,
    int lockoutExpiryTime,
    int cooldownDurationSeconds,
    int expiryTime,
    bool isExpired,
    String errorMessage,
    bool isLoading,
  });
}

/// @nodoc
class _$OtpStateCopyWithImpl<$Res, $Val extends OtpState>
    implements $OtpStateCopyWith<$Res> {
  _$OtpStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of OtpState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? code = null,
    Object? attempts = null,
    Object? maxAttempts = null,
    Object? isLocked = null,
    Object? lockoutExpiryTime = null,
    Object? cooldownDurationSeconds = null,
    Object? expiryTime = null,
    Object? isExpired = null,
    Object? errorMessage = null,
    Object? isLoading = null,
  }) {
    return _then(
      _value.copyWith(
            code: null == code
                ? _value.code
                : code // ignore: cast_nullable_to_non_nullable
                      as String,
            attempts: null == attempts
                ? _value.attempts
                : attempts // ignore: cast_nullable_to_non_nullable
                      as int,
            maxAttempts: null == maxAttempts
                ? _value.maxAttempts
                : maxAttempts // ignore: cast_nullable_to_non_nullable
                      as int,
            isLocked: null == isLocked
                ? _value.isLocked
                : isLocked // ignore: cast_nullable_to_non_nullable
                      as bool,
            lockoutExpiryTime: null == lockoutExpiryTime
                ? _value.lockoutExpiryTime
                : lockoutExpiryTime // ignore: cast_nullable_to_non_nullable
                      as int,
            cooldownDurationSeconds: null == cooldownDurationSeconds
                ? _value.cooldownDurationSeconds
                : cooldownDurationSeconds // ignore: cast_nullable_to_non_nullable
                      as int,
            expiryTime: null == expiryTime
                ? _value.expiryTime
                : expiryTime // ignore: cast_nullable_to_non_nullable
                      as int,
            isExpired: null == isExpired
                ? _value.isExpired
                : isExpired // ignore: cast_nullable_to_non_nullable
                      as bool,
            errorMessage: null == errorMessage
                ? _value.errorMessage
                : errorMessage // ignore: cast_nullable_to_non_nullable
                      as String,
            isLoading: null == isLoading
                ? _value.isLoading
                : isLoading // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$OtpStateImplCopyWith<$Res>
    implements $OtpStateCopyWith<$Res> {
  factory _$$OtpStateImplCopyWith(
    _$OtpStateImpl value,
    $Res Function(_$OtpStateImpl) then,
  ) = __$$OtpStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String code,
    int attempts,
    int maxAttempts,
    bool isLocked,
    int lockoutExpiryTime,
    int cooldownDurationSeconds,
    int expiryTime,
    bool isExpired,
    String errorMessage,
    bool isLoading,
  });
}

/// @nodoc
class __$$OtpStateImplCopyWithImpl<$Res>
    extends _$OtpStateCopyWithImpl<$Res, _$OtpStateImpl>
    implements _$$OtpStateImplCopyWith<$Res> {
  __$$OtpStateImplCopyWithImpl(
    _$OtpStateImpl _value,
    $Res Function(_$OtpStateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of OtpState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? code = null,
    Object? attempts = null,
    Object? maxAttempts = null,
    Object? isLocked = null,
    Object? lockoutExpiryTime = null,
    Object? cooldownDurationSeconds = null,
    Object? expiryTime = null,
    Object? isExpired = null,
    Object? errorMessage = null,
    Object? isLoading = null,
  }) {
    return _then(
      _$OtpStateImpl(
        code: null == code
            ? _value.code
            : code // ignore: cast_nullable_to_non_nullable
                  as String,
        attempts: null == attempts
            ? _value.attempts
            : attempts // ignore: cast_nullable_to_non_nullable
                  as int,
        maxAttempts: null == maxAttempts
            ? _value.maxAttempts
            : maxAttempts // ignore: cast_nullable_to_non_nullable
                  as int,
        isLocked: null == isLocked
            ? _value.isLocked
            : isLocked // ignore: cast_nullable_to_non_nullable
                  as bool,
        lockoutExpiryTime: null == lockoutExpiryTime
            ? _value.lockoutExpiryTime
            : lockoutExpiryTime // ignore: cast_nullable_to_non_nullable
                  as int,
        cooldownDurationSeconds: null == cooldownDurationSeconds
            ? _value.cooldownDurationSeconds
            : cooldownDurationSeconds // ignore: cast_nullable_to_non_nullable
                  as int,
        expiryTime: null == expiryTime
            ? _value.expiryTime
            : expiryTime // ignore: cast_nullable_to_non_nullable
                  as int,
        isExpired: null == isExpired
            ? _value.isExpired
            : isExpired // ignore: cast_nullable_to_non_nullable
                  as bool,
        errorMessage: null == errorMessage
            ? _value.errorMessage
            : errorMessage // ignore: cast_nullable_to_non_nullable
                  as String,
        isLoading: null == isLoading
            ? _value.isLoading
            : isLoading // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc

class _$OtpStateImpl extends _OtpState {
  const _$OtpStateImpl({
    required this.code,
    required this.attempts,
    this.maxAttempts = 3,
    required this.isLocked,
    required this.lockoutExpiryTime,
    this.cooldownDurationSeconds = 30,
    required this.expiryTime,
    required this.isExpired,
    required this.errorMessage,
    this.isLoading = false,
  }) : super._();

  /// OTP code entered
  @override
  final String code;

  /// Number of failed attempts
  @override
  final int attempts;

  /// Max allowed attempts before lockout
  @override
  @JsonKey()
  final int maxAttempts;

  /// Whether account is locked due to too many attempts
  @override
  final bool isLocked;

  /// Timestamp when lockout expires (milliseconds since epoch)
  @override
  final int lockoutExpiryTime;

  /// Cooldown duration in seconds (30 seconds standard)
  @override
  @JsonKey()
  final int cooldownDurationSeconds;

  /// OTP expiry time (milliseconds since epoch)
  @override
  final int expiryTime;

  /// Whether OTP is expired
  @override
  final bool isExpired;

  /// Error message
  @override
  final String errorMessage;

  /// Is waiting for server response
  @override
  @JsonKey()
  final bool isLoading;

  @override
  String toString() {
    return 'OtpState(code: $code, attempts: $attempts, maxAttempts: $maxAttempts, isLocked: $isLocked, lockoutExpiryTime: $lockoutExpiryTime, cooldownDurationSeconds: $cooldownDurationSeconds, expiryTime: $expiryTime, isExpired: $isExpired, errorMessage: $errorMessage, isLoading: $isLoading)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OtpStateImpl &&
            (identical(other.code, code) || other.code == code) &&
            (identical(other.attempts, attempts) ||
                other.attempts == attempts) &&
            (identical(other.maxAttempts, maxAttempts) ||
                other.maxAttempts == maxAttempts) &&
            (identical(other.isLocked, isLocked) ||
                other.isLocked == isLocked) &&
            (identical(other.lockoutExpiryTime, lockoutExpiryTime) ||
                other.lockoutExpiryTime == lockoutExpiryTime) &&
            (identical(
                  other.cooldownDurationSeconds,
                  cooldownDurationSeconds,
                ) ||
                other.cooldownDurationSeconds == cooldownDurationSeconds) &&
            (identical(other.expiryTime, expiryTime) ||
                other.expiryTime == expiryTime) &&
            (identical(other.isExpired, isExpired) ||
                other.isExpired == isExpired) &&
            (identical(other.errorMessage, errorMessage) ||
                other.errorMessage == errorMessage) &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    code,
    attempts,
    maxAttempts,
    isLocked,
    lockoutExpiryTime,
    cooldownDurationSeconds,
    expiryTime,
    isExpired,
    errorMessage,
    isLoading,
  );

  /// Create a copy of OtpState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$OtpStateImplCopyWith<_$OtpStateImpl> get copyWith =>
      __$$OtpStateImplCopyWithImpl<_$OtpStateImpl>(this, _$identity);
}

abstract class _OtpState extends OtpState {
  const factory _OtpState({
    required final String code,
    required final int attempts,
    final int maxAttempts,
    required final bool isLocked,
    required final int lockoutExpiryTime,
    final int cooldownDurationSeconds,
    required final int expiryTime,
    required final bool isExpired,
    required final String errorMessage,
    final bool isLoading,
  }) = _$OtpStateImpl;
  const _OtpState._() : super._();

  /// OTP code entered
  @override
  String get code;

  /// Number of failed attempts
  @override
  int get attempts;

  /// Max allowed attempts before lockout
  @override
  int get maxAttempts;

  /// Whether account is locked due to too many attempts
  @override
  bool get isLocked;

  /// Timestamp when lockout expires (milliseconds since epoch)
  @override
  int get lockoutExpiryTime;

  /// Cooldown duration in seconds (30 seconds standard)
  @override
  int get cooldownDurationSeconds;

  /// OTP expiry time (milliseconds since epoch)
  @override
  int get expiryTime;

  /// Whether OTP is expired
  @override
  bool get isExpired;

  /// Error message
  @override
  String get errorMessage;

  /// Is waiting for server response
  @override
  bool get isLoading;

  /// Create a copy of OtpState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$OtpStateImplCopyWith<_$OtpStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
