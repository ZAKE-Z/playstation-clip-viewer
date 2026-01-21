import 'package:freezed_annotation/freezed_annotation.dart';
import 'media_item.dart';

part 'media_gallery_response.freezed.dart';
part 'media_gallery_response.g.dart';

/// Response from PSN media gallery API
@freezed
sealed class MediaGalleryResponse with _$MediaGalleryResponse {
  const factory MediaGalleryResponse({
    required List<MediaItem> ugcDocument,
    String? nextCursorMark,
    int? limit,
  }) = _MediaGalleryResponse;

  factory MediaGalleryResponse.fromJson(Map<String, dynamic> json) =>
      _$MediaGalleryResponseFromJson(json);
}

/// Extension for convenience getters
extension MediaGalleryResponseX on MediaGalleryResponse {
  /// Get the items list
  List<MediaItem> get items => ugcDocument;

  /// Get the next cursor for pagination
  String? get nextCursor => nextCursorMark;
}
