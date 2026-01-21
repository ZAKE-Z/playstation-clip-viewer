// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'media_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MediaItem {

 String get id; String get title; String get scePlatform; String get sceTitleName; String get uploadDate; MediaType get ugcType; String get smallPreviewImage; String get largePreviewImage; double? get videoDuration; String? get videoUrl; String? get screenshotUrl; String? get downloadUrl; int? get fileSize; String? get resolution;
/// Create a copy of MediaItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MediaItemCopyWith<MediaItem> get copyWith => _$MediaItemCopyWithImpl<MediaItem>(this as MediaItem, _$identity);

  /// Serializes this MediaItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MediaItem&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.scePlatform, scePlatform) || other.scePlatform == scePlatform)&&(identical(other.sceTitleName, sceTitleName) || other.sceTitleName == sceTitleName)&&(identical(other.uploadDate, uploadDate) || other.uploadDate == uploadDate)&&(identical(other.ugcType, ugcType) || other.ugcType == ugcType)&&(identical(other.smallPreviewImage, smallPreviewImage) || other.smallPreviewImage == smallPreviewImage)&&(identical(other.largePreviewImage, largePreviewImage) || other.largePreviewImage == largePreviewImage)&&(identical(other.videoDuration, videoDuration) || other.videoDuration == videoDuration)&&(identical(other.videoUrl, videoUrl) || other.videoUrl == videoUrl)&&(identical(other.screenshotUrl, screenshotUrl) || other.screenshotUrl == screenshotUrl)&&(identical(other.downloadUrl, downloadUrl) || other.downloadUrl == downloadUrl)&&(identical(other.fileSize, fileSize) || other.fileSize == fileSize)&&(identical(other.resolution, resolution) || other.resolution == resolution));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,scePlatform,sceTitleName,uploadDate,ugcType,smallPreviewImage,largePreviewImage,videoDuration,videoUrl,screenshotUrl,downloadUrl,fileSize,resolution);

@override
String toString() {
  return 'MediaItem(id: $id, title: $title, scePlatform: $scePlatform, sceTitleName: $sceTitleName, uploadDate: $uploadDate, ugcType: $ugcType, smallPreviewImage: $smallPreviewImage, largePreviewImage: $largePreviewImage, videoDuration: $videoDuration, videoUrl: $videoUrl, screenshotUrl: $screenshotUrl, downloadUrl: $downloadUrl, fileSize: $fileSize, resolution: $resolution)';
}


}

