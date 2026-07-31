import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:leyak_lvl_editor/editor/main_editor.dart';

class GridComponent extends Component with HasGameReference<MainEditor> {
  final Paint gridPaint = Paint()
    ..color = Colors.grey.withAlpha(76)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;

  @override
  void render(Canvas canvas) {
    final visibleRect = game.camera.visibleWorldRect;

    final double tileSize = game.tileSize;
    final int gridWidth = game.gridWidth;
    final int gridLength = game.gridLength;

    // Рівень починається на x=0 (старт) і закінчується на gridWidth
    // клітинок праворуч (кінець рівня, який тягає LevelEndMarkerComponent)
    // — як у Geometry Dash, а не центрований довкола x=0.
    final double gridLeft = 0;
    final double gridRight = gridWidth * tileSize;
    final double gridTop = 0;
    final double gridBottom = gridLength * tileSize;

    final double startX = (visibleRect.left / tileSize).floor() * tileSize;
    final double endX = (visibleRect.right / tileSize).ceil() * tileSize;

    final double startY = (visibleRect.top / tileSize).floor() * tileSize;
    final double endY = (visibleRect.bottom / tileSize).ceil() * tileSize;

    for (double x = startX; x <= endX; x += tileSize) {
      if (x >= gridLeft && x <= gridRight) {
        final y1 = startY < gridTop ? gridTop : startY;
        final y2 = endY > gridBottom ? gridBottom : endY;
        canvas.drawLine(Offset(x, y1), Offset(x, y2), gridPaint);
      }
    }

    for (double y = startY; y <= endY; y += tileSize) {
      if (y >= gridTop && y <= gridBottom) {
        final x1 = startX < gridLeft ? gridLeft : startX;
        final x2 = endX > gridRight ? gridRight : endX;
        canvas.drawLine(Offset(x1, y), Offset(x2, y), gridPaint);
      }
    }
  }
}
