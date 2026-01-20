// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'token_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PsnTokens {

 String get accessToken; String get refreshToken; DateTime get expiresAt; DateTime get refreshExpiresAt;
/// Create a copy of PsnTokens
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PsnTokensCopyWith<PsnTokens> get copyWith => _$PsnTokensCopyWithImpl<PsnTokens>(this as PsnTokens, _$identity);

  /// Serializes this PsnTokens to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PsnTokens&&(identical(other.accessToken, accessToken) || other.accessToken == accessToken)&&(identical(other.refreshToken, refreshToken) || other.refreshToken == refreshToken)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.refreshExpiresAt, refreshExpiresAt) || other.refreshExpiresAt == refreshExpiresAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,accessToken,refreshToken,expiresAt,refreshExpiresAt);

@override
String toString() {
  return 'PsnTokens(accessToken: $accessToken, refreshToken: $refreshToken, expiresAt: $expiresAt, refreshExpiresAt: $refreshExpiresAt)';
}


}

/// @nodoc
abstract mixin class $PsnTokensCopyWith<$Res>  {
  factory $PsnTokensCopyWith(PsnTokens value, $Res Function(PsnTokens) _then) = _$PsnTokensCopyWithImpl;
@useResult
$Res call({
 String accessToken, String refreshToken, DateTime expiresAt, DateTime refreshExpiresAt
});




}
/// @nodoc
class _$PsnTokensCopyWithImpl<$Res>
    implements $PsnTokensCopyWith<$Res> {
  _$PsnTokensCopyWithImpl(this._self, this._then);

  final PsnTokens _self;
  final $Res Function(PsnTokens) _then;

/// Create a copy of PsnTokens
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? accessToken = null,Object? refreshToken = null,Object? expiresAt = null,Object? refreshExpiresAt = null,}) {
  return _then(_self.copyWith(
accessToken: null == accessToken ? _self.accessToken : accessToken // ignore: cast_nullable_to_non_nullable
as String,refreshToken: null == refreshToken ? _self.refreshToken : refreshToken // ignore: cast_nullable_to_non_nullable
as String,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,refreshExpiresAt: null == refreshExpiresAt ? _self.refreshExpiresAt : refreshExpiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [PsnTokens].
extension PsnTokensPatterns on PsnTokens {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PsnTokens value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PsnTokens() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PsnTokens value)  $default,){
final _that = this;
switch (_that) {
case _PsnTokens():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PsnTokens value)?  $default,){
final _that = this;
switch (_that) {
case _PsnTokens() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String accessToken,  String refreshToken,  DateTime expiresAt,  DateTime refreshExpiresAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PsnTokens() when $default != null:
return $default(_that.accessToken,_that.refreshToken,_that.expiresAt,_that.refreshExpiresAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String accessToken,  String refreshToken,  DateTime expiresAt,  DateTime refreshExpiresAt)  $default,) {final _that = this;
switch (_that) {
case _PsnTokens():
return $default(_that.accessToken,_that.refreshToken,_that.expiresAt,_that.refreshExpiresAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String accessToken,  String refreshToken,  DateTime expiresAt,  DateTime refreshExpiresAt)?  $default,) {final _that = this;
switch (_that) {
case _PsnTokens() when $default != null:
return $default(_that.accessToken,_that.refreshToken,_that.expiresAt,_that.refreshExpiresAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PsnTokens implements PsnTokens {
  const _PsnTokens({required this.accessToken, required this.refreshToken, required this.expiresAt, required this.refreshExpiresAt});
  factory _PsnTokens.fromJson(Map<String, dynamic> json) => _$PsnTokensFromJson(json);

@override final  String accessToken;
@override final  String refreshToken;
@override final  DateTime expiresAt;
@override final  DateTime refreshExpiresAt;

/// Create a copy of PsnTokens
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PsnTokensCopyWith<_PsnTokens> get copyWith => __$PsnTokensCopyWithImpl<_PsnTokens>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PsnTokensToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PsnTokens&&(identical(other.accessToken, accessToken) || other.accessToken == accessToken)&&(identical(other.refreshToken, refreshToken) || other.refreshToken == refreshToken)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.refreshExpiresAt, refreshExpiresAt) || other.refreshExpiresAt == refreshExpiresAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,accessToken,refreshToken,expiresAt,refreshExpiresAt);

@override
String toString() {
  return 'PsnTokens(accessToken: $accessToken, refreshToken: $refreshToken, expiresAt: $expiresAt, refreshExpiresAt: $refreshExpiresAt)';
}


}

/// @nodoc
abstract mixin class _$PsnTokensCopyWith<$Res> implements $PsnTokensCopyWith<$Res> {
  factory _$PsnTokensCopyWith(_PsnTokens value, $Res Function(_PsnTokens) _then) = __$PsnTokensCopyWithImpl;
@override @useResult
$Res call({
 String accessToken, String refreshToken, DateTime expiresAt, DateTime refreshExpiresAt
});




}
/// @nodoc
class __$PsnTokensCopyWithImpl<$Res>
    implements _$PsnTokensCopyWith<$Res> {
  __$PsnTokensCopyWithImpl(this._self, this._then);

  final _PsnTokens _self;
  final $Res Function(_PsnTokens) _then;

/// Create a copy of PsnTokens
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? accessToken = null,Object? refreshToken = null,Object? expiresAt = null,Object? refreshExpiresAt = null,}) {
  return _then(_PsnTokens(
accessToken: null == accessToken ? _self.accessToken : accessToken // ignore: cast_nullable_to_non_nullable
as String,refreshToken: null == refreshToken ? _self.refreshToken : refreshToken // ignore: cast_nullable_to_non_nullable
as String,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,refreshExpiresAt: null == refreshExpiresAt ? _self.refreshExpiresAt : refreshExpiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
