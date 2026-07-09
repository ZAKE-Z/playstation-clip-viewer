import 'dart:convert';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../upload/data/upload_config.dart';
import '../../upload/providers/upload_settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final configState = ref.watch(uploadConfigProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Upload',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Import a ShareX (.sxcu) config to upload clips and screenshots to '
            'your preferred service. The config is stored securely.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 24),
          configState.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text(
              'Error loading: $e',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            data: (config) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (config != null) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest
                            .withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                size: 20,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                config.name.isNotEmpty
                                    ? config.name
                                    : config.requestUrl,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            config.requestUrl,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => _importShareX(context, ref),
                          icon: const Icon(Icons.upload_file),
                          label: Text(
                            config != null ? 'Import different config' : 'Import ShareX config',
                          ),
                        ),
                      ),
                      if (config != null) ...[
                        const SizedBox(width: 12),
                        FilledButton.tonalIcon(
                          onPressed: () => _clear(context, ref),
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Clear'),
                        ),
                      ],
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _importShareX(BuildContext context, WidgetRef ref) async {
    const group = XTypeGroup(
      label: 'ShareX config',
      extensions: ['sxcu', 'json'],
    );
    final files = await openFiles(acceptedTypeGroups: [group]);
    if (files.isEmpty || !context.mounted) return;

    try {
      var bytes = await files.first.readAsBytes();
      // Strip UTF-8 BOM if present (common in Windows-saved JSON)
      const bom = [0xEF, 0xBB, 0xBF];
      if (bytes.length >= 3 &&
          bytes[0] == bom[0] &&
          bytes[1] == bom[1] &&
          bytes[2] == bom[2]) {
        bytes = bytes.sublist(3);
      }
      final json = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
      final config = UploadConfig.fromShareX(json);
      if (config == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invalid ShareX config: missing RequestURL'),
            ),
          );
        }
        return;
      }
      await ref.read(uploadConfigProvider.notifier).saveConfig(config);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Imported: ${config.name}')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import failed: $e')),
        );
      }
    }
  }

  Future<void> _clear(BuildContext context, WidgetRef ref) async {
    await ref.read(uploadConfigProvider.notifier).clearConfig();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Upload config cleared')),
      );
    }
  }
}
