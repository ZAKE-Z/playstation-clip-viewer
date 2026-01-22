---
phase: 3
plan: 3
wave: 2
---

# Plan 3.3: Gallery UI

## Objective
Create the gallery screen with a grid of media thumbnails. Includes refresh and infinite scroll.

## Context
- lib/features/clips/providers/media_provider.dart
- lib/features/clips/data/media_item.dart
- lib/app.dart (to integrate)

## Tasks

<task type="auto">
  <name>Add cached_network_image dependency</name>
  <files>pubspec.yaml</files>
  <action>
    Add to dependencies:
    ```yaml
    cached_network_image: ^3.3.0
    ```
    
    Run `flutter pub get`.
  </action>
  <verify>flutter pub get</verify>
  <done>cached_network_image installed</done>
</task>

<task type="auto">
  <name>Create media grid item widget</name>
  <files>lib/features/clips/presentation/media_grid_item.dart</files>
  <action>
    Create lib/features/clips/presentation/media_grid_item.dart:
    
    ```dart
    import 'package:cached_network_image/cached_network_image.dart';
    import 'package:flutter/material.dart';
    import '../data/media_item.dart';
    
    class MediaGridItem extends StatelessWidget {
      final MediaItem item;
      final VoidCallback? onTap;
    
      const MediaGridItem({
        super.key,
        required this.item,
        this.onTap,
      });
    
      @override
      Widget build(BuildContext context) {
        return GestureDetector(
          onTap: onTap,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: item.thumbnailUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[800],
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[800],
                    child: const Icon(Icons.error),
                  ),
                ),
              ),
              // Video indicator
              if (item.mediaType == MediaType.video)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.play_circle_outline,
                          size: 16,
                          color: Colors.white,
                        ),
                        if (item.videoDuration != null) ...[
                          const SizedBox(width: 4),
                          Text(
                            _formatDuration(item.videoDuration!),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              // Game name overlay
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(8),
                    ),
                  ),
                  child: Text(
                    item.gameName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        );
      }
    
      String _formatDuration(double seconds) {
        final duration = Duration(seconds: seconds.round());
        final minutes = duration.inMinutes;
        final secs = duration.inSeconds % 60;
        return '$minutes:${secs.toString().padLeft(2, '0')}';
      }
    }
    ```
  </action>
  <verify>dart analyze lib/features/clips/presentation/media_grid_item.dart</verify>
  <done>MediaGridItem widget with thumbnail, video indicator, game name</done>
</task>

## Success Criteria
- [ ] cached_network_image installed
- [ ] MediaGridItem shows thumbnail with overlays
- [ ] Video items show play icon and duration
- [ ] `dart analyze lib/` passes
