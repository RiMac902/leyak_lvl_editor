import 'package:flame/components.dart';

/// Єдина відповідальність — крок експоненційного згладжування однієї
/// точки до цілі. Використовується компонентами сутностей/груп, щоб рух
/// під час перетягування не виглядав стрибками між клітинками сітки.
class PositionSmoothing {
  const PositionSmoothing({this.speed = 14.0, this.snapThreshold = 0.02});

  /// Швидкість згладжування (частка відстані, яку долаємо за секунду).
  final double speed;
  final double snapThreshold;

  /// Змінює [current] на місці, наближаючи його до [target].
  void step(Vector2 current, Vector2 target, double dt) {
    if (current == target) return;

    final t = (dt * speed).clamp(0.0, 1.0);
    current.setValues(
      current.x + (target.x - current.x) * t,
      current.y + (target.y - current.y) * t,
    );

    if ((current - target).length < snapThreshold) {
      current.setFrom(target);
    }
  }
}
