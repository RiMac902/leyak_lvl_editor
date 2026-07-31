import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

/// Один примітив частинки — коло, що згасає й падає під [gravity].
/// Використовується і для вибуху смерті, і для іскор ковзання по землі
/// ([spawnDeathParticles]/[spawnGroundSparks]) — та сама форма, різні
/// параметри швидкості/гравітації/кольору/часу життя.
class Particle extends PositionComponent {
  Particle({
    required Vector2 position,
    required this.velocity,
    required this.gravity,
    required this.color,
    this.lifetime = 0.6,
    this.radius = 3,
  }) : super(position: position, size: Vector2.all(radius * 2), anchor: Anchor.center);

  Vector2 velocity;
  final Vector2 gravity;
  final Color color;
  final double lifetime;
  final double radius;

  double _age = 0;

  @override
  void update(double dt) {
    super.update(dt);
    velocity += gravity * dt;
    position += velocity * dt;
    _age += dt;
    if (_age >= lifetime) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final alpha = (1 - _age / lifetime).clamp(0.0, 1.0);
    canvas.drawCircle(Offset(radius, radius), radius, Paint()..color = color.withValues(alpha: alpha));
  }
}

/// Вибух частинок при смерті — розлітаються рівномірно по колу.
/// Гравітація `Vector2(0, 300)` — лише візуальна, не пов'язана з фізикою
/// гравця.
void spawnDeathParticles(Component host, Vector2 origin, {int count = 16}) {
  final random = math.Random();
  for (var i = 0; i < count; i++) {
    final angle = random.nextDouble() * 2 * math.pi;
    final speed = 80 + random.nextDouble() * 160;
    final velocity = Vector2(math.cos(angle), math.sin(angle)) * speed;
    host.add(
      Particle(
        position: origin.clone(),
        velocity: velocity,
        gravity: Vector2(0, 300),
        color: const Color(0xFFFF5252),
      ),
    );
  }
}

/// Іскри при ковзанні по землі — короткоживучі, летять трохи вгору й убік.
/// Гравітація `Vector2(0, 200)`.
void spawnGroundSparks(Component host, Vector2 origin) {
  final random = math.Random();
  for (var i = 0; i < 2; i++) {
    final velocity = Vector2((random.nextDouble() - 0.5) * 120, -random.nextDouble() * 80);
    host.add(
      Particle(
        position: origin.clone(),
        velocity: velocity,
        gravity: Vector2(0, 200),
        color: const Color(0xFFFFF176),
        lifetime: 0.3,
        radius: 2,
      ),
    );
  }
}
