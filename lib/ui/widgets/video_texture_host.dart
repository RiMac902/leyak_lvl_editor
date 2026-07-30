import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:leyak_lvl_editor/editor/video/video_texture_manager.dart';
import 'package:video_player/video_player.dart';

/// Міст між деревом віджетів Flutter і Flame: реальний рендер відео
/// (`video_player`) можливий лише тут, у widget tree. Для кожного активного
/// [VideoTextureManager.activePaths] тримає прихований [VideoPlayer],
/// обгорнутий у [RepaintBoundary], і періодично знімає поточний кадр як
/// [dart:ui.Image], штовхаючи його назад у менеджер — звідки
/// [EntityComponent] синхронно читає його для рендеру шейдера.
class VideoTextureHost extends StatelessWidget {
  const VideoTextureHost({super.key, required this.manager});

  final VideoTextureManager manager;

  @override
  Widget build(BuildContext context) {
    // IgnorePointer: цей віджет існує лише для непомітного захоплення
    // кадрів (Opacity(0.01), не 0 — щоб paint-прохід реально відбувався,
    // див. коментар у _VideoFrameCapture), а не для взаємодії. Без цього
    // його SizedBox(320x180) у верхньому лівому куті екрана перехоплює
    // всі кліки/драги під собою (напр. увесь Layers panel), бо Flutter
    // хіт-тестить Opacity нормально при будь-якому значенні > 0.0.
    return IgnorePointer(
      child: ValueListenableBuilder<Set<String>>(
        valueListenable: manager.activePaths,
        builder: (context, paths, _) {
          return Stack(
            children: [
              for (final path in paths)
                _VideoFrameCapture(key: ValueKey(path), path: path, manager: manager),
            ],
          );
        },
      ),
    );
  }
}

class _VideoFrameCapture extends StatefulWidget {
  const _VideoFrameCapture({super.key, required this.path, required this.manager});

  final String path;
  final VideoTextureManager manager;

  @override
  State<_VideoFrameCapture> createState() => _VideoFrameCaptureState();
}

class _VideoFrameCaptureState extends State<_VideoFrameCapture> {
  static const _captureInterval = Duration(milliseconds: 66);

  final GlobalKey _boundaryKey = GlobalKey();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(_captureInterval, (_) => _captureFrame());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _captureFrame() async {
    final renderObject = _boundaryKey.currentContext?.findRenderObject();
    if (renderObject is! RenderRepaintBoundary || renderObject.debugNeedsPaint) return;

    final image = await renderObject.toImage();
    if (!mounted) {
      image.dispose();
      return;
    }
    widget.manager.updateFrame(widget.path, image);
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.manager.controllerFor(widget.path);
    if (controller == null) return const SizedBox.shrink();

    // controller.initialize() — асинхронний; ValueListenableBuilder тут
    // обов'язковий, а не разовий читання value.isInitialized у build() —
    // інакше цей віджет так і лишався б SizedBox.shrink() назавжди: build()
    // викликається лише один раз одразу після acquire() (коли контролер
    // ще не готовий), і нічого не тригерило б перебудову пізніше, коли
    // ініціалізація фактично завершується.
    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        if (!value.isInitialized) return const SizedBox.shrink();

        // Opacity(0.01), а не Offstage/opacity:0 — ті пропускають
        // фактичний paint-прохід, тож RepaintBoundary.toImage() не мав би
        // що знімати. RepaintBoundary знімає власний растр ДО того, як
        // Opacity його притлумлює (opacity діє на рівні вище цього шару),
        // тож захоплений кадр лишається повнояскравим — тьмяніє лише те,
        // що бачить користувач.
        return Opacity(
          opacity: 0.01,
          child: SizedBox(
            width: 320,
            height: 180,
            child: RepaintBoundary(key: _boundaryKey, child: VideoPlayer(controller)),
          ),
        );
      },
    );
  }
}
