import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

/// Єдина відповідальність — грати один спільний на всю сцену музичний трек
/// через SoLoud і роздавати його поточний спектр (FFT + waveform) як
/// [ui.Image]-текстуру для шейдерів, яким вона потрібна ([ShaderTextureKind.audio]).
///
/// На відміну від [VideoTextureManager], тут НЕ потрібен міст до Flutter
/// widget tree: аналіз аудіо в SoLoud — нативна/FFI можливість, незалежна
/// від дерева віджетів, тож весь захват живе в звичайному Dart-таймері.
class AudioTextureManager {
  static const int _bins = 256;
  static const Duration _captureInterval = Duration(milliseconds: 33);

  AudioSource? _source;
  SoundHandle? _handle;
  AudioData? _audioData;
  Timer? _timer;
  ui.Image? _currentFrame;
  bool _soloudInitialized = false;

  /// Шлях поточного треку, або `null`, якщо нічого не грає. UI (панель
  /// вибору треку) слухає це для відображення поточного вибору.
  final ValueNotifier<String?> currentPath = ValueNotifier<String?>(null);

  /// Останній захоплений кадр спектру (256x2: рядок 0 — FFT, рядок 1 —
  /// waveform) — читається синхронно щокадру в [EntityComponent.render].
  ui.Image? get currentFrame => _currentFrame;

  /// Запускає відтворення [assetPath] у циклі (гучно — на відміну від
  /// відео, музика має бути чутною) і починає періодично оновлювати
  /// спектр-текстуру. Зупиняє попередній трек, якщо той грав.
  Future<void> play(String assetPath) async {
    await stop();

    if (!_soloudInitialized) {
      await SoLoud.instance.init();
      _soloudInitialized = true;
    }
    SoLoud.instance.setVisualizationEnabled(true);

    final source = await SoLoud.instance.loadAsset(assetPath);
    _source = source;
    _handle = SoLoud.instance.play(source, looping: true);
    _audioData = AudioData(GetSamplesKind.linear);
    currentPath.value = assetPath;
    _timer = Timer.periodic(_captureInterval, (_) => _captureFrame());
  }

  /// Зупиняє поточний трек (якщо є) і звільняє все пов'язане з ним.
  Future<void> stop() async {
    _timer?.cancel();
    _timer = null;

    final handle = _handle;
    if (handle != null) await SoLoud.instance.stop(handle);
    final source = _source;
    if (source != null) await SoLoud.instance.disposeSource(source);

    _audioData?.dispose();
    _audioData = null;
    _handle = null;
    _source = null;
    _currentFrame?.dispose();
    _currentFrame = null;
    currentPath.value = null;
  }

  void _captureFrame() {
    final data = _audioData;
    if (data == null) return;

    data.updateSamples();
    final samples = data.getAudioData();
    if (samples.length < _bins * 2) return;

    final bytes = Uint8List(_bins * 2 * 4);
    for (var x = 0; x < _bins; x++) {
      final fft = (samples[x].clamp(0.0, 1.0) * 255).round();
      final wave = (((samples[_bins + x] + 1) / 2).clamp(0.0, 1.0) * 255).round();

      final fftOffset = x * 4;
      bytes[fftOffset] = fft;
      bytes[fftOffset + 1] = fft;
      bytes[fftOffset + 2] = fft;
      bytes[fftOffset + 3] = 255;

      final waveOffset = (_bins + x) * 4;
      bytes[waveOffset] = wave;
      bytes[waveOffset + 1] = wave;
      bytes[waveOffset + 2] = wave;
      bytes[waveOffset + 3] = 255;
    }

    ui.decodeImageFromPixels(bytes, _bins, 2, ui.PixelFormat.rgba8888, (image) {
      _currentFrame?.dispose();
      _currentFrame = image;
    });
  }
}
