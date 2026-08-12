import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leyak_lvl_editor/editor/animation/position_smoothing.dart';

void main() {
  group('PositionSmoothing.step', () {
    test('does nothing when already at target', () {
      const smoothing = PositionSmoothing();
      final current = Vector2(3, 3);

      smoothing.step(current, Vector2(3, 3), 1 / 60);

      expect(current, Vector2(3, 3));
    });

    test('moves current towards target proportionally to dt * speed', () {
      const smoothing = PositionSmoothing(speed: 10.0, snapThreshold: 0.0);
      final current = Vector2(0, 0);

      smoothing.step(current, Vector2(10, 0), 0.1);

      expect(current.x, closeTo(10.0, 1e-9));
    });

    test('clamps the interpolation factor so it never overshoots the target', () {
      const smoothing = PositionSmoothing(speed: 100.0, snapThreshold: 0.0);
      final current = Vector2(0, 0);

      smoothing.step(current, Vector2(10, 0), 1.0);

      expect(current, Vector2(10, 0));
    });

    test('snaps to target once within snapThreshold to avoid endless creep', () {
      const smoothing = PositionSmoothing(speed: 14.0, snapThreshold: 0.5);
      final current = Vector2(0.1, 0);

      smoothing.step(current, Vector2(0, 0), 1 / 60);

      expect(current, Vector2.zero());
    });
  });
}