/// @nodoc
abstract mixin class $MediaItemCopyWith<$Res>  {
  factory $MediaItemCopyWith(MediaItem value, $Res Function(MediaItem) _then) = _$MediaItemCopyWithImpl;
@useResult
$Res call({
 String id, String title, String scePlatform, String sceTitleName, String uploadDate, MediaType ugcType, String smallPreviewImage, String largePreviewImage, double? videoDuration, String? videoUrl, String? screenshotUrl, String? downloadUrl, int? fileSize, String? resolution
});




}
/// @nodoc
class _$MediaItemCopyWithImpl<$Res>
    implements $MediaItemCopyWith<$Res> {
  _$MediaItemCopyWithImpl(this._self, this._then);

  final MediaItem _self;
  final $Res Function(MediaItem) _then;

/// Create a copy of MediaItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? scePlatform = null,Object? sceTitleName = null,Object? uploadDate = null,Object? ugcType = null,Object? smallPreviewImage = null,Object? largePreviewImage = null,Object? videoDuration = freezed,Object? videoUrl = freezed,Object? screenshotUrl = freezed,Object? downloadUrl = freezed,Object? fileSize = freezed,Object? resolution = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,scePlatform: null == scePlatform ? _self.scePlatform : scePlatform // ignore: cast_nullable_to_non_nullable
as String,sceTitleName: null == sceTitleName ? _self.sceTitleName : sceTitleName // ignore: cast_nullable_to_non_nullable
as String,uploadDate: null == uploadDate ? _self.uploadDate : uploadDate // ignore: cast_nullable_to_non_nullable
as String,ugcType: null == ugcType ? _self.ugcType : ugcType // ignore: cast_nullable_to_non_nullable
as MediaType,smallPreviewImage: null == smallPreviewImage ? _self.smallPreviewImage : smallPreviewImage // ignore: cast_nullable_to_non_nullable
as String,largePreviewImage: null == largePreviewImage ? _self.largePreviewImage : largePreviewImage // ignore: cast_nullable_to_non_nullable
as String,videoDuration: freezed == videoDuration ? _self.videoDuration : videoDuration // ignore: cast_nullable_to_non_nullable
as double?,videoUrl: freezed == videoUrl ? _self.videoUrl : videoUrl // ignore: cast_nullable_to_non_nullable
as String?,screenshotUrl: freezed == screenshotUrl ? _self.screenshotUrl : screenshotUrl // ignore: cast_nullable_to_non_nullable
as String?,downloadUrl: freezed == downloadUrl ? _self.downloadUrl : downloadUrl // ignore: cast_nullable_to_non_nullable
as String?,fileSize: freezed == fileSize ? _self.fileSize : fileSize // ignore: cast_nullable_to_non_nullable
as int?,resolution: freezed == resolution ? _self.resolution : resolution // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [MediaItem].
extension MediaItemPatterns on MediaItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MediaItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MediaItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MediaItem value)  $default,){
final _that = this;
switch (_that) {
case _MediaItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MediaItem value)?  $default,){
final _that = this;
switch (_that) {
case _MediaItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  String scePlatform,  String sceTitleName,  String uploadDate,  MediaType ugcType,  String smallPreviewImage,  String largePreviewImage,  double? videoDuration,  String? videoUrl,  String? screenshotUrl,  String? downloadUrl,  int? fileSize,  String? resolution)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MediaItem() when $default != null:
return $default(_that.id,_that.title,_that.scePlatform,_that.sceTitleName,_that.uploadDate,_that.ugcType,_that.smallPreviewImage,_that.largePreviewImage,_that.videoDuration,_that.videoUrl,_that.screenshotUrl,_that.downloadUrl,_that.fileSize,_that.resolution);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  String scePlatform,  String sceTitleName,  String uploadDate,  MediaType ugcType,  String smallPreviewImage,  String largePreviewImage,  double? videoDuration,  String? videoUrl,  String? screenshotUrl,  String? downloadUrl,  int? fileSize,  String? resolution)  $default,) {final _that = this;
switch (_that) {
case _MediaItem():
return $default(_that.id,_that.title,_that.scePlatform,_that.sceTitleName,_that.uploadDate,_that.ugcType,_that.smallPreviewImage,_that.largePreviewImage,_that.videoDuration,_that.videoUrl,_that.screenshotUrl,_that.downloadUrl,_that.fileSize,_that.resolution);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  String scePlatform,  String sceTitleName,  String uploadDate,  MediaType ugcType,  String smallPreviewImage,  String largePreviewImage,  double? videoDuration,  String? videoUrl,  String? screenshotUrl,  String? downloadUrl,  int? fileSize,  String? resolution)?  $default,) {final _that = this;
switch (_that) {
case _MediaItem() when $default != null:
return $default(_that.id,_that.title,_that.scePlatform,_that.sceTitleName,_that.uploadDate,_that.ugcType,_that.smallPreviewImage,_that.largePreviewImage,_that.videoDuration,_that.videoUrl,_that.screenshotUrl,_that.downloadUrl,_that.fileSize,_that.resolution);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MediaItem implements MediaItem {
  const _MediaItem({required this.id, required this.title, required this.scePlatform, required this.sceTitleName, required this.uploadDate, required this.ugcType, required this.smallPreviewImage, required this.largePreviewImage, this.videoDuration, this.videoUrl, this.screenshotUrl, this.downloadUrl, this.fileSize, this.resolution});
  factory _MediaItem.fromJson(Map<String, dynamic> json) => _$MediaItemFromJson(json);

@override final  String id;
@override final  String title;
@override final  String scePlatform;
@override final  String sceTitleName;
@override final  String uploadDate;
@override final  MediaType ugcType;
@override final  String smallPreviewImage;
@override final  String largePreviewImage;
@override final  double? videoDuration;
@override final  String? videoUrl;
@override final  String? screenshotUrl;
@override final  String? downloadUrl;
@override final  int? fileSize;
@override final  String? resolution;

/// Create a copy of MediaItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MediaItemCopyWith<_MediaItem> get copyWith => __$MediaItemCopyWithImpl<_MediaItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MediaItemToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MediaItem&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.scePlatform, scePlatform) || other.scePlatform == scePlatform)&&(identical(other.sceTitleName, sceTitleName) || other.sceTitleName == sceTitleName)&&(identical(other.uploadDate, uploadDate) || other.uploadDate == uploadDate)&&(identical(other.ugcType, ugcType) || other.ugcType == ugcType)&&(identical(other.smallPreviewImage, smallPreviewImage) || other.smallPreviewImage == smallPreviewImage)&&(identical(other.largePreviewImage, largePreviewImage) || other.largePreviewImage == largePreviewImage)&&(identical(other.videoDuration, videoDuration) || other.videoDuration == videoDuration)&&(identical(other.videoUrl, videoUrl) || other.videoUrl == videoUrl)&&(identical(other.screenshotUrl, screenshotUrl) || other.screenshotUrl == screenshotUrl)&&(identical(other.downloadUrl, downloadUrl) || other.downloadUrl == downloadUrl)&&(identical(other.fileSize, fileSize) || other.fileSize == fileSize)&&(identical(other.resolution, resolution) || other.resolution == resolution));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,scePlatform,sceTitleName,uploadDate,ugcType,smallPreviewImage,largePreviewImage,videoDuration,videoUrl,screenshotUrl,downloadUrl,fileSize,resolution);

@override
String toString() {
  return 'MediaItem(id: $id, title: $title, scePlatform: $scePlatform, sceTitleName: $sceTitleName, uploadDate: $uploadDate, ugcType: $ugcType, smallPreviewImage: $smallPreviewImage, largePreviewImage: $largePreviewImage, videoDuration: $videoDuration, videoUrl: $videoUrl, screenshotUrl: $screenshotUrl, downloadUrl: $downloadUrl, fileSize: $fileSize, resolution: $resolution)';
}


}

/// @nodoc
abstract mixin class _$MediaItemCopyWith<$Res> implements $MediaItemCopyWith<$Res> {
  factory _$MediaItemCopyWith(_MediaItem value, $Res Function(_MediaItem) _then) = __$MediaItemCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, String scePlatform, String sceTitleName, String uploadDate, MediaType ugcType, String smallPreviewImage, String largePreviewImage, double? videoDuration, String? videoUrl, String? screenshotUrl, String? downloadUrl, int? fileSize, String? resolution
});




}
/// @nodoc
class __$MediaItemCopyWithImpl<$Res>
    implements _$MediaItemCopyWith<$Res> {
  __$MediaItemCopyWithImpl(this._self, this._then);

  final _MediaItem _self;
  final $Res Function(_MediaItem) _then;

/// Create a copy of MediaItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? scePlatform = null,Object? sceTitleName = null,Object? uploadDate = null,Object? ugcType = null,Object? smallPreviewImage = null,Object? largePreviewImage = null,Object? videoDuration = freezed,Object? videoUrl = freezed,Object? screenshotUrl = freezed,Object? downloadUrl = freezed,Object? fileSize = freezed,Object? resolution = freezed,}) {
  return _then(_MediaItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,scePlatform: null == scePlatform ? _self.scePlatform : scePlatform // ignore: cast_nullable_to_non_nullable
as String,sceTitleName: null == sceTitleName ? _self.sceTitleName : sceTitleName // ignore: cast_nullable_to_non_nullable
as String,uploadDate: null == uploadDate ? _self.uploadDate : uploadDate // ignore: cast_nullable_to_non_nullable
as String,ugcType: null == ugcType ? _self.ugcType : ugcType // ignore: cast_nullable_to_non_nullable
as MediaType,smallPreviewImage: null == smallPreviewImage ? _self.smallPreviewImage : smallPreviewImage // ignore: cast_nullable_to_non_nullable
as String,largePreviewImage: null == largePreviewImage ? _self.largePreviewImage : largePreviewImage // ignore: cast_nullable_to_non_nullable
as String,videoDuration: freezed == videoDuration ? _self.videoDuration : videoDuration // ignore: cast_nullable_to_non_nullable
as double?,videoUrl: freezed == videoUrl ? _self.videoUrl : videoUrl // ignore: cast_nullable_to_non_nullable
as String?,screenshotUrl: freezed == screenshotUrl ? _self.screenshotUrl : screenshotUrl // ignore: cast_nullable_to_non_nullable
as String?,downloadUrl: freezed == downloadUrl ? _self.downloadUrl : downloadUrl // ignore: cast_nullable_to_non_nullable
as String?,fileSize: freezed == fileSize ? _self.fileSize : fileSize // ignore: cast_nullable_to_non_nullable
as int?,resolution: freezed == resolution ? _self.resolution : resolution // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
