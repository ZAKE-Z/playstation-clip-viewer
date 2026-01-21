// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'media_gallery_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MediaGalleryResponse _$MediaGalleryResponseFromJson(
  Map<String, dynamic> json,
) => _MediaGalleryResponse(
  ugcDocument: (json['ugcDocument'] as List<dynamic>)
      .map((e) => MediaItem.fromJson(e as Map<String, dynamic>))
      .toList(),
  nextCursorMark: json['nextCursorMark'] as String?,
  limit: (json['limit'] as num?)?.toInt(),
);

Map<String, dynamic> _$MediaGalleryResponseToJson(
  _MediaGalleryResponse instance,
) => <String, dynamic>{
  'ugcDocument': instance.ugcDocument,
  'nextCursorMark': instance.nextCursorMark,
  'limit': instance.limit,
};
