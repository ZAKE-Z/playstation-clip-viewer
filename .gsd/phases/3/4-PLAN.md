---
phase: 3
plan: 4
wave: 2
---

# Plan 3.4: Gallery Screen Integration

## Objective
Create the main gallery screen with grid layout, infinite scroll, pull-to-refresh, and integrate into app navigation.

## Context
- lib/features/clips/providers/media_provider.dart
- lib/features/clips/presentation/media_grid_item.dart
- lib/app.dart

## Tasks

<task type="auto">
  <name>Create gallery screen</name>
  <files>lib/features/clips/presentation/gallery_screen.dart</files>
  <action>
    Create lib/features/clips/presentation/gallery_screen.dart:
    
    ```dart
    import 'package:flutter/material.dart';
    import 'package:flutter_riverpod/flutter_riverpod.dart';
    import '../providers/media_provider.dart';
    import 'media_grid_item.dart';
    
    class GalleryScreen extends ConsumerStatefulWidget {
      const GalleryScreen({super.key});
    
      @override
      ConsumerState<GalleryScreen> createState() => _GalleryScreenState();
    }
    
    class _GalleryScreenState extends ConsumerState<GalleryScreen> {
      final _scrollController = ScrollController();
    
      @override
      void initState() {
        super.initState();
        _scrollController.addListener(_onScroll);
      }
    
      @override
      void dispose() {
        _scrollController.dispose();
        super.dispose();
      }
    
      void _onScroll() {
        if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200) {
          ref.read(mediaListProvider.notifier).loadMore();
        }
      }
    
      @override
      Widget build(BuildContext context) {
        final mediaState = ref.watch(mediaListProvider);
    
        return Scaffold(
          appBar: AppBar(
            title: const Text('PS Clips'),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () => ref.read(authProvider.notifier).logout(),
              ),
            ],
          ),
          body: mediaState.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: $error'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.invalidate(mediaListProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
            data: (state) {
              if (state.items.isEmpty && state.error == null) {
                return const Center(
                  child: Text('No clips found'),
                );
              }
    
              return RefreshIndicator(
                onRefresh: () => ref.read(mediaListProvider.notifier).refresh(),
                child: GridView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 16 / 9,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: state.items.length + (state.isLoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index >= state.items.length) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }
    
                    final item = state.items[index];
                    return MediaGridItem(
                      item: item,
                      onTap: () {
                        // TODO: Show detail view (Phase 4)
                      },
                    );
                  },
                ),
              );
            },
          ),
        );
      }
    }
    ```
    
    Note: Need to import authProvider for logout.
  </action>
  <verify>dart analyze lib/features/clips/presentation/gallery_screen.dart</verify>
  <done>GalleryScreen with grid, infinite scroll, pull-to-refresh</done>
</task>

<task type="auto">
  <name>Update app.dart to show gallery when authenticated</name>
  <files>lib/app.dart</files>
  <action>
    Update the Authenticated branch in _AuthWrapper to show GalleryScreen:
    
    Replace the placeholder "Logged in!" screen with:
    ```dart
    import 'features/clips/presentation/gallery_screen.dart';
    
    // In the data: (state) block:
    if (state is Authenticated) {
      return const GalleryScreen();
    }
    ```
    
    Remove the old placeholder Scaffold for authenticated state.
  </action>
  <verify>dart analyze lib/app.dart</verify>
  <done>app.dart routes to GalleryScreen when authenticated</done>
</task>

## Success Criteria
- [ ] GalleryScreen displays media grid
- [ ] Infinite scroll loads more items
- [ ] Pull-to-refresh works
- [ ] Authenticated users see gallery
- [ ] `dart analyze lib/` passes
