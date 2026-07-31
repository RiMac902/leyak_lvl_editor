import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:leyak_lvl_editor/editor/models/level_entity.dart';
import 'package:leyak_lvl_editor/editor/rendering/entity_visual_painter.dart';

/// Один [LevelEntity] з редактора, що не є тригером/фінішем — звичайний
/// блок геометрії рівня. Колізія — завжди прямокутний [RectangleHitbox] за
/// bounding-box сутності, незалежно від реальної форми (трикутник/еліпс/
/// path) — точна геометрія хітбокса для довільних форм поза межами цього
/// playtest-порту; рендер лишається чесним — [paintEntityVisual], та сама
/// функція, що малює сутність і в редакторі ([EntityComponent]), тож
/// шейдери/відео/аудіо-текстури виглядають ідентично в грі.
///
/// Хітбокс додається лише коли сутність фактично щось означає для геймплею
/// ([isSolid]/[isDeadly]) — чиста декорація рендериться, але не колізить.
class LevelBlock extends PositionComponent {
  LevelBlock(this.entity, {required this.tileSize});

  final LevelEntity entity;
  final double tileSize;

  /// Секунди з моменту завантаження — той самий сенс, що й
  /// `EntityComponent._elapsedTime`, для шейдерів з uTime.
  double _elapsedTime = 0;

  bool get isSolid => entity.customProperties['isSolid'] == true;
  bool get isDeadly => entity.customProperties['isDeadly'] == true;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    position = entity.transform.position * tileSize;
    size = entity.transform.size * tileSize;
    if (isSolid || isDeadly) {
      add(RectangleHitbox()..collisionType = CollisionType.passive);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _elapsedTime += dt;
  }

  @override
  void render(Canvas canvas) {
    final parts = entity.parts;
    if (parts != null && parts.isNotEmpty) {
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
      return;
    }

    paintEntityVisual(
      canvas,
      Rect.fromLTWH(0, 0, size.x, size.y),
      entity.visual.color,
      entity.visual.shaderId,
      entity.visual.videoPath,
      entity.visual.shaderParams,
      entity.shapeType,
      entity.shapeStyle,
      tileSize,
      _elapsedTime,
    );
  }
}
