import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:leyak_lvl_editor/editor/models/level_entity.dart';
import 'package:leyak_lvl_editor/game/components/player.dart';
import 'package:leyak_lvl_editor/game/speed_trigger_type.dart';

/// Той самий портал-паттерн, що й [ModeTrigger], лише викликає
/// [Player.setSpeedMultiplier].
class SpeedTrigger extends PositionComponent with CollisionCallbacks {
  SpeedTrigger(this.entity, this.type, {required this.tileSize});

  final LevelEntity entity;
  final SpeedTriggerType type;
  final double tileSize;

  bool _triggered = false;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    position = entity.transform.position * tileSize;
    size = entity.transform.size * tileSize;
    add(RectangleHitbox()..collisionType = CollisionType.passive);
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (_triggered || other is! Player) return;
    _triggered = true;
    other.setSpeedMultiplier(type.multiplier);
    removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      Paint()..color = const Color(0x66FFB74D),
    );
  }
}
