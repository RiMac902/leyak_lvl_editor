import 'package:flame/components.dart';
import 'package:leyak_lvl_editor/editor/models/level_entity.dart';
import 'package:leyak_lvl_editor/editor/models/level_group.dart';

/// "Запікає" [LevelEntity.transform.scale] у реальний [TransformData.size]
/// (і зсуває [TransformData.position], щоб центр фігури лишився на місці —
/// вона ж масштабується навколо центру), скидаючи сам [scale] назад у
/// (1,1). Без цього scale лишався б чисто візуальним множником: hit-test,
/// marquee й снепінг рахують лише [size]/[position], тож після
/// масштабування через гізмо об'єкт виглядав би одного розміру, а
/// клікався/снепився — за старим, немасштабованим.
void bakeEntityScale(LevelEntity entity) {
  final scale = entity.transform.scale;
  if (scale.x == 1.0 && scale.y == 1.0) return;

  final oldSize = entity.transform.size;
  final scaleAbs = Vector2(scale.x.abs(), scale.y.abs());
  final newSize = Vector2(oldSize.x * scaleAbs.x, oldSize.y * scaleAbs.y);
  final center = entity.transform.position + oldSize / 2;

  entity.transform
    ..position = center - newSize / 2
    ..size = newSize
    ..scale = Vector2.all(1.0);
}

/// Те саме, що [bakeEntityScale], але для [LevelGroup]: розганяє
/// [LevelGroup.scale] по відносних (до піврота групи) position/size усіх
/// [members], а сам [LevelGroup.scale] скидає в (1,1).
void bakeGroupScale(LevelGroup group, List<LevelEntity> members) {
  final scale = group.scale;
  if (scale.x == 1.0 && scale.y == 1.0) return;

  for (final member in members) {
    final scaleAbs = Vector2(scale.x.abs(), scale.y.abs());
    member.transform
      ..position = Vector2(
        member.transform.position.x * scale.x,
        member.transform.position.y * scale.y,
      )
      ..size = Vector2(
        member.transform.size.x * scaleAbs.x,
        member.transform.size.y * scaleAbs.y,
      );
  }

  group.scale = Vector2.all(1.0);
}
