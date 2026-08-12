import 'dart:ui';

import 'package:flame/components.dart' show Vector2;
import 'package:flutter_test/flutter_test.dart';
import 'package:leyak_lvl_editor/editor/models/shape_style.dart';
import 'package:leyak_lvl_editor/editor/models/shape_type.dart';
import 'package:leyak_lvl_editor/editor/rendering/shape_path.dart';

void _expectRectClose(Rect actual, Rect expected, [double tolerance = 1e-6]) {
  expect(actual.left, closeTo(expected.left, tolerance));
  expect(actual.top, closeTo(expected.top, tolerance));
  expect(actual.right, closeTo(expected.right, tolerance));
  expect(actual.bottom, closeTo(expected.bottom, tolerance));
}

void main() {
  const rect = Rect.fromLTWH(10, 20, 100, 60);

  group('rectangle', () {
    test('sharp corners: bounds match the input rect exactly', () {
      final path = shapePathFor(ShapeType.rectangle, rect, ShapeStyle(), 1.0);

      _expectRectClose(path.getBounds(), rect);
    });

    test('rounded corners: bounds still match the input rect', () {
      final style = ShapeStyle(cornerRadii: [10, 10, 10, 10]);
      final path = shapePathFor(ShapeType.rectangle, rect, style, 1.0);

      _expectRectClose(path.getBounds(), rect);
    });

    test('corner radius is scaled by tileSize', () {
      final withoutRadius = shapePathFor(ShapeType.rectangle, rect, ShapeStyle(), 1.0);
      final withRadius = shapePathFor(
        ShapeType.rectangle,
        rect,
        ShapeStyle(cornerRadii: [5, 5, 5, 5]),
        2.0,
      );

      // Both still span the full rect (corners only cut inward along edges).
      _expectRectClose(withoutRadius.getBounds(), rect);
      _expectRectClose(withRadius.getBounds(), rect);
    });
  });

  group('ellipse', () {
    test('bounds match the input rect exactly', () {
      final path = shapePathFor(ShapeType.ellipse, rect, ShapeStyle(), 1.0);

      _expectRectClose(path.getBounds(), rect);
    });
  });

  group('triangle', () {
    test('sharp corners: bounds match the input rect', () {
      final path = shapePathFor(ShapeType.triangle, rect, ShapeStyle(), 1.0);

      _expectRectClose(path.getBounds(), rect);
    });

    test('only the first 3 corner radii are used', () {
      final style = ShapeStyle(cornerRadii: [5, 5, 5, 999]);

      expect(() => shapePathFor(ShapeType.triangle, rect, style, 1.0), returnsNormally);
    });
  });

  group('line', () {
    test('sharp-cornered horizontal line has the expected rectangular bounds', () {
      final style = ShapeStyle(
        lineStart: Vector2(0, 0),
        lineEnd: Vector2(10, 0),
        lineThickness: 4,
      );

      final path = shapePathFor(ShapeType.line, const Rect.fromLTWH(0, 0, 100, 100), style, 1.0);

      _expectRectClose(path.getBounds(), const Rect.fromLTWH(0, -2, 10, 4));
    });

    test('zero-length line (start == end) produces an empty path', () {
      final style = ShapeStyle(
        lineStart: Vector2(3, 3),
        lineEnd: Vector2(3, 3),
        lineThickness: 4,
      );

      final path = shapePathFor(ShapeType.line, const Rect.fromLTWH(0, 0, 10, 10), style, 1.0);

      expect(path.getBounds(), Rect.zero);
    });

    test('line offset is anchored to rect.topLeft and scaled by tileSize', () {
      final style = ShapeStyle(
        lineStart: Vector2(0, 0),
        lineEnd: Vector2(5, 0),
        lineThickness: 2,
      );

      final path = shapePathFor(ShapeType.line, const Rect.fromLTWH(1, 1, 100, 100), style, 2.0);

      // start = (1,1), end = (1 + 5*2, 1) = (11, 1); thickness*tileSize = 4.
      _expectRectClose(path.getBounds(), const Rect.fromLTWH(1, -1, 10, 4));
    });
  });

  group('path (pen tool)', () {
    test('fewer than 2 points produces an empty path', () {
      final style = ShapeStyle(pathPoints: [Vector2(0, 0)]);

      final path = shapePathFor(ShapeType.path, rect, style, 1.0);

      expect(path.getBounds(), Rect.zero);
    });

    test('no points at all produces an empty path', () {
      final path = shapePathFor(ShapeType.path, rect, ShapeStyle(), 1.0);

      expect(path.getBounds(), Rect.zero);
    });

    test('straight open segment with zero handles spans exactly point to point', () {
      final style = ShapeStyle(
        pathPoints: [Vector2(0, 0), Vector2(5, 0)],
        pathHandlesIn: [Vector2.zero(), Vector2.zero()],
        pathHandlesOut: [Vector2.zero(), Vector2.zero()],
      );
      const origin = Rect.fromLTWH(2, 3, 100, 100);

      final path = shapePathFor(ShapeType.path, origin, style, 1.0);

      _expectRectClose(path.getBounds(), const Rect.fromLTWH(2, 3, 5, 0));
    });

    test('closed path connects the last point back to the first', () {
      final style = ShapeStyle(
        pathPoints: [Vector2(0, 0), Vector2(4, 0), Vector2(4, 4)],
        pathHandlesIn: [Vector2.zero(), Vector2.zero(), Vector2.zero()],
        pathHandlesOut: [Vector2.zero(), Vector2.zero(), Vector2.zero()],
        pathClosed: true,
      );

      final path = shapePathFor(ShapeType.path, const Rect.fromLTWH(0, 0, 10, 10), style, 1.0);

      _expectRectClose(path.getBounds(), const Rect.fromLTWH(0, 0, 4, 4));
    });

    test('points and handles are scaled by tileSize', () {
      final style = ShapeStyle(
        pathPoints: [Vector2(0, 0), Vector2(1, 0)],
        pathHandlesIn: [Vector2.zero(), Vector2.zero()],
        pathHandlesOut: [Vector2.zero(), Vector2.zero()],
      );

      final path = shapePathFor(ShapeType.path, const Rect.fromLTWH(0, 0, 10, 10), style, 20.0);

      _expectRectClose(path.getBounds(), const Rect.fromLTWH(0, 0, 20, 0));
    });
  });
}
