import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/image_cache_service.dart';
import '../../../core/services/logger_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../../settings/presentation/settings_screen.dart';
import '../providers/media_provider.dart';
import 'media_grid_item.dart';
import 'detail_screen.dart';

/// Interval for background auto-refresh
const _autoRefreshInterval = Duration(minutes: 2);

class GalleryScreen extends ConsumerStatefulWidget {
  const GalleryScreen({super.key});

  @override
  ConsumerState<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends ConsumerState<GalleryScreen> {
  Timer? _autoRefreshTimer;

  @override
  void initState() {
    super.initState();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(_autoRefreshInterval, (_) {
      ref.read(mediaListProvider.notifier).refreshInBackground();
    });
  }

  @override
  Widget build(BuildContext context) {
    final mediaState = ref.watch(mediaListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('PS Clips'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              // Clear image cache and reload
              ImageCacheService.instance.clearCache();
              ref.read(mediaListProvider.notifier).refresh();
            },
          ),
          // Logout button
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
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
              const Icon(Icons.error_outline, size: 60, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Something went wrong',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  error.toString().replaceAll('Exception: ', ''),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => ref.read(mediaListProvider.notifier).refresh(),
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
        data: (state) {
          if (state.items.isEmpty && state.error == null) {
            return RefreshIndicator(
              onRefresh: () async {
                ImageCacheService.instance.clearCache();
                await ref.read(mediaListProvider.notifier).refresh();
              },
              child: Stack(
                children: [
                  ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 200), // Push content down
                    ],
                  ),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.photo_library_outlined,
                          size: 80,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'No clips found',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Pull to refresh or check back later',
                          style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 24),
                        FilledButton.tonalIcon(
                          onPressed: () =>
                              ref.read(mediaListProvider.notifier).refresh(),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Refresh Now'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          if (state.error != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 60,
                      color: Colors.orange,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Unable to load clips',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.error.toString(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FilledButton.icon(
                          onPressed: () =>
                              ref.read(mediaListProvider.notifier).refresh(),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                        const SizedBox(width: 16),
                        OutlinedButton.icon(
                          onPressed: () async {
                            // Open log file logic
                            final logger = ref.read(loggerServiceProvider);
                            final path = await logger.getLogFilePath();
                            if (path != null) {
                              // Open explorer with file selected
                              final result = await Process.run('explorer.exe', [
                                '/select,',
                                path,
                              ]);
                              if (result.exitCode != 0) {
                                // Fallback: just open the folder
                                // Not critical if fails
                              }
                            }
                          },
                          icon: const Icon(Icons.description),
                          label: const Text('Open Log'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ImageCacheService.instance.clearCache();
              await ref.read(mediaListProvider.notifier).refresh();
            },
            child: GridView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 16 / 9,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: state.items.length,
              itemBuilder: (context, index) {
                final item = state.items[index];
                return MediaGridItem(
                  item: item,
                  onTap: () {
                    final cookies = ref.read(cloudFrontCookiesProvider);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) =>
                            DetailScreen(item: item, cookies: cookies),
                      ),
                    );
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
