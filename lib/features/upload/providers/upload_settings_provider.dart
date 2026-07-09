import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/storage/upload_config_storage.dart';
import '../data/upload_config.dart';

part 'upload_settings_provider.g.dart';

@Riverpod(keepAlive: true)
UploadConfigStorage uploadConfigStorage(Ref ref) {
  return UploadConfigStorage();
}

@Riverpod(keepAlive: true)
class UploadConfigNotifier extends _$UploadConfigNotifier {
  @override
  Future<UploadConfig?> build() async {
    final storage = ref.read(uploadConfigStorageProvider);
    return storage.loadConfig();
  }

  Future<void> saveConfig(UploadConfig config) async {
    final storage = ref.read(uploadConfigStorageProvider);
    await storage.saveConfig(config);
    state = AsyncValue.data(config);
  }

  Future<void> clearConfig() async {
    final storage = ref.read(uploadConfigStorageProvider);
    await storage.clearConfig();
    state = const AsyncValue.data(null);
  }
}
