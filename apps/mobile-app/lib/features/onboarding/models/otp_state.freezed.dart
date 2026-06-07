// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'otp_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$OtpState {

/// OTP code entered
 String get code;/// Number of failed attempts
 int get attempts;/// Max allowed attempts before lockout
 int get maxAttempts;/// Whether account is locked due to too many attempts
 bool get isLocked;/// Timestamp when lockout expires (milliseconds since epoch)
 int get lockoutExpiryTime;/// Cooldown duration in seconds (30 seconds standard)
 int get cooldownDurationSeconds;/// OTP expiry time (milliseconds since epoch)
 int get expiryTime;/// Whether OTP is expired
 bool get isExpired;/// Error message
 String get errorMessage;/// Is waiting for server response
 bool get isLoading;
/// Create a copy of OtpState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OtpStateCopyWith<OtpState> get copyWith => _$OtpStateCopyWithImpl<OtpState>(this as OtpState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OtpState&&(identical(other.code, code) || other.code == code)&&(identical(other.attempts, attempts) || other.attempts == attempts)&&(identical(other.maxAttempts, maxAttempts) || other.maxAttempts == maxAttempts)&&(identical(other.isLocked, isLocked) || other.isLocked == isLocked)&&(identical(other.lockoutExpiryTime, lockoutExpiryTime) || other.lockoutExpiryTime == lockoutExpiryTime)&&(identical(other.cooldownDurationSeconds, cooldownDurationSeconds) || other.cooldownDurationSeconds == cooldownDurationSeconds)&&(identical(other.expiryTime, expiryTime) || other.expiryTime == expiryTime)&&(identical(other.isExpired, isExpired) || other.isExpired == isExpired)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading));
}


@override
int get hashCode => Object.hash(runtimeType,code,attempts,maxAttempts,isLocked,lockoutExpiryTime,cooldownDurationSeconds,expiryTime,isExpired,errorMessage,isLoading);

@override
String toString() {
  return 'OtpState(code: $code, attempts: $attempts, maxAttempts: $maxAttempts, isLocked: $isLocked, lockoutExpiryTime: $lockoutExpiryTime, cooldownDurationSeconds: $cooldownDurationSeconds, expiryTime: $expiryTime, isExpired: $isExpired, errorMessage: $errorMessage, isLoading: $isLoading)';
}


}

/// @nodoc
abstract mixin class $OtpStateCopyWith<$Res>  {
  factory $OtpStateCopyWith(OtpState value, $Res Function(OtpState) _then) = _$OtpStateCopyWithImpl;
@useResult
$Res call({
 String code, int attempts, int maxAttempts, bool isLocked, int lockoutExpiryTime, int cooldownDurationSeconds, int expiryTime, bool isExpired, String errorMessage, bool isLoading
});




}
/// @nodoc
class _$OtpStateCopyWithImpl<$Res>
    implements $OtpStateCopyWith<$Res> {
  _$OtpStateCopyWithImpl(this._self, this._then);

  final OtpState _self;
  final $Res Function(OtpState) _then;

/// Create a copy of OtpState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? code = null,Object? attempts = null,Object? maxAttempts = null,Object? isLocked = null,Object? lockoutExpiryTime = null,Object? cooldownDurationSeconds = null,Object? expiryTime = null,Object? isExpired = null,Object? errorMessage = null,Object? isLoading = null,}) {
  return _then(_self.copyWith(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,attempts: null == attempts ? _self.attempts : attempts // ignore: cast_nullable_to_non_nullable
as int,maxAttempts: null == maxAttempts ? _self.maxAttempts : maxAttempts // ignore: cast_nullable_to_non_nullable
as int,isLocked: null == isLocked ? _self.isLocked : isLocked // ignore: cast_nullable_to_non_nullable
as bool,lockoutExpiryTime: null == lockoutExpiryTime ? _self.lockoutExpiryTime : lockoutExpiryTime // ignore: cast_nullable_to_non_nullable
as int,cooldownDurationSeconds: null == cooldownDurationSeconds ? _self.cooldownDurationSeconds : cooldownDurationSeconds // ignore: cast_nullable_to_non_nullable
as int,expiryTime: null == expiryTime ? _self.expiryTime : expiryTime // ignore: cast_nullable_to_non_nullable
as int,isExpired: null == isExpired ? _self.isExpired : isExpired // ignore: cast_nullable_to_non_nullable
as bool,errorMessage: null == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [OtpState].
extension OtpStatePatterns on OtpState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OtpState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OtpState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OtpState value)  $default,){
final _that = this;
switch (_that) {
case _OtpState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OtpState value)?  $default,){
final _that = this;
switch (_that) {
case _OtpState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String code,  int attempts,  int maxAttempts,  bool isLocked,  int lockoutExpiryTime,  int cooldownDurationSeconds,  int expiryTime,  bool isExpired,  String errorMessage,  bool isLoading)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OtpState() when $default != null:
return $default(_that.code,_that.attempts,_that.maxAttempts,_that.isLocked,_that.lockoutExpiryTime,_that.cooldownDurationSeconds,_that.expiryTime,_that.isExpired,_that.errorMessage,_that.isLoading);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String code,  int attempts,  int maxAttempts,  bool isLocked,  int lockoutExpiryTime,  int cooldownDurationSeconds,  int expiryTime,  bool isExpired,  String errorMessage,  bool isLoading)  $default,) {final _that = this;
switch (_that) {
case _OtpState():
return $default(_that.code,_that.attempts,_that.maxAttempts,_that.isLocked,_that.lockoutExpiryTime,_that.cooldownDurationSeconds,_that.expiryTime,_that.isExpired,_that.errorMessage,_that.isLoading);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String code,  int attempts,  int maxAttempts,  bool isLocked,  int lockoutExpiryTime,  int cooldownDurationSeconds,  int expiryTime,  bool isExpired,  String errorMessage,  bool isLoading)?  $default,) {final _that = this;
switch (_that) {
case _OtpState() when $default != null:
return $default(_that.code,_that.attempts,_that.maxAttempts,_that.isLocked,_that.lockoutExpiryTime,_that.cooldownDurationSeconds,_that.expiryTime,_that.isExpired,_that.errorMessage,_that.isLoading);case _:
  return null;

}
}

}

