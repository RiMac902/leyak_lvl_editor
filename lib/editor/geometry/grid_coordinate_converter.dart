import 'package:flame/components.dart';

/// Єдина відповідальність — конвертація світових координат у координати
/// сітки, з урахуванням поточного режиму прилипання. Розмір тайла й прапорець
/// snap читаються лениво (через колбеки), щоб конвертер можна було створити
/// до того, як стануть доступні ігровий екземпляр і стан snap-режиму.
class GridCoordinateConverter {
  const GridCoordinateConverter(this.getTileSize, this.isSnapEnabled);

  final double Function() getTileSize;
  final bool Function() isSnapEnabled;

  bool get snapping => isSnapEnabled();

  /// Snap увімкнено — округлює до клітинки сітки. Snap вимкнено — повертає
  /// точну позицію в координатах сітки (вільне розміщення).
  Vector2 worldToGrid(Vector2 worldPos) {
    final tileSize = getTileSize();
    final x = worldPos.x / tileSize;
    final y = worldPos.y / tileSize;
    if (!snapping) return Vector2(x, y);
    return Vector2(x.floorToDouble(), y.floorToDouble());
  }
}
