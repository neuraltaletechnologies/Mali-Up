// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_lookup_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$UserLookupResult {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
      String userId,
      String firstName,
      String lastName,
      String businessId,
      String businessName,
      String businessType,
      String city,
      String? businessLogo,
    )
    returningUser,
    required TResult Function() newUser,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(
      String userId,
      String firstName,
      String lastName,
      String businessId,
      String businessName,
      String businessType,
      String city,
      String? businessLogo,
    )?
    returningUser,
    TResult? Function()? newUser,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(
      String userId,
      String firstName,
      String lastName,
      String businessId,
      String businessName,
      String businessType,
      String city,
      String? businessLogo,
    )?
    returningUser,
    TResult Function()? newUser,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(ReturningUser value) returningUser,
    required TResult Function(NewUser value) newUser,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(ReturningUser value)? returningUser,
    TResult? Function(NewUser value)? newUser,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(ReturningUser value)? returningUser,
    TResult Function(NewUser value)? newUser,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserLookupResultCopyWith<$Res> {
  factory $UserLookupResultCopyWith(
    UserLookupResult value,
    $Res Function(UserLookupResult) then,
  ) = _$UserLookupResultCopyWithImpl<$Res, UserLookupResult>;
}

/// @nodoc
class _$UserLookupResultCopyWithImpl<$Res, $Val extends UserLookupResult>
    implements $UserLookupResultCopyWith<$Res> {
  _$UserLookupResultCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of UserLookupResult
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$ReturningUserImplCopyWith<$Res> {
  factory _$$ReturningUserImplCopyWith(
    _$ReturningUserImpl value,
    $Res Function(_$ReturningUserImpl) then,
  ) = __$$ReturningUserImplCopyWithImpl<$Res>;
  @useResult
  $Res call({
    String userId,
    String firstName,
    String lastName,
    String businessId,
    String businessName,
    String businessType,
    String city,
    String? businessLogo,
  });
}

/// @nodoc
class __$$ReturningUserImplCopyWithImpl<$Res>
    extends _$UserLookupResultCopyWithImpl<$Res, _$ReturningUserImpl>
    implements _$$ReturningUserImplCopyWith<$Res> {
  __$$ReturningUserImplCopyWithImpl(
    _$ReturningUserImpl _value,
    $Res Function(_$ReturningUserImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of UserLookupResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? firstName = null,
    Object? lastName = null,
    Object? businessId = null,
    Object? businessName = null,
    Object? businessType = null,
    Object? city = null,
    Object? businessLogo = freezed,
  }) {
    return _then(
      _$ReturningUserImpl(
        userId: null == userId
            ? _value.userId
            : userId // ignore: cast_nullable_to_non_nullable
                  as String,
        firstName: null == firstName
            ? _value.firstName
            : firstName // ignore: cast_nullable_to_non_nullable
                  as String,
        lastName: null == lastName
            ? _value.lastName
            : lastName // ignore: cast_nullable_to_non_nullable
                  as String,
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
        businessLogo: freezed == businessLogo
            ? _value.businessLogo
            : businessLogo // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc

class _$ReturningUserImpl implements ReturningUser {
  const _$ReturningUserImpl({
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.businessId,
    required this.businessName,
    required this.businessType,
    required this.city,
    required this.businessLogo,
  });

  @override
  final String userId;
  @override
  final String firstName;
  @override
  final String lastName;
  @override
  final String businessId;
  @override
  final String businessName;
  @override
  final String businessType;
  @override
  final String city;
  @override
  final String? businessLogo;

  @override
  String toString() {
    return 'UserLookupResult.returningUser(userId: $userId, firstName: $firstName, lastName: $lastName, businessId: $businessId, businessName: $businessName, businessType: $businessType, city: $city, businessLogo: $businessLogo)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ReturningUserImpl &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.firstName, firstName) ||
                other.firstName == firstName) &&
            (identical(other.lastName, lastName) ||
                other.lastName == lastName) &&
            (identical(other.businessId, businessId) ||
                other.businessId == businessId) &&
            (identical(other.businessName, businessName) ||
                other.businessName == businessName) &&
            (identical(other.businessType, businessType) ||
                other.businessType == businessType) &&
            (identical(other.city, city) || other.city == city) &&
            (identical(other.businessLogo, businessLogo) ||
                other.businessLogo == businessLogo));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    userId,
    firstName,
    lastName,
    businessId,
    businessName,
    businessType,
    city,
    businessLogo,
  );

  /// Create a copy of UserLookupResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ReturningUserImplCopyWith<_$ReturningUserImpl> get copyWith =>
      __$$ReturningUserImplCopyWithImpl<_$ReturningUserImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
      String userId,
      String firstName,
      String lastName,
      String businessId,
      String businessName,
      String businessType,
      String city,
      String? businessLogo,
    )
    returningUser,
    required TResult Function() newUser,
  }) {
    return returningUser(
      userId,
      firstName,
      lastName,
      businessId,
      businessName,
      businessType,
      city,
      businessLogo,
    );
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(
      String userId,
      String firstName,
      String lastName,
      String businessId,
      String businessName,
      String businessType,
      String city,
      String? businessLogo,
    )?
    returningUser,
    TResult? Function()? newUser,
  }) {
    return returningUser?.call(
      userId,
      firstName,
      lastName,
      businessId,
      businessName,
      businessType,
      city,
      businessLogo,
    );
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(
      String userId,
      String firstName,
      String lastName,
      String businessId,
      String businessName,
      String businessType,
      String city,
      String? businessLogo,
    )?
    returningUser,
    TResult Function()? newUser,
    required TResult orElse(),
  }) {
    if (returningUser != null) {
      return returningUser(
        userId,
        firstName,
        lastName,
        businessId,
        businessName,
        businessType,
        city,
        businessLogo,
      );
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(ReturningUser value) returningUser,
    required TResult Function(NewUser value) newUser,
  }) {
    return returningUser(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(ReturningUser value)? returningUser,
    TResult? Function(NewUser value)? newUser,
  }) {
    return returningUser?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(ReturningUser value)? returningUser,
    TResult Function(NewUser value)? newUser,
    required TResult orElse(),
  }) {
    if (returningUser != null) {
      return returningUser(this);
    }
    return orElse();
  }
}

