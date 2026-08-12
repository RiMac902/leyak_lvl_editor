import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leyak_lvl_editor/editor/geometry/path_bounds.dart';
import 'package:leyak_lvl_editor/editor/models/level_entity.dart';
import 'package:leyak_lvl_editor/editor/models/shape_style.dart';
import 'package:leyak_lvl_editor/editor/models/shape_type.dart';
import 'package:leyak_lvl_editor/editor/models/transform_data.dart';

LevelEntity _pathEntity(List<Vector2> points, {Vector2? position}) {
  return LevelEntity(
    id: 'p',
    transform: TransformData(position: position ?? Vector2.zero()),
    shapeType: ShapeType.path,
    shapeStyle: ShapeStyle(pathPoints: points),
  );
}

void main() {
  group('recomputePathBounds', () {
    test('does nothing when there are no path points', () {
      final entity = _pathEntity([], position: Vector2(5, 5));

      recomputePathBounds(entity);

      expect(entity.transform.position, Vector2(5, 5));
      expect(entity.transform.size, Vector2.all(1.0));
    });

    test('computes tight bounding box from anchor points', () {
      final entity = _pathEntity([Vector2(1, 1), Vector2(4, 2), Vector2(2, 5)]);

      recomputePathBounds(entity);

      expect(entity.transform.size, Vector2(3, 4));
    });

    test('rebases points to stay relative to the new position', () {
      final entity = _pathEntity([Vector2(2, 3), Vector2(6, 7)]);

      recomputePathBounds(entity);

      final points = entity.shapeStyle.pathPoints;
      expect(points[0], Vector2(0, 0));
      expect(points[1], Vector2(4, 4));
    });

    test('offsets transform position by old position plus new origin', () {
      final entity = _pathEntity([Vector2(2, 2), Vector2(5, 5)], position: Vector2(10, 10));

      recomputePathBounds(entity);

      expect(entity.transform.position, Vector2(12, 12));
    });

    test('single point collapses to zero-size box at that point', () {
      final entity = _pathEntity([Vector2(3, 3)]);

      recomputePathBounds(entity);

      expect(entity.transform.size, Vector2.zero());
      expect(entity.shapeStyle.pathPoints.single, Vector2.zero());
    });
  });
}
