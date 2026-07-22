import 'package:flame/components.dart';
import 'package:leyak_lvl_editor/editor/geometry/grid_rect.dart';
import 'package:leyak_lvl_editor/editor/models/level_entity.dart';

/// Єдина відповідальність — зберігання та пошук [LevelEntity].
class EntityRepository {
  final List<LevelEntity> _entities = [];

  /// Викликається після додавання нової сутності. Не залежить від Flutter —
  /// UI-шар підписується на це через [SceneCubit].
  void Function()? onChanged;

  List<LevelEntity> get all => List.unmodifiable(_entities);

  void add(LevelEntity entity) {
    _entities.add(entity);
    onChanged?.call();
  }

  LevelEntity? findAt(Vector2 cell) {
    for (var i = _entities.length - 1; i >= 0; i--) {
      final entity = _entities[i];
      if (!entity.isVisible) continue;

      final pos = entity.transform.position;
      final size = entity.transform.size;

      if (cell.x >= pos.x &&
          cell.x < pos.x + size.x &&
          cell.y >= pos.y &&
          cell.y < pos.y + size.y) {
        return entity;
      }
    }
    return null;
  }

  List<LevelEntity> findWithin(GridRect region) {
    return _entities
        .where(
          (entity) =>
              entity.isVisible &&
              region.intersects(entity.transform.position, entity.transform.size),
        )
        .toList();
  }

  List<LevelEntity> get sortedByLayer =>
      List<LevelEntity>.from(_entities)..sort((a, b) => a.layer.compareTo(b.layer));
}
