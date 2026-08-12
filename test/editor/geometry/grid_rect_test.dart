import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leyak_lvl_editor/editor/geometry/grid_rect.dart';

void main() {
  group('GridRect.fromCorners', () {
    test('normalizes corners regardless of drag direction', () {
      final rect = GridRect.fromCorners(Vector2(5, 5), Vector2(1, 2), inclusive: false);

      expect(rect.position, Vector2(1, 2));
      expect(rect.size, Vector2(4, 3));
    });

    test('inclusive mode pads size by one cell for snap-mode marquee', () {
      final rect = GridRect.fromCorners(Vector2(1, 1), Vector2(3, 4), inclusive: true);

      expect(rect.position, Vector2(1, 1));
      expect(rect.size, Vector2(3, 4));
    });

    test('non-inclusive mode has no padding for free placement', () {
      final rect = GridRect.fromCorners(Vector2(1, 1), Vector2(3, 4), inclusive: false);

      expect(rect.size, Vector2(2, 3));
    });

    test('degenerate single-point selection has zero size when non-inclusive', () {
      final rect = GridRect.fromCorners(Vector2(2, 2), Vector2(2, 2), inclusive: false);

      expect(rect.size, Vector2.zero());
    });
  });

  group('GridRect.intersects', () {
    test('returns true for overlapping rectangles', () {
      final rect = GridRect(Vector2(0, 0), Vector2(4, 4));

      expect(rect.intersects(Vector2(2, 2), Vector2(4, 4)), isTrue);
    });

    test('returns false for rectangles that only touch at an edge', () {
      final rect = GridRect(Vector2(0, 0), Vector2(4, 4));

      expect(rect.intersects(Vector2(4, 0), Vector2(4, 4)), isFalse);
    });

    test('returns false for disjoint rectangles', () {
      final rect = GridRect(Vector2(0, 0), Vector2(2, 2));

      expect(rect.intersects(Vector2(10, 10), Vector2(2, 2)), isFalse);
    });

    test('returns true when one rectangle fully contains the other', () {
      final rect = GridRect(Vector2(0, 0), Vector2(10, 10));

      expect(rect.intersects(Vector2(2, 2), Vector2(1, 1)), isTrue);
    });
  });
}
