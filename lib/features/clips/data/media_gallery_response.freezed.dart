// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'media_gallery_response.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MediaGalleryResponse {

 List<MediaItem> get ugcDocument; String? get nextCursorMark; int? get limit;
/// Create a copy of MediaGalleryResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MediaGalleryResponseCopyWith<MediaGalleryResponse> get copyWith => _$MediaGalleryResponseCopyWithImpl<MediaGalleryResponse>(this as MediaGalleryResponse, _$identity);

  /// Serializes this MediaGalleryResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MediaGalleryResponse&&const DeepCollectionEquality().equals(other.ugcDocument, ugcDocument)&&(identical(other.nextCursorMark, nextCursorMark) || other.nextCursorMark == nextCursorMark)&&(identical(other.limit, limit) || other.limit == limit));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(ugcDocument),nextCursorMark,limit);

@override
String toString() {
  return 'MediaGalleryResponse(ugcDocument: $ugcDocument, nextCursorMark: $nextCursorMark, limit: $limit)';
}


}

/// @nodoc
abstract mixin class $MediaGalleryResponseCopyWith<$Res>  {
  factory $MediaGalleryResponseCopyWith(MediaGalleryResponse value, $Res Function(MediaGalleryResponse) _then) = _$MediaGalleryResponseCopyWithImpl;
@useResult
$Res call({
 List<MediaItem> ugcDocument, String? nextCursorMark, int? limit
});




}
/// @nodoc
class _$MediaGalleryResponseCopyWithImpl<$Res>
    implements $MediaGalleryResponseCopyWith<$Res> {
  _$MediaGalleryResponseCopyWithImpl(this._self, this._then);

  final MediaGalleryResponse _self;
  final $Res Function(MediaGalleryResponse) _then;

/// Create a copy of MediaGalleryResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? ugcDocument = null,Object? nextCursorMark = freezed,Object? limit = freezed,}) {
  return _then(_self.copyWith(
ugcDocument: null == ugcDocument ? _self.ugcDocument : ugcDocument // ignore: cast_nullable_to_non_nullable
as List<MediaItem>,nextCursorMark: freezed == nextCursorMark ? _self.nextCursorMark : nextCursorMark // ignore: cast_nullable_to_non_nullable
as String?,limit: freezed == limit ? _self.limit : limit // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [MediaGalleryResponse].
extension MediaGalleryResponsePatterns on MediaGalleryResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MediaGalleryResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MediaGalleryResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MediaGalleryResponse value)  $default,){
final _that = this;
switch (_that) {
case _MediaGalleryResponse():
return $default(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MediaGalleryResponse value)?  $default,){
final _that = this;
switch (_that) {
case _MediaGalleryResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<MediaItem> ugcDocument,  String? nextCursorMark,  int? limit)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MediaGalleryResponse() when $default != null:
return $default(_that.ugcDocument,_that.nextCursorMark,_that.limit);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<MediaItem> ugcDocument,  String? nextCursorMark,  int? limit)  $default,) {final _that = this;
switch (_that) {
case _MediaGalleryResponse():
return $default(_that.ugcDocument,_that.nextCursorMark,_that.limit);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<MediaItem> ugcDocument,  String? nextCursorMark,  int? limit)?  $default,) {final _that = this;
switch (_that) {
case _MediaGalleryResponse() when $default != null:
return $default(_that.ugcDocument,_that.nextCursorMark,_that.limit);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MediaGalleryResponse implements MediaGalleryResponse {
  const _MediaGalleryResponse({required final  List<MediaItem> ugcDocument, this.nextCursorMark, this.limit}): _ugcDocument = ugcDocument;
  factory _MediaGalleryResponse.fromJson(Map<String, dynamic> json) => _$MediaGalleryResponseFromJson(json);

 final  List<MediaItem> _ugcDocument;
@override List<MediaItem> get ugcDocument {
  if (_ugcDocument is EqualUnmodifiableListView) return _ugcDocument;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_ugcDocument);
}

@override final  String? nextCursorMark;
@override final  int? limit;

/// Create a copy of MediaGalleryResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MediaGalleryResponseCopyWith<_MediaGalleryResponse> get copyWith => __$MediaGalleryResponseCopyWithImpl<_MediaGalleryResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MediaGalleryResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MediaGalleryResponse&&const DeepCollectionEquality().equals(other._ugcDocument, _ugcDocument)&&(identical(other.nextCursorMark, nextCursorMark) || other.nextCursorMark == nextCursorMark)&&(identical(other.limit, limit) || other.limit == limit));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_ugcDocument),nextCursorMark,limit);

@override
String toString() {
  return 'MediaGalleryResponse(ugcDocument: $ugcDocument, nextCursorMark: $nextCursorMark, limit: $limit)';
}


}

/// @nodoc
abstract mixin class _$MediaGalleryResponseCopyWith<$Res> implements $MediaGalleryResponseCopyWith<$Res> {
  factory _$MediaGalleryResponseCopyWith(_MediaGalleryResponse value, $Res Function(_MediaGalleryResponse) _then) = __$MediaGalleryResponseCopyWithImpl;
@override @useResult
$Res call({
 List<MediaItem> ugcDocument, String? nextCursorMark, int? limit
});




}
/// @nodoc
class __$MediaGalleryResponseCopyWithImpl<$Res>
    implements _$MediaGalleryResponseCopyWith<$Res> {
  __$MediaGalleryResponseCopyWithImpl(this._self, this._then);

  final _MediaGalleryResponse _self;
  final $Res Function(_MediaGalleryResponse) _then;

/// Create a copy of MediaGalleryResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? ugcDocument = null,Object? nextCursorMark = freezed,Object? limit = freezed,}) {
  return _then(_MediaGalleryResponse(
ugcDocument: null == ugcDocument ? _self._ugcDocument : ugcDocument // ignore: cast_nullable_to_non_nullable
as List<MediaItem>,nextCursorMark: freezed == nextCursorMark ? _self.nextCursorMark : nextCursorMark // ignore: cast_nullable_to_non_nullable
as String?,limit: freezed == limit ? _self.limit : limit // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
