import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';

/// Єдина відповідальність — тримати по одному [VideoPlayerController] на
/// кожен унікальний шлях відео, що зараз використовується хоч одним
/// [EntityComponent], лічити скільки сутностей на нього посилаються, і
/// роздавати останній захоплений кадр як [ui.Image].
///
/// Сам НЕ знімає кадри — реальний рендер `video_player` можливий лише
/// всередині дерева віджетів Flutter, тож знімки робить [VideoTextureHost]
/// (мостить Flutter widget tree і Flame-компоненти) і штовхає їх сюди
/// через [updateFrame]. [activePaths] — сигнал для [VideoTextureHost], які
/// саме приховані відео-віджети йому зараз тримати змонтованими.
class VideoTextureManager {
  final Map<String, VideoPlayerController> _controllers = {};
  final Map<String, int> _refCounts = {};
  final Map<String, ui.Image?> _frames = {};

  final ValueNotifier<Set<String>> activePaths = ValueNotifier<Set<String>>(const {});

  VideoPlayerController? controllerFor(String path) => _controllers[path];

  ui.Image? frameFor(String? path) => path == null ? null : _frames[path];

  /// Сигналізує, що ще один [EntityComponent] почав використовувати відео
  /// за [path]. Ідемпотентно рахує посилання — контролер створюється лише
  /// на перше звернення. [path], що починається з `assets/`, вважається
  /// вбудованим Flutter-asset'ом (див. `pubspec.yaml` → `flutter: assets:`)
  /// і відкривається через [VideoPlayerController.asset] — інакше це
  /// абсолютний шлях на диску (типово — вибраний через file picker),
  /// відкривається через [VideoPlayerController.file].
  void acquire(String path) {
    final count = (_refCounts[path] ?? 0) + 1;
    _refCounts[path] = count;
    if (count > 1) return;

    final controller = path.startsWith('assets/')
        ? VideoPlayerController.asset(path)
        : VideoPlayerController.file(File(path));
    _controllers[path] = controller;
    activePaths.value = {...activePaths.value, path};

    controller.initialize().then((_) {
      controller
        ..setLooping(true)
        ..play();
    });
  }

  /// Сигналізує, що [EntityComponent] більше не використовує відео за
  /// [path]. Контролер звільняється лише коли лічильник посилань сягає 0.
  void release(String path) {
    final count = (_refCounts[path] ?? 0) - 1;
    if (count > 0) {
      _refCounts[path] = count;
      return;
    }

    _refCounts.remove(path);
    _frames.remove(path);
    _controllers.remove(path)?.dispose();
    activePaths.value = {...activePaths.value}..remove(path);
  }

  /// Викликається [VideoTextureHost] після кожного знімку кадру.
  void updateFrame(String path, ui.Image image) {
    if (!_controllers.containsKey(path)) {
      // Відео вже звільнили, поки знімок летів асинхронно — картинка нікому
      // не потрібна.
      image.dispose();
      return;
    }
    _frames[path]?.dispose();
    _frames[path] = image;
  }
}