/// @nodoc


class _OtpState extends OtpState {
  const _OtpState({required this.code, required this.attempts, this.maxAttempts = 3, required this.isLocked, required this.lockoutExpiryTime, this.cooldownDurationSeconds = 30, required this.expiryTime, required this.isExpired, required this.errorMessage, this.isLoading = false}): super._();
  

/// OTP code entered
@override final  String code;
/// Number of failed attempts
@override final  int attempts;
/// Max allowed attempts before lockout
@override@JsonKey() final  int maxAttempts;
/// Whether account is locked due to too many attempts
@override final  bool isLocked;
/// Timestamp when lockout expires (milliseconds since epoch)
@override final  int lockoutExpiryTime;
/// Cooldown duration in seconds (30 seconds standard)
@override@JsonKey() final  int cooldownDurationSeconds;
/// OTP expiry time (milliseconds since epoch)
@override final  int expiryTime;
/// Whether OTP is expired
@override final  bool isExpired;
/// Error message
@override final  String errorMessage;
/// Is waiting for server response
@override@JsonKey() final  bool isLoading;

/// Create a copy of OtpState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OtpStateCopyWith<_OtpState> get copyWith => __$OtpStateCopyWithImpl<_OtpState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OtpState&&(identical(other.code, code) || other.code == code)&&(identical(other.attempts, attempts) || other.attempts == attempts)&&(identical(other.maxAttempts, maxAttempts) || other.maxAttempts == maxAttempts)&&(identical(other.isLocked, isLocked) || other.isLocked == isLocked)&&(identical(other.lockoutExpiryTime, lockoutExpiryTime) || other.lockoutExpiryTime == lockoutExpiryTime)&&(identical(other.cooldownDurationSeconds, cooldownDurationSeconds) || other.cooldownDurationSeconds == cooldownDurationSeconds)&&(identical(other.expiryTime, expiryTime) || other.expiryTime == expiryTime)&&(identical(other.isExpired, isExpired) || other.isExpired == isExpired)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading));
}


@override
int get hashCode => Object.hash(runtimeType,code,attempts,maxAttempts,isLocked,lockoutExpiryTime,cooldownDurationSeconds,expiryTime,isExpired,errorMessage,isLoading);

@override
String toString() {
  return 'OtpState(code: $code, attempts: $attempts, maxAttempts: $maxAttempts, isLocked: $isLocked, lockoutExpiryTime: $lockoutExpiryTime, cooldownDurationSeconds: $cooldownDurationSeconds, expiryTime: $expiryTime, isExpired: $isExpired, errorMessage: $errorMessage, isLoading: $isLoading)';
}


}

/// @nodoc
abstract mixin class _$OtpStateCopyWith<$Res> implements $OtpStateCopyWith<$Res> {
  factory _$OtpStateCopyWith(_OtpState value, $Res Function(_OtpState) _then) = __$OtpStateCopyWithImpl;
@override @useResult
$Res call({
 String code, int attempts, int maxAttempts, bool isLocked, int lockoutExpiryTime, int cooldownDurationSeconds, int expiryTime, bool isExpired, String errorMessage, bool isLoading
});




}
/// @nodoc
class __$OtpStateCopyWithImpl<$Res>
    implements _$OtpStateCopyWith<$Res> {
  __$OtpStateCopyWithImpl(this._self, this._then);

  final _OtpState _self;
  final $Res Function(_OtpState) _then;

/// Create a copy of OtpState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? code = null,Object? attempts = null,Object? maxAttempts = null,Object? isLocked = null,Object? lockoutExpiryTime = null,Object? cooldownDurationSeconds = null,Object? expiryTime = null,Object? isExpired = null,Object? errorMessage = null,Object? isLoading = null,}) {
  return _then(_OtpState(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,attempts: null == attempts ? _self.attempts : attempts // ignore: cast_nullable_to_non_nullable
as int,maxAttempts: null == maxAttempts ? _self.maxAttempts : maxAttempts // ignore: cast_nullable_to_non_nullable
as int,isLocked: null == isLocked ? _self.isLocked : isLocked // ignore: cast_nullable_to_non_nullable
as bool,lockoutExpiryTime: null == lockoutExpiryTime ? _self.lockoutExpiryTime : lockoutExpiryTime // ignore: cast_nullable_to_non_nullable
as int,cooldownDurationSeconds: null == cooldownDurationSeconds ? _self.cooldownDurationSeconds : cooldownDurationSeconds // ignore: cast_nullable_to_non_nullable
as int,expiryTime: null == expiryTime ? _self.expiryTime : expiryTime // ignore: cast_nullable_to_non_nullable
as int,isExpired: null == isExpired ? _self.isExpired : isExpired // ignore: cast_nullable_to_non_nullable
as bool,errorMessage: null == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
