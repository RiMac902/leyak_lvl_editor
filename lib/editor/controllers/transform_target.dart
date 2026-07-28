import 'package:flame/components.dart';
import 'package:leyak_lvl_editor/editor/components/entity_component.dart';
import 'package:leyak_lvl_editor/editor/components/group_component.dart';
import 'package:leyak_lvl_editor/editor/models/level_entity.dart';
import 'package:leyak_lvl_editor/editor/models/level_group.dart';

/// Уніфікує "одна сутність" і "одна група" для гізмо трансформації, щоб
/// той не розгалужувався на entity-vs-group у власній логіці.
abstract class TransformTarget {
  Vector2 get pivotWorldPosition;

  /// Немасштабований, неповернутий розмір bounding-box у пікселях —
  /// стабільний протягом усього драгу (масштаб/поворот змінюють лише
  /// [scale]/[rotation], а не сам цей розмір).
  Vector2 get localSize;

  double get rotation;
  set rotation(double value);

  Vector2 get scale;
  set scale(Vector2 value);
}

class EntityTransformTarget implements TransformTarget {
  EntityTransformTarget(this.entity, this.component, this.tileSize);

  final LevelEntity entity;
  final EntityComponent component;
  final double tileSize;

  @override
  Vector2 get pivotWorldPosition => component.absolutePosition;

  @override
  Vector2 get localSize => entity.transform.size * tileSize;

  @override
  double get rotation => entity.transform.rotation;
  @override
  set rotation(double value) => entity.transform.rotation = value;

  @override
  Vector2 get scale => entity.transform.scale;
  @override
  set scale(Vector2 value) => entity.transform.scale = value;
}

class GroupTransformTarget implements TransformTarget {
  GroupTransformTarget(this.group, this.component, this.members, this.tileSize);

  final LevelGroup group;
  final GroupComponent component;
  final List<LevelEntity> members;
  final double tileSize;

  @override
  Vector2 get pivotWorldPosition => component.absolutePosition;

  @override
  Vector2 get localSize {
    var minX = double.infinity, minY = double.infinity;
    var maxX = -double.infinity, maxY = -double.infinity;
    for (final member in members) {
      final pos = member.transform.position;
      final size = member.transform.size;
      minX = minX < pos.x ? minX : pos.x;
      minY = minY < pos.y ? minY : pos.y;
      maxX = maxX > pos.x + size.x ? maxX : pos.x + size.x;
      maxY = maxY > pos.y + size.y ? maxY : pos.y + size.y;
    }
    return Vector2(maxX - minX, maxY - minY) * tileSize;
  }

  @override
  double get rotation => group.rotation;
  @override
  set rotation(double value) => group.rotation = value;

  @override
  Vector2 get scale => group.scale;
  @override
  set scale(Vector2 value) => group.scale = value;
}
