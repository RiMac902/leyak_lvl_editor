import 'dart:ui';

import 'package:flame/components.dart';
import 'package:leyak_lvl_editor/code/di/injection.dart';
import 'package:leyak_lvl_editor/editor/animation/position_smoothing.dart';
import 'package:leyak_lvl_editor/editor/audio/audio_texture_manager.dart';
import 'package:leyak_lvl_editor/editor/main_editor.dart';
import 'package:leyak_lvl_editor/editor/models/level_entity.dart';
import 'package:leyak_lvl_editor/editor/models/shape_style.dart';
import 'package:leyak_lvl_editor/editor/models/shape_type.dart';
import 'package:leyak_lvl_editor/editor/rendering/shader_catalog.dart';
import 'package:leyak_lvl_editor/editor/rendering/shape_path.dart';
import 'package:leyak_lvl_editor/editor/video/video_texture_manager.dart';

/// Єдина відповідальність — візуальне представлення однієї [LevelEntity]
/// у дереві компонентів Flame. Щокадру "витягує" свіжі position/rotation/
/// scale/size із сутності (дані лишаються єдиним джерелом правди — цей
/// компонент нічого туди не пише), тож будь-яка зміна ззовні (інструмент
/// перетягування, Inspector) підхоплюється автоматично на наступному кадрі.
/// Позицію згладжує через [PositionSmoothing], щоб рух по сітці не виглядав
/// стрибками між клітинками — так само, як робив колишній
/// EntityMotionAnimator, тільки тепер прив'язано до конкретного компонента.
class EntityComponent extends PositionComponent
    with HasVisibility, HasGameReference<MainEditor> {
  // Anchor.center, а не topLeft: [position] має бути центром фігури, щоб
  // обертання/масштаб (від гізмо чи Inspector) відбувались навколо центру,
  // а не кута — так, як очікує користувач від хендлів трансформації.
  EntityComponent(this.entity) : super(anchor: Anchor.center);

  final LevelEntity entity;

  static const PositionSmoothing _smoothing = PositionSmoothing();

  bool isSelected = false;

  /// Секунди з моменту завантаження цього компонента — подається як uTime
  /// шейдерам, яким потрібна анімація ([ShaderCatalog.needsTime]).
  double _elapsedTime = 0;

  /// Шляхи відео, які цей компонент зараз тримає "живими" у
  /// [VideoTextureManager] (через [VideoTextureManager.acquire]) — щокадру
  /// звіряється з тим, що сутності насправді потрібно зараз, і
  /// acquire/release лише на різницю.
  Set<String> _acquiredVideoPaths = const {};

  Vector2 _targetPixelPosition() =>
      (entity.transform.position + entity.transform.size / 2) * game.tileSize;

  /// Миттєво (без згладжування) ставить позицію в поточну ціль. Потрібно
  /// при першому кадрі, і коли [SceneComponentRegistry] переносить цей
  /// компонент під нового батька (напр. у [GroupComponent] при групуванні) —
  /// інакше стара абсолютна позиція один кадр читалась би як відносна до
  /// нового батька, і сутність візуально смикнулась би.
  void snapToTarget() => position.setFrom(_targetPixelPosition());

  @override
  void onLoad() {
    super.onLoad();
    snapToTarget();
    priority = entity.layer;
  }

  @override
  void update(double dt) {
    super.update(dt);

    _elapsedTime += dt;
    _smoothing.step(position, _targetPixelPosition(), dt);
    angle = entity.transform.rotation;
    scale.setFrom(entity.transform.scale);
    size.setFrom(entity.transform.size * game.tileSize);
    isVisible = entity.isVisible;
    // priority — фактичний z-order у дереві Flame (більший = малюється
    // пізніше = зверху). Сеттер сам не робить нічого дорогого, якщо
    // значення не змінилось, тож можна просто присвоювати щокадру, а не
    // звіряти вручну — реальне перевпорядкування (Layers panel ▲▼) стає
    // видимим одразу.
    priority = entity.layer;

    _reconcileVideoUsage();
  }

  @override
  void onRemove() {
    if (_acquiredVideoPaths.isNotEmpty) {
      final manager = getIt<VideoTextureManager>();
      for (final path in _acquiredVideoPaths) {
        manager.release(path);
      }
      _acquiredVideoPaths = const {};
    }
    super.onRemove();
  }

  Set<String> _neededVideoPaths() {
    final parts = entity.parts;
    if (parts != null && parts.isNotEmpty) {
      return {for (final part in parts) if (part.videoPath != null) part.videoPath!};
    }
    final path = entity.visual.videoPath;
    return path == null ? const {} : {path};
  }

  void _reconcileVideoUsage() {
    final needed = _neededVideoPaths();
    if (needed.length == _acquiredVideoPaths.length && needed.containsAll(_acquiredVideoPaths)) {
      return;
    }

    final manager = getIt<VideoTextureManager>();
    for (final path in needed) {
      if (!_acquiredVideoPaths.contains(path)) manager.acquire(path);
    }
    for (final path in _acquiredVideoPaths) {
      if (!needed.contains(path)) manager.release(path);
    }
    _acquiredVideoPaths = needed;
  }

  @override
  void render(Canvas canvas) {
    final parts = entity.parts;
    if (parts != null && parts.isNotEmpty) {
      final tileSize = game.tileSize;
      for (final part in parts) {
        final partRect = Rect.fromLTWH(
          part.relativePosition.x * tileSize,
          part.relativePosition.y * tileSize,
          part.size.x * tileSize,
          part.size.y * tileSize,
        );
        _drawShape(
          canvas,
          partRect,
          part.color,
          part.shaderId,
          part.videoPath,
          part.shapeType,
          part.shapeStyle,
          tileSize,
        );
      }
    } else {
      _drawShape(
        canvas,
        Rect.fromLTWH(0, 0, size.x, size.y),
        entity.visual.color,
        entity.visual.shaderId,
        entity.visual.videoPath,
        entity.shapeType,
        entity.shapeStyle,
        game.tileSize,
      );
    }

    if (isSelected) {
      final rect = Rect.fromLTWH(0, 0, size.x, size.y);
      final borderPaint = Paint()
        ..color = const Color(0xFFFFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawRect(rect, borderPaint);
    }
  }

  /// Малює форму [shapeType], вписану в [rect], суцільним кольором [color],
  /// і якщо [shaderId] заданий і знайдений у [ShaderCatalog] — НАКЛАДАЄ
  /// шейдер поверх неї (не замінює колір, а компонується над ним, як
  /// напівпрозора плівка), кліпуючи його тим самим контуром форми, щоб
  /// накладення не "вилазило" за межі не-прямокутних форм. Якщо шейдер
  /// потребує текстури ([ShaderCatalog.textureKindFor]), бере поточний кадр
  /// відео за [videoPath] з [VideoTextureManager] чи поточний спектр треку
  /// з [AudioTextureManager] — якщо кадру ще нема (джерело не задане чи ще
  /// завантажується), тихо пропускає шейдер і лишає просто базовий колір,
  /// а не падає/блокується.
  ///
  /// Шейдер рендериться в окреме off-screen зображення точного розміру
  /// [rect], а не напряму на вже трансформований канвас — інакше координати
  /// всередині шейдера ([FlutterFragCoord]) плавали б разом із позицією/
  /// поворотом/зумом об'єкта замість того, щоб лишатись "прив'язаними" до
  /// самої фігури.
  void _drawShape(
    Canvas canvas,
    Rect rect,
    Color color,
    String? shaderId,
    String? videoPath,
    ShapeType shapeType,
    ShapeStyle shapeStyle,
    double tileSize,
  ) {
    final path = shapePathFor(shapeType, rect, shapeStyle, tileSize);
    canvas.drawPath(path, Paint()..color = color);

    final catalog = getIt<ShaderCatalog>();
    final shader = catalog.shaderFor(shaderId);
    if (shader == null) return;

    switch (catalog.textureKindFor(shaderId)) {
      case ShaderTextureKind.video:
        final frame = getIt<VideoTextureManager>().frameFor(videoPath);
        if (frame == null) return;
        shader.setImageSampler(0, frame);
      case ShaderTextureKind.audio:
        final frame = getIt<AudioTextureManager>().currentFrame;
        if (frame == null) return;
        shader.setImageSampler(0, frame);
      case ShaderTextureKind.none:
        break;
    }

    shader
      ..setFloat(0, rect.width)
      ..setFloat(1, rect.height);
    if (catalog.needsTime(shaderId)) {
      shader.setFloat(2, _elapsedTime);
    }

    final image = _renderShaderImage(shader, rect.width, rect.height);
    if (image == null) return;

    canvas.save();
    canvas.clipPath(path);
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      rect,
      Paint(),
    );
    canvas.restore();
  }

  Image? _renderShaderImage(FragmentShader shader, double width, double height) {
    final w = width.ceil();
    final h = height.ceil();
    if (w <= 0 || h <= 0) return null;

    final recorder = PictureRecorder();
    final recordCanvas = Canvas(recorder, Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()));
    recordCanvas.drawRect(
      Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
      Paint()..shader = shader,
    );
    return recorder.endRecording().toImageSync(w, h);
  }
}
