import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:leyak_lvl_editor/editor/animation/entity_motion_animator.dart';
import 'package:leyak_lvl_editor/editor/entities/entity_repository.dart';
import 'package:leyak_lvl_editor/editor/geometry/grid_coordinate_converter.dart';
import 'package:leyak_lvl_editor/editor/geometry/grid_rect.dart';
import 'package:leyak_lvl_editor/editor/models/level_entity.dart';
import 'package:leyak_lvl_editor/editor/tools/draw_tool.dart';
import 'package:leyak_lvl_editor/editor/tools/selection_tool.dart';

/// Єдина відповідальність — відмальовка сцени об'єктів на canvas:
/// самі сутності, прев'ю малювання та рамка виділення. Готові
/// сутності малюються в їхній анімованій ([EntityMotionAnimator])
/// позиції, а не одразу в snapped-цільовій — це й дає плавний рух.
/// Розмір тайла й режим прилипання читає з [GridCoordinateConverter] —
/// тієї самої "одиниці правди", що й інструменти малювання/виділення.
class ObjectSceneRenderer {
  const ObjectSceneRenderer();

  void render(
    Canvas canvas,
    GridCoordinateConverter converter,
    EntityRepository repository,
    DrawTool drawTool,
    SelectionTool selectionTool,
    EntityMotionAnimator motionAnimator,
  ) {
    final tileSize = converter.getTileSize();

    for (final entity in repository.sortedByLayer) {
      if (!entity.isVisible) continue;
      final position = motionAnimator.visualPositionOf(entity);
      _drawEntity(canvas, position, entity, tileSize, selectionTool.selected);
    }

    if (drawTool.entity != null && drawTool.origin != null) {
      _drawEntity(canvas, drawTool.origin!, drawTool.entity!, tileSize, selectionTool.selected);
    }

    if (selectionTool.marqueeStart != null && selectionTool.marqueeCurrent != null) {
      _drawMarquee(
        canvas,
        tileSize,
        selectionTool.marqueeStart!,
        selectionTool.marqueeCurrent!,
        converter.snapping,
      );
    }
  }

  void _drawEntity(
    Canvas canvas,
    Vector2 origin,
    LevelEntity entity,
    double tileSize,
    List<LevelEntity> selected,
  ) {
    final rect = Rect.fromLTWH(
      origin.x * tileSize,
      origin.y * tileSize,
      entity.transform.size.x * tileSize,
      entity.transform.size.y * tileSize,
    );

    canvas.drawRect(rect, Paint()..color = entity.visual.color);

    if (selected.contains(entity)) {
      final borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawRect(rect, borderPaint);
    }
  }

  void _drawMarquee(
    Canvas canvas,
    double tileSize,
    Vector2 start,
    Vector2 current,
    bool inclusive,
  ) {
    final region = GridRect.fromCorners(start, current, inclusive: inclusive);
    final rect = Rect.fromLTWH(
      region.position.x * tileSize,
      region.position.y * tileSize,
      region.size.x * tileSize,
      region.size.y * tileSize,
    );

    final fillPaint = Paint()
      ..color = Colors.blue.withAlpha(50)
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawRect(rect, fillPaint);
    canvas.drawRect(rect, borderPaint);
  }
}
