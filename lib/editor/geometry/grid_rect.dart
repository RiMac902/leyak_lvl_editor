import 'package:flame/components.dart';

/// Прямокутник у координатах сітки. Єдина відповідальність — геометрія:
/// побудова з двох довільних кутових точок та перевірка перетину.
class GridRect {
  GridRect(this.position, this.size);

  /// [inclusive] — чи трактувати [a]/[b] як індекси клітинок, що обидві
  /// входять у прямокутник (snap-режим, тоді додається +1 клітинка), чи
  /// як точні координати без прилипання (вільне розміщення, без padding).
  factory GridRect.fromCorners(Vector2 a, Vector2 b, {required bool inclusive}) {
    final minX = a.x < b.x ? a.x : b.x;
    final minY = a.y < b.y ? a.y : b.y;
    final maxX = a.x > b.x ? a.x : b.x;
    final maxY = a.y > b.y ? a.y : b.y;
    final pad = inclusive ? 1.0 : 0.0;
    return GridRect(
      Vector2(minX, minY),
      Vector2(maxX - minX + pad, maxY - minY + pad),
    );
  }

  final Vector2 position;
  final Vector2 size;

  bool intersects(Vector2 otherPosition, Vector2 otherSize) {
    return position.x < otherPosition.x + otherSize.x &&
        position.x + size.x > otherPosition.x &&
        position.y < otherPosition.y + otherSize.y &&
        position.y + size.y > otherPosition.y;
  }
}
