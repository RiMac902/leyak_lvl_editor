import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:leyak_lvl_editor/editor/geometry/grid_coordinate_converter.dart';
import 'package:leyak_lvl_editor/editor/geometry/grid_rect.dart';
import 'package:leyak_lvl_editor/editor/models/shape_style.dart';
import 'package:leyak_lvl_editor/editor/models/shape_type.dart';
import 'package:leyak_lvl_editor/editor/rendering/shape_path.dart';
import 'package:leyak_lvl_editor/editor/tools/draw_tool.dart';
import 'package:leyak_lvl_editor/editor/tools/selection_tool.dart';

/// Єдина відповідальність — відмальовка ефемерного, не пов'язаного з даними
/// "начиння" інструментів: прев'ю малювання та рамка виділення (marquee).
/// Самі сутності малює [EntityComponent] — цей клас лишається тільки для
/// того, що не має власного компонента в дереві Flame.
class ToolOverlayRenderer {
  const ToolOverlayRenderer();

  void render(
    Canvas canvas,
    GridCoordinateConverter converter,
    DrawTool drawTool,
    SelectionTool selectionTool,
  ) {
    final tileSize = converter.getTileSize();

    if (drawTool.entity != null && drawTool.origin != null) {
      _drawRect(
        canvas,
        drawTool.origin!,
        drawTool.entity!.transform.size,
        tileSize,
        drawTool.entity!.visual.color,
        drawTool.entity!.shapeType,
        drawTool.entity!.shapeStyle,
      );
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

  void _drawRect(
    Canvas canvas,
    Vector2 origin,
    Vector2 size,
    double tileSize,
    Color color,
    ShapeType shapeType,
    ShapeStyle shapeStyle,
  ) {
    final rect = Rect.fromLTWH(
      origin.x * tileSize,
      origin.y * tileSize,
      size.x * tileSize,
      size.y * tileSize,
    );
    canvas.drawPath(shapePathFor(shapeType, rect, shapeStyle, tileSize), Paint()..color = color);
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
