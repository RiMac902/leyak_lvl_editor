import 'dart:math' as math;
import 'dart:ui';

import 'package:leyak_lvl_editor/editor/models/shape_style.dart';
import 'package:leyak_lvl_editor/editor/models/shape_type.dart';

/// Єдина відповідальність — побудувати [Path] форми [type], вписаної в
/// [rect], з урахуванням [style] ([ShapeStyle.cornerRadius] для
/// прямокутника, [ShapeStyle.lineStart]/[lineEnd]/[lineThickness] для
/// лінії — обидва в координатах сітки, тому множаться на [tileSize]).
/// Спільний і для заливки кольором, і для кліпу шейдерного накладення
/// ([EntityComponent]), і для прев'ю малювання ([ToolOverlayRenderer]) —
/// щоб усі три місця завжди малювали однакову форму.
Path shapePathFor(ShapeType type, Rect rect, ShapeStyle style, double tileSize) {
  switch (type) {
    case ShapeType.rectangle:
      if (style.cornerRadius <= 0) return Path()..addRect(rect);
      final maxRadius = math.min(rect.width, rect.height) / 2;
      final radius = (style.cornerRadius * tileSize).clamp(0.0, maxRadius);
      return Path()..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)));
    case ShapeType.ellipse:
      return Path()..addOval(rect);
    case ShapeType.triangle:
      return Path()
        ..moveTo(rect.center.dx, rect.top)
        ..lineTo(rect.right, rect.bottom)
        ..lineTo(rect.left, rect.bottom)
        ..close();
    case ShapeType.line:
      final start = Offset(
        rect.left + style.lineStart.x * tileSize,
        rect.top + style.lineStart.y * tileSize,
      );
      final end = Offset(
        rect.left + style.lineEnd.x * tileSize,
        rect.top + style.lineEnd.y * tileSize,
      );
      return _linePath(start, end, style.lineThickness * tileSize);
  }
}

/// "Лінія" — заповнений вузький чотирикутник між [start] і [end] завширшки
/// [thickness], а не справжній stroke — так вона лишається звичайним
/// [Path], який можна так само заливати кольором чи кліпати шейдером, як і
/// інші форми.
Path _linePath(Offset start, Offset end, double thickness) {
  final direction = end - start;
  final length = direction.distance;
  if (length == 0) return Path();

  final normal = Offset(-direction.dy, direction.dx) / length * (thickness / 2);

  return Path()
    ..moveTo(start.dx + normal.dx, start.dy + normal.dy)
    ..lineTo(end.dx + normal.dx, end.dy + normal.dy)
    ..lineTo(end.dx - normal.dx, end.dy - normal.dy)
    ..lineTo(start.dx - normal.dx, start.dy - normal.dy)
    ..close();
}
