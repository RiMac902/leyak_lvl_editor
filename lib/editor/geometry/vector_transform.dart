import 'dart:math' as math;

import 'package:flame/components.dart';

/// Єдина відповідальність — застосувати обертання й масштаб до точки.
/// Потрібен лише для одноразового "запікання" відносної позиції члена
/// групи в абсолютну при розгрупуванні — під час звичайного руху/обертання
/// цю математику за нас робить композиція трансформів у дереві Flame.
Vector2 rotateScale(Vector2 point, double angle, Vector2 scale) {
  final scaled = Vector2(point.x * scale.x, point.y * scale.y);
  final cosA = math.cos(angle);
  final sinA = math.sin(angle);
  return Vector2(
    scaled.x * cosA - scaled.y * sinA,
    scaled.x * sinA + scaled.y * cosA,
  );
}
