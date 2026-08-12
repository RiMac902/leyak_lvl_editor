import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leyak_lvl_editor/editor/geometry/vector_transform.dart';

void main() {
  group('rotateScale', () {
    test('applies scale without rotation', () {
      final result = rotateScale(Vector2(2, 3), 0, Vector2(2, 0.5));

      expect(result.x, closeTo(4, 1e-9));
      expect(result.y, closeTo(1.5, 1e-9));
    });

    test('rotates a unit vector by 90 degrees', () {
      final result = rotateScale(Vector2(1, 0), math.pi / 2, Vector2.all(1.0));

      expect(result.x, closeTo(0, 1e-9));
      expect(result.y, closeTo(1, 1e-9));
    });

    test('applies scale before rotation', () {
      final result = rotateScale(Vector2(1, 0), math.pi / 2, Vector2(2, 1));

      expect(result.x, closeTo(0, 1e-9));
      expect(result.y, closeTo(2, 1e-9));
    });

    test('identity transform leaves point unchanged', () {
      final result = rotateScale(Vector2(3, 4), 0, Vector2.all(1.0));

      expect(result.x, closeTo(3, 1e-9));
      expect(result.y, closeTo(4, 1e-9));
    });
  });
}