abstract class ReturningUser implements UserLookupResult {
  const factory ReturningUser({
    required final String userId,
    required final String firstName,
    required final String lastName,
    required final String businessId,
    required final String businessName,
    required final String businessType,
    required final String city,
    required final String? businessLogo,
  }) = _$ReturningUserImpl;

  String get userId;
  String get firstName;
  String get lastName;
  String get businessId;
  String get businessName;
  String get businessType;
  String get city;
  String? get businessLogo;

  /// Create a copy of UserLookupResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ReturningUserImplCopyWith<_$ReturningUserImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$NewUserImplCopyWith<$Res> {
  factory _$$NewUserImplCopyWith(
    _$NewUserImpl value,
    $Res Function(_$NewUserImpl) then,
  ) = __$$NewUserImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$NewUserImplCopyWithImpl<$Res>
    extends _$UserLookupResultCopyWithImpl<$Res, _$NewUserImpl>
    implements _$$NewUserImplCopyWith<$Res> {
  __$$NewUserImplCopyWithImpl(
    _$NewUserImpl _value,
    $Res Function(_$NewUserImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of UserLookupResult
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$NewUserImpl implements NewUser {
  const _$NewUserImpl();

  @override
  String toString() {
    return 'UserLookupResult.newUser()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$NewUserImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
      String userId,
      String firstName,
      String lastName,
      String businessId,
      String businessName,
      String businessType,
      String city,
      String? businessLogo,
    )
    returningUser,
    required TResult Function() newUser,
  }) {
    return newUser();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(
      String userId,
      String firstName,
      String lastName,
      String businessId,
      String businessName,
      String businessType,
      String city,
      String? businessLogo,
    )?
    returningUser,
    TResult? Function()? newUser,
  }) {
    return newUser?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(
      String userId,
      String firstName,
      String lastName,
      String businessId,
      String businessName,
      String businessType,
      String city,
      String? businessLogo,
    )?
    returningUser,
    TResult Function()? newUser,
    required TResult orElse(),
  }) {
    if (newUser != null) {
      return newUser();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(ReturningUser value) returningUser,
    required TResult Function(NewUser value) newUser,
  }) {
    return newUser(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(ReturningUser value)? returningUser,
    TResult? Function(NewUser value)? newUser,
  }) {
    return newUser?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(ReturningUser value)? returningUser,
    TResult Function(NewUser value)? newUser,
    required TResult orElse(),
  }) {
    if (newUser != null) {
      return newUser(this);
    }
    return orElse();
  }
}

abstract class NewUser implements UserLookupResult {
  const factory NewUser() = _$NewUserImpl;
}
