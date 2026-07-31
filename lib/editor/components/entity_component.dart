import 'dart:ui';

import 'package:flame/components.dart';
import 'package:leyak_lvl_editor/code/di/injection.dart';
import 'package:leyak_lvl_editor/editor/animation/position_smoothing.dart';
import 'package:leyak_lvl_editor/editor/main_editor.dart';
import 'package:leyak_lvl_editor/editor/models/level_entity.dart';
import 'package:leyak_lvl_editor/editor/models/shape_type.dart';
import 'package:leyak_lvl_editor/editor/rendering/entity_visual_painter.dart';
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
        paintEntityVisual(
          canvas,
          partRect,
          part.color,
          part.shaderId,
          part.videoPath,
          part.shaderParams,
          part.shapeType,
          part.shapeStyle,
          tileSize,
          _elapsedTime,
        );
      }
    } else {
      paintEntityVisual(
        canvas,
        Rect.fromLTWH(0, 0, size.x, size.y),
        entity.visual.color,
        entity.visual.shaderId,
        entity.visual.videoPath,
        entity.visual.shaderParams,
        entity.shapeType,
        entity.shapeStyle,
        game.tileSize,
        _elapsedTime,
      );
    }

    // Прямокутна рамка bbox як індикатор виділення — оминається для path:
    // для довільного контуру вона вводила б в оману (рамка навколо
    // bbox, не навколо самої кривої). Реальний індикатор виділення й
    // редагування для path — точки-хендли з PathNodeGizmoComponent.
    if (isSelected && entity.shapeType != ShapeType.path) {
      final rect = Rect.fromLTWH(0, 0, size.x, size.y);
      final borderPaint = Paint()
        ..color = const Color(0xFFFFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawRect(rect, borderPaint);
    }
  }
}
