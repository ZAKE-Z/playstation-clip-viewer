---
phase: 3
plan: 1
wave: 1
---

# Plan 3.1: Media Data Models

## Objective
Create Freezed data models for PSN media items and API responses. This is foundational for the API service and UI.

## Context
- .gsd/phases/3/RESEARCH.md
- old/server/psn-types.py (reference for field structure)
- lib/features/auth/data/token_model.dart (pattern to follow)

## Tasks

<task type="auto">
  <name>Create media item model</name>
  <files>lib/features/clips/data/media_item.dart</files>
  <action>
    Create lib/features/clips/data/media_item.dart with Freezed:
    
    ```dart
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
    abstract class MediaItem with _$MediaItem {
      const factory MediaItem({
        required String id,
        required String title,
        @JsonKey(name: 'scePlatform') required String platform,
        @JsonKey(name: 'sceTitleName') required String gameName,
        @JsonKey(name: 'uploadDate') required String uploadDate,
        @JsonKey(name: 'ugcType') required MediaType mediaType,
        @JsonKey(name: 'smallPreviewImage') required String thumbnailUrl,
        @JsonKey(name: 'largePreviewImage') required String previewUrl,
        @JsonKey(name: 'videoDuration') double? videoDuration,
        @JsonKey(name: 'videoUrl') String? videoUrl,
        @JsonKey(name: 'screenshotUrl') String? screenshotUrl,
        @JsonKey(name: 'downloadUrl') String? downloadUrl,
        @JsonKey(name: 'fileSize') int? fileSize,
        String? resolution,
      }) = _MediaItem;
    
      factory MediaItem.fromJson(Map<String, dynamic> json) =>
          _$MediaItemFromJson(json);
    }
    ```
  </action>
  <verify>dart analyze lib/features/clips/data/media_item.dart</verify>
  <done>media_item.dart created with all PSN fields mapped</done>
</task>

<task type="auto">
  <name>Create media gallery response model</name>
  <files>lib/features/clips/data/media_gallery_response.dart</files>
  <action>
    Create lib/features/clips/data/media_gallery_response.dart:
    
    ```dart
    import 'package:freezed_annotation/freezed_annotation.dart';
    import 'media_item.dart';
    
    part 'media_gallery_response.freezed.dart';
    part 'media_gallery_response.g.dart';
    
    /// Response from PSN media gallery API
    @freezed
    abstract class MediaGalleryResponse with _$MediaGalleryResponse {
      const factory MediaGalleryResponse({
        @JsonKey(name: 'ugcDocument') required List<MediaItem> items,
        @JsonKey(name: 'nextCursorMark') String? nextCursor,
        int? limit,
      }) = _MediaGalleryResponse;
    
      factory MediaGalleryResponse.fromJson(Map<String, dynamic> json) =>
          _$MediaGalleryResponseFromJson(json);
    }
    ```
  </action>
  <verify>dart run build_runner build --delete-conflicting-outputs</verify>
  <done>Both models generated with freezed, no build errors</done>
</task>

## Success Criteria
- [ ] MediaItem model with all PSN fields
- [ ] MediaGalleryResponse model for pagination
- [ ] Build runner generates .freezed.dart and .g.dart files
- [ ] `dart analyze lib/` passes
