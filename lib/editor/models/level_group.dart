import 'package:flame/components.dart';

/// Постійна група сутностей. Членство не зберігається тут — воно завжди
/// читається "наживо" з [LevelEntity.groupId], щоб не тримати дві копії
/// одного й того самого списку. [position] — це піврот (центр bounding-box
/// на момент групування), відносно якого позиціонуються члени групи.
class LevelGroup {
  LevelGroup({required this.id, required this.position, this.rotation = 0.0, Vector2? scale})
    : scale = scale ?? Vector2.all(1.0);

  final String id;
  Vector2 position;
  double rotation;
  Vector2 scale;
}
