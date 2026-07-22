import 'package:flame/components.dart';

/// Єдина відповідальність — конвертація світових координат у клітинку сітки.
class GridCoordinateConverter {
  const GridCoordinateConverter(this.tileSize);

  final double tileSize;

  Vector2 worldToGrid(Vector2 worldPos) {
    final col = (worldPos.x / tileSize).floorToDouble();
    final row = (worldPos.y / tileSize).floorToDouble();
    return Vector2(col, row);
  }
}
