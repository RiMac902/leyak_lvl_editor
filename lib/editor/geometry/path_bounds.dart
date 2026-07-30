import 'package:flame/components.dart';
import 'package:leyak_lvl_editor/editor/models/level_entity.dart';

/// Перераховує [LevelEntity.transform] `position`/`size` як щільний
/// bounding-box якірних точок [entity.shapeStyle.pathPoints] і "перебазовує"
/// самі точки так, щоб вони лишились відносними до НОВОЇ [position] —
/// решта коду (hit-test, Layers panel, гізмо-пivot) очікує, що
/// `transform.position` завжди top-left, а `transform.size` — реальний
/// охоплюючий прямокутник, так само як і для решти [ShapeType].
///
/// Навмисно рахує bbox лише по якорях, без bezier-хендлів — хендли рідко
/// виступають далеко за межі власного якоря, тож трохи вужчий hit-box —
/// прийнятне спрощення, а не помилка.
///
/// Викликати лише ПІСЛЯ завершення драгу (не щокадру під час самого
/// перетягування точки) — інакше [TransformData.position], що змінюється
/// щокадру, змушував би [PositionSmoothing] в [EntityComponent] постійно
/// доганяти рухому ціль, і драг відчувався б як загальмований.
void recomputePathBounds(LevelEntity entity) {
  final points = entity.shapeStyle.pathPoints;
  if (points.isEmpty) return;

  var minX = points.first.x, minY = points.first.y;
  var maxX = points.first.x, maxY = points.first.y;
  for (final point in points) {
    minX = minX < point.x ? minX : point.x;
    minY = minY < point.y ? minY : point.y;
    maxX = maxX > point.x ? maxX : point.x;
    maxY = maxY > point.y ? maxY : point.y;
  }

  final oldPosition = entity.transform.position;
  final newOrigin = Vector2(minX, minY);

  for (final point in points) {
    point.setValues(point.x - newOrigin.x, point.y - newOrigin.y);
  }

  entity.transform
    ..position = oldPosition + newOrigin
    ..size = Vector2(maxX - minX, maxY - minY);
}
