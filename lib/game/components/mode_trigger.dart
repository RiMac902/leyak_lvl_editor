import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:leyak_lvl_editor/editor/models/level_entity.dart';
import 'package:leyak_lvl_editor/game/components/player.dart';
import 'package:leyak_lvl_editor/game/player_mode.dart';

/// Вузький пасивний хітбокс-портал: при перетині з [Player] викликає
/// [Player.setMode] і видаляє себе (одноразовий, [_triggered] боронить від
/// повторного спрацювання в той самий кадр перекриття).
class ModeTrigger extends PositionComponent with CollisionCallbacks {
  ModeTrigger(this.entity, this.mode, {required this.tileSize});

  final LevelEntity entity;
  final PlayerMode mode;
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
    other.setMode(mode);
    removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      Paint()..color = const Color(0x664FC3F7),
    );
  }
}
