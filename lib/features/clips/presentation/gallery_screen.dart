import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/image_cache_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/media_provider.dart';
import 'media_grid_item.dart';
import 'detail_screen.dart';

class GalleryScreen extends ConsumerWidget {
  const GalleryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mediaState = ref.watch(mediaListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('PS Clips'),
        actions: [
          // Refresh button
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
