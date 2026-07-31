import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:leyak_lvl_editor/editor/models/level_entity.dart';

/// Пасивний хітбокс — [Player.onCollisionStart] розпізнає цей тип і
/// викликає перемогу. Сам нічого не робить при зіткненні (на відміну від
/// [ModeTrigger]/[SpeedTrigger]) — Player сам вирішує, що робити з фінішем.
class FinishLine extends PositionComponent {
  FinishLine(this.entity, {required this.tileSize});

  final LevelEntity entity;
  final double tileSize;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    position = entity.transform.position * tileSize;
    size = entity.transform.size * tileSize;
    add(RectangleHitbox()..collisionType = CollisionType.passive);
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      Paint()..color = const Color(0x8800E676),
    );
  }
}
