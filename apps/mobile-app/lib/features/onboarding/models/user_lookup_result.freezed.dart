// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_lookup_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$UserLookupResult {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserLookupResult);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'UserLookupResult()';
}


}

/// @nodoc
class $UserLookupResultCopyWith<$Res>  {
$UserLookupResultCopyWith(UserLookupResult _, $Res Function(UserLookupResult) __);
}


/// Adds pattern-matching-related methods to [UserLookupResult].
extension UserLookupResultPatterns on UserLookupResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ReturningUser value)?  returningUser,TResult Function( NewUser value)?  newUser,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ReturningUser() when returningUser != null:
return returningUser(_that);case NewUser() when newUser != null:
return newUser(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ReturningUser value)  returningUser,required TResult Function( NewUser value)  newUser,}){
final _that = this;
switch (_that) {
case ReturningUser():
return returningUser(_that);case NewUser():
return newUser(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ReturningUser value)?  returningUser,TResult? Function( NewUser value)?  newUser,}){
final _that = this;
switch (_that) {
case ReturningUser() when returningUser != null:
return returningUser(_that);case NewUser() when newUser != null:
return newUser(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String userId,  String firstName,  String lastName,  String businessId,  String businessName,  String businessType,  String city,  String? businessLogo)?  returningUser,TResult Function()?  newUser,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ReturningUser() when returningUser != null:
return returningUser(_that.userId,_that.firstName,_that.lastName,_that.businessId,_that.businessName,_that.businessType,_that.city,_that.businessLogo);case NewUser() when newUser != null:
return newUser();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String userId,  String firstName,  String lastName,  String businessId,  String businessName,  String businessType,  String city,  String? businessLogo)  returningUser,required TResult Function()  newUser,}) {final _that = this;
switch (_that) {
case ReturningUser():
return returningUser(_that.userId,_that.firstName,_that.lastName,_that.businessId,_that.businessName,_that.businessType,_that.city,_that.businessLogo);case NewUser():
return newUser();case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String userId,  String firstName,  String lastName,  String businessId,  String businessName,  String businessType,  String city,  String? businessLogo)?  returningUser,TResult? Function()?  newUser,}) {final _that = this;
switch (_that) {
case ReturningUser() when returningUser != null:
return returningUser(_that.userId,_that.firstName,_that.lastName,_that.businessId,_that.businessName,_that.businessType,_that.city,_that.businessLogo);case NewUser() when newUser != null:
return newUser();case _:
  return null;

}
}

}

/// @nodoc


class ReturningUser implements UserLookupResult {
  const ReturningUser({required this.userId, required this.firstName, required this.lastName, required this.businessId, required this.businessName, required this.businessType, required this.city, required this.businessLogo});
  

 final  String userId;
 final  String firstName;
 final  String lastName;
 final  String businessId;
 final  String businessName;
 final  String businessType;
 final  String city;
 final  String? businessLogo;

/// Create a copy of UserLookupResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReturningUserCopyWith<ReturningUser> get copyWith => _$ReturningUserCopyWithImpl<ReturningUser>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReturningUser&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.firstName, firstName) || other.firstName == firstName)&&(identical(other.lastName, lastName) || other.lastName == lastName)&&(identical(other.businessId, businessId) || other.businessId == businessId)&&(identical(other.businessName, businessName) || other.businessName == businessName)&&(identical(other.businessType, businessType) || other.businessType == businessType)&&(identical(other.city, city) || other.city == city)&&(identical(other.businessLogo, businessLogo) || other.businessLogo == businessLogo));
}


@override
int get hashCode => Object.hash(runtimeType,userId,firstName,lastName,businessId,businessName,businessType,city,businessLogo);

@override
String toString() {
  return 'UserLookupResult.returningUser(userId: $userId, firstName: $firstName, lastName: $lastName, businessId: $businessId, businessName: $businessName, businessType: $businessType, city: $city, businessLogo: $businessLogo)';
}


}

/// @nodoc
abstract mixin class $ReturningUserCopyWith<$Res> implements $UserLookupResultCopyWith<$Res> {
  factory $ReturningUserCopyWith(ReturningUser value, $Res Function(ReturningUser) _then) = _$ReturningUserCopyWithImpl;
@useResult
$Res call({
 String userId, String firstName, String lastName, String businessId, String businessName, String businessType, String city, String? businessLogo
});




}
/// @nodoc
class _$ReturningUserCopyWithImpl<$Res>
    implements $ReturningUserCopyWith<$Res> {
  _$ReturningUserCopyWithImpl(this._self, this._then);

  final ReturningUser _self;
  final $Res Function(ReturningUser) _then;

/// Create a copy of UserLookupResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? userId = null,Object? firstName = null,Object? lastName = null,Object? businessId = null,Object? businessName = null,Object? businessType = null,Object? city = null,Object? businessLogo = freezed,}) {
  return _then(ReturningUser(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,firstName: null == firstName ? _self.firstName : firstName // ignore: cast_nullable_to_non_nullable
as String,lastName: null == lastName ? _self.lastName : lastName // ignore: cast_nullable_to_non_nullable
as String,businessId: null == businessId ? _self.businessId : businessId // ignore: cast_nullable_to_non_nullable
as String,businessName: null == businessName ? _self.businessName : businessName // ignore: cast_nullable_to_non_nullable
as String,businessType: null == businessType ? _self.businessType : businessType // ignore: cast_nullable_to_non_nullable
as String,city: null == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String,businessLogo: freezed == businessLogo ? _self.businessLogo : businessLogo // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class NewUser implements UserLookupResult {
  const NewUser();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NewUser);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'UserLookupResult.newUser()';
}


}




// dart format on
