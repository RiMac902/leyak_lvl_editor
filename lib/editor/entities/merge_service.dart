import 'package:flame/components.dart';
import 'package:leyak_lvl_editor/editor/models/entity_part.dart';
import 'package:leyak_lvl_editor/editor/models/level_entity.dart';
import 'package:leyak_lvl_editor/editor/models/transform_data.dart';
import 'package:leyak_lvl_editor/editor/models/visual_data.dart';

/// Єдина відповідальність — об'єднати кілька [LevelEntity] в одну складену
/// (compound) сутність, аналогічно `<g>` з декількома `<rect>` в SVG:
/// результат — ОДИН запис у [EntityRepository]/одна [EntityComponent], а
/// кожна колишня сутність стає [EntityPart] зі своїм кольором на своєму
/// місці. На відміну від групування ([GroupingService]), тут не потрібно,
/// щоб фігури утворювали суцільний прямокутник без дірок/накладань, чи
/// щоб кольори збігались — це довільна "картинка" з кількох шматків.
class MergeService {
  const MergeService();

  /// Повертає null, якщо об'єднати не можна: менше 2 сутностей, хтось із
  /// них уже в постійній групі (об'єднання з групами не підтримується —
  /// спершу розгрупуй), чи хтось повернутий/масштабований (для простоти
  /// перший реліз підтримує лише axis-aligned частини).
  LevelEntity? merge(List<LevelEntity> entities) {
    if (entities.length < 2) return null;
    if (entities.any((e) => e.groupId != null)) return null;
    if (entities.any(
      (e) => e.transform.rotation != 0 || e.transform.scale.x != 1 || e.transform.scale.y != 1,
    )) {
      return null;
    }

    var minX = double.infinity, minY = double.infinity;
    var maxX = -double.infinity, maxY = -double.infinity;
    for (final entity in entities) {
      final pos = entity.transform.position;
      final size = entity.transform.size;
      minX = minX < pos.x ? minX : pos.x;
      minY = minY < pos.y ? minY : pos.y;
      maxX = maxX > pos.x + size.x ? maxX : pos.x + size.x;
      maxY = maxY > pos.y + size.y ? maxY : pos.y + size.y;
    }
    final origin = Vector2(minX, minY);

    final parts = entities
        .map(
          (entity) => EntityPart(
            relativePosition: entity.transform.position - origin,
            size: entity.transform.size.clone(),
            color: entity.visual.color,
            shapeType: entity.shapeType,
            shapeStyle: entity.shapeStyle.clone(),
            shaderId: entity.visual.shaderId,
            videoPath: entity.visual.videoPath,
          ),
        )
        .toList();

    return LevelEntity(
      id: '${DateTime.now().microsecondsSinceEpoch}_merged',
      transform: TransformData(position: origin, size: Vector2(maxX - minX, maxY - minY)),
      visual: VisualData(color: entities.first.visual.color),
      parts: parts,
      // Найвищий шар серед об'єднаних — результат лишається там же,
      // де були найвищі з колишніх сутностей у стеку.
      layer: entities.map((e) => e.layer).reduce((a, b) => a > b ? a : b),
    );
  }
}
