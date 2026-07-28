import 'package:flame/components.dart';
import 'package:leyak_lvl_editor/editor/geometry/grid_rect.dart';
import 'package:leyak_lvl_editor/editor/models/level_entity.dart';

/// Єдина відповідальність — зберігання та пошук [LevelEntity].
///
/// [resolveGroupOffset] лінивий колбек (як у [GridCoordinateConverter]),
/// що повертає поточну позицію групи за її id — потрібен лише для того,
/// щоб hit-test (findAt/findWithin) рахував абсолютну позицію згрупованих
/// сутностей, чия [TransformData.position] після групування зберігається
/// відносно піврота групи.
class EntityRepository {
  EntityRepository({Vector2 Function(String groupId)? resolveGroupOffset})
    : _resolveGroupOffset = resolveGroupOffset ?? ((_) => Vector2.zero());

  final List<LevelEntity> _entities = [];
  final Vector2 Function(String groupId) _resolveGroupOffset;

  /// Викликається після будь-якої зміни списку. Не залежить від Flutter —
  /// UI-шар підписується на це через [SceneCubit].
  void Function()? onChanged;

  /// Викликаються з конкретною сутністю, що з'явилась/зникла — щоб
  /// [SceneComponentRegistry] міг точково створити/прибрати компонент,
  /// не порівнюючи весь список щокадру.
  void Function(LevelEntity entity)? onEntityAdded;
  void Function(LevelEntity entity)? onEntityRemoved;

  List<LevelEntity> get all => List.unmodifiable(_entities);

  void add(LevelEntity entity) {
    _entities.add(entity);
    onEntityAdded?.call(entity);
    onChanged?.call();
  }

  void remove(LevelEntity entity) {
    _entities.remove(entity);
    onEntityRemoved?.call(entity);
    onChanged?.call();
  }

  /// Повністю замінює список (для відновлення знімка при undo/redo).
  /// Викликає ті самі колбеки, що й [add]/[remove], по одному на сутність —
  /// щоб [SceneComponentRegistry] і надалі точково створював/прибирав
  /// компоненти, а не отримував "магічний" стрибок стану без пояснення.
  void replaceAll(List<LevelEntity> newEntities) {
    for (final entity in List.of(_entities)) {
      _entities.remove(entity);
      onEntityRemoved?.call(entity);
    }
    for (final entity in newEntities) {
      _entities.add(entity);
      onEntityAdded?.call(entity);
    }
    onChanged?.call();
  }

  /// Позиція сутності в світових координатах сітки, з урахуванням піврота
  /// групи, якщо сутність згрупована (див. клас-документацію).
  Vector2 absolutePositionOf(LevelEntity entity) {
    final groupId = entity.groupId;
    if (groupId == null) return entity.transform.position;
    return entity.transform.position + _resolveGroupOffset(groupId);
  }

  List<LevelEntity> membersOf(String groupId) =>
      _entities.where((entity) => entity.groupId == groupId).toList();

  LevelEntity? findAt(Vector2 cell) {
    for (var i = _entities.length - 1; i >= 0; i--) {
      final entity = _entities[i];
      if (!entity.isVisible) continue;

      final pos = absolutePositionOf(entity);
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
              entity.isVisible && region.intersects(absolutePositionOf(entity), entity.transform.size),
        )
        .toList();
  }

  List<LevelEntity> get sortedByLayer =>
      List<LevelEntity>.from(_entities)..sort((a, b) => a.layer.compareTo(b.layer));
}
