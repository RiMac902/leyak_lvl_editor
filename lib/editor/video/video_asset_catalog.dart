import 'package:flutter/services.dart';

/// Єдина відповідальність — список відео, вбудованих у застосунок як
/// Flutter asset (`assets/videos/...`, зареєстровані в `pubspec.yaml` під
/// `flutter: assets:`). Заповнюється один раз при старті через
/// [AssetManifest] — не треба вручну дублювати список файлів у коді щоразу,
/// як хтось додає нове відео в `assets/videos/`, досить прописати новий
/// файл у `pubspec.yaml`.
///
/// Навмисно НЕ дозволяє вибирати довільний файл з диску (через
/// системний file picker) — лише те, що фактично вкладено в застосунок.
class VideoAssetCatalog {
  List<String> _paths = const [];

  List<String> get availablePaths => _paths;

  Future<void> load() async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    _paths = manifest.listAssets().where((path) => path.startsWith('assets/videos/')).toList();
  }
}
