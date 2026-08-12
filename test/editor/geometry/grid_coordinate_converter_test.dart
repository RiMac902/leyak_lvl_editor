import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leyak_lvl_editor/editor/geometry/grid_coordinate_converter.dart';

void main() {
  group('GridCoordinateConverter', () {
    test('snapping enabled floors to the nearest grid cell', () {
      final converter = GridCoordinateConverter(() => 64.0, () => true);

      final result = converter.worldToGrid(Vector2(130, 190));

      expect(result, Vector2(2, 2));
    });

    test('snapping disabled returns exact fractional grid position', () {
      final converter = GridCoordinateConverter(() => 64.0, () => false);

      final result = converter.worldToGrid(Vector2(130, 192));

      expect(result.x, closeTo(2.03125, 1e-9));
      expect(result.y, 3.0);
    });

    test('floors negative coordinates towards negative infinity', () {
      final converter = GridCoordinateConverter(() => 64.0, () => true);

      final result = converter.worldToGrid(Vector2(-10, -65));

      expect(result, Vector2(-1, -2));
    });

    test('reads tile size and snap flag lazily on every call', () {
      var tileSize = 32.0;
      var snapping = false;
      final converter = GridCoordinateConverter(() => tileSize, () => snapping);

      expect(converter.worldToGrid(Vector2(64, 0)), Vector2(2, 0));

      tileSize = 64.0;
      snapping = true;
      expect(converter.worldToGrid(Vector2(70, 0)), Vector2(1, 0));
      expect(converter.snapping, isTrue);
    });
  });
}
