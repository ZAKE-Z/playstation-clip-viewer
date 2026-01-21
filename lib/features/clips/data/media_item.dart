import 'package:freezed_annotation/freezed_annotation.dart';

part 'media_item.freezed.dart';
part 'media_item.g.dart';

/// Type of media content
enum MediaType {
  @JsonValue(1)
  screenshot,
  @JsonValue(2)
  video,
}

/// A single clip or screenshot from PlayStation
@freezed
sealed class MediaItem with _$MediaItem {
  const factory MediaItem({
    required String id,
    required String title,
    required String scePlatform,
    required String sceTitleName,
    required String uploadDate,
    required MediaType ugcType,
    required String smallPreviewImage,
    required String largePreviewImage,
    double? videoDuration,
    String? videoUrl,
    String? screenshotUrl,
    String? downloadUrl,
    int? fileSize,
    String? resolution,
  }) = _MediaItem;

  factory MediaItem.fromJson(Map<String, dynamic> json) =>
      _$MediaItemFromJson(json);
}

/// Extension for convenience getters
extension MediaItemX on MediaItem {
  /// Get the media type as enum
  MediaType get mediaType => ugcType;

  /// Get the platform
  String get platform => scePlatform;

  /// Get the game name
  String get gameName => sceTitleName;

  /// Get the thumbnail URL
  String get thumbnailUrl => smallPreviewImage;

  /// Get the preview URL
  String get previewUrl => largePreviewImage;
}
