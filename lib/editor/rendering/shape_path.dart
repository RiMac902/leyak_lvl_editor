import 'dart:math' as math;
import 'dart:ui';

import 'package:leyak_lvl_editor/editor/models/shape_style.dart';
import 'package:leyak_lvl_editor/editor/models/shape_type.dart';

/// Єдина відповідальність — побудувати [Path] форми [type], вписаної в
/// [rect], з урахуванням [style] ([ShapeStyle.cornerRadii] для
/// прямокутника/трикутника/лінії, [ShapeStyle.lineStart]/[lineEnd]/
/// [lineThickness] для лінії — усі в координатах сітки, тому множаться на
/// [tileSize]). Спільний і для заливки кольором, і для кліпу шейдерного
/// накладення ([EntityComponent]), і для прев'ю малювання
/// ([ToolOverlayRenderer]) — щоб усі три місця завжди малювали однакову
/// форму.
Path shapePathFor(ShapeType type, Rect rect, ShapeStyle style, double tileSize) {
  switch (type) {
    case ShapeType.rectangle:
      return _roundedPolygonPath(
        [rect.topLeft, rect.topRight, rect.bottomRight, rect.bottomLeft],
        style.cornerRadii.map((r) => r * tileSize).toList(),
      );
    case ShapeType.ellipse:
      return Path()..addOval(rect);
    case ShapeType.triangle:
      return _roundedPolygonPath(
        [Offset(rect.center.dx, rect.top), rect.bottomRight, rect.bottomLeft],
        style.cornerRadii.take(3).map((r) => r * tileSize).toList(),
      );
    case ShapeType.line:
      final start = Offset(
        rect.left + style.lineStart.x * tileSize,
        rect.top + style.lineStart.y * tileSize,
      );
      final end = Offset(
        rect.left + style.lineEnd.x * tileSize,
        rect.top + style.lineEnd.y * tileSize,
      );
      return _linePath(start, end, style.lineThickness * tileSize, style.cornerRadii, tileSize);
  }
}

/// "Лінія" — заповнений вузький чотирикутник між [start] і [end] завширшки
/// [thickness], а не справжній stroke — так вона лишається звичайним
/// [Path], який можна так само заливати кольором чи кліпати шейдером, як і
/// інші форми. [cornerRadii]\[0\]/\[1\] (заокруглення початку/кінця,
/// координати сітки) застосовуються до ОБОХ кутів відповідного кінця
/// одразу — користувач думає про лінію як про два кінці, а не 4 окремі
/// кути чотирикутника.
Path _linePath(
  Offset start,
  Offset end,
  double thickness,
  List<double> cornerRadii,
  double tileSize,
) {
  final direction = end - start;
  final length = direction.distance;
  if (length == 0) return Path();

  final normal = Offset(-direction.dy, direction.dx) / length * (thickness / 2);
  final startRadius = cornerRadii[0] * tileSize;
  final endRadius = cornerRadii[1] * tileSize;

  return _roundedPolygonPath(
    [start + normal, end + normal, end - normal, start - normal],
    [startRadius, endRadius, endRadius, startRadius],
  );
}

/// Багатокутник [vertices] із заокругленими кутами: `radii[i]` — радіус
/// заокруглення `vertices[i]` (0 = гострий кут, лишається без змін).
/// Кожен радіус обмежується половиною коротшого із двох суміжних ребер,
/// щоб сусідні фаски не перетиналися. Кут "зрізається" квадратичною
/// кривою Без'є через оригінальну вершину як контрольну точку — не
/// ідеальна дуга кола, але один спільний алгоритм для прямокутника,
/// трикутника й лінії (усі — просто багатокутники з різною кількістю
/// вершин) замість трьох окремих спеціальних випадків.
Path _roundedPolygonPath(List<Offset> vertices, List<double> radii) {
  final n = vertices.length;
  final path = Path();

  for (var i = 0; i < n; i++) {
    final prev = vertices[(i - 1 + n) % n];
    final curr = vertices[i];
    final next = vertices[(i + 1) % n];

    final toPrev = prev - curr;
    final toNext = next - curr;
    final radius = radii[i].clamp(0.0, math.min(toPrev.distance, toNext.distance) / 2);

    final pIn = curr + toPrev / toPrev.distance * radius;
    final pOut = curr + toNext / toNext.distance * radius;

    if (i == 0) {
      path.moveTo(pIn.dx, pIn.dy);
    } else {
      path.lineTo(pIn.dx, pIn.dy);
    }

    if (radius <= 0) {
      path.lineTo(curr.dx, curr.dy);
    } else {
      path.quadraticBezierTo(curr.dx, curr.dy, pOut.dx, pOut.dy);
    }
  }

  return path..close();
}
