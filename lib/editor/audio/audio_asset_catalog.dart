import 'package:flutter/services.dart';

/// Єдина відповідальність — список музичних треків, вбудованих у застосунок
/// як Flutter asset (`assets/audio/...`, зареєстровані в `pubspec.yaml` як
/// директорія під `flutter: assets:`). На відміну від [VideoAssetCatalog]
/// (там реєструється кожен файл окремо), тут директорія оголошена цілком —
/// досить кинути новий файл у `assets/audio/` і перезапустити застосунок,
/// без правок `pubspec.yaml`.
///
/// Фільтрує лише реальні аудіофайли за розширенням, щоб службовий
/// `assets/audio/README.txt` не показувався в списку треків.
class AudioAssetCatalog {
  static const _audioExtensions = ['.mp3', '.wav', '.ogg', '.flac'];

  List<String> _paths = const [];

  List<String> get availablePaths => _paths;

  Future<void> load() async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    _paths = manifest
        .listAssets()
        .where(
          (path) =>
              path.startsWith('assets/audio/') &&
              _audioExtensions.any((ext) => path.toLowerCase().endsWith(ext)),
        )
        .toList();
  }
}
