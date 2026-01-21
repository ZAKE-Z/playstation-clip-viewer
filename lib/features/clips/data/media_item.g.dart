// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'media_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MediaItem _$MediaItemFromJson(Map<String, dynamic> json) => _MediaItem(
  id: json['id'] as String,
  title: json['title'] as String,
  scePlatform: json['scePlatform'] as String,
  sceTitleName: json['sceTitleName'] as String,
  uploadDate: json['uploadDate'] as String,
  ugcType: $enumDecode(_$MediaTypeEnumMap, json['ugcType']),
  smallPreviewImage: json['smallPreviewImage'] as String,
  largePreviewImage: json['largePreviewImage'] as String,
  videoDuration: (json['videoDuration'] as num?)?.toDouble(),
  videoUrl: json['videoUrl'] as String?,
  screenshotUrl: json['screenshotUrl'] as String?,
  downloadUrl: json['downloadUrl'] as String?,
  fileSize: (json['fileSize'] as num?)?.toInt(),
  resolution: json['resolution'] as String?,
);

Map<String, dynamic> _$MediaItemToJson(_MediaItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'scePlatform': instance.scePlatform,
      'sceTitleName': instance.sceTitleName,
      'uploadDate': instance.uploadDate,
      'ugcType': _$MediaTypeEnumMap[instance.ugcType]!,
      'smallPreviewImage': instance.smallPreviewImage,
      'largePreviewImage': instance.largePreviewImage,
      'videoDuration': instance.videoDuration,
      'videoUrl': instance.videoUrl,
      'screenshotUrl': instance.screenshotUrl,
      'downloadUrl': instance.downloadUrl,
      'fileSize': instance.fileSize,
      'resolution': instance.resolution,
    };

const _$MediaTypeEnumMap = {MediaType.screenshot: 1, MediaType.video: 2};
