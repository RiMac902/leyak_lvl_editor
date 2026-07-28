import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:leyak_lvl_editor/editor/entities/entity_repository.dart';
import 'package:leyak_lvl_editor/editor/entities/group_repository.dart';
import 'package:leyak_lvl_editor/editor/models/level_entity.dart';
import 'package:leyak_lvl_editor/editor/models/level_group.dart';
import 'package:leyak_lvl_editor/editor/models/transform_data.dart';
import 'package:leyak_lvl_editor/editor/models/visual_data.dart';

/// Незалежний від Flame знімок однієї [LevelEntity] — глибока копія всіх
/// полів, потрібних, щоб відновити її точно такою ж, якою вона була.
class EntitySnapshot {
  EntitySnapshot._({
    required this.id,
    required this.position,
    required this.rotation,
    required this.scale,
    required this.size,
    required this.color,
    required this.customProperties,
    required this.layer,
    required this.groupId,
    required this.isVisible,
  });

  factory EntitySnapshot.of(LevelEntity entity) => EntitySnapshot._(
    id: entity.id,
    position: entity.transform.position.clone(),
    rotation: entity.transform.rotation,
    scale: entity.transform.scale.clone(),
    size: entity.transform.size.clone(),
    color: entity.visual.color,
    customProperties: Map<String, dynamic>.of(entity.customProperties),
    layer: entity.layer,
    groupId: entity.groupId,
    isVisible: entity.isVisible,
  );

  final String id;
  final Vector2 position;
  final double rotation;
  final Vector2 scale;
  final Vector2 size;
  final Color color;
  final Map<String, dynamic> customProperties;
  final int layer;
  final String? groupId;
  final bool isVisible;

  LevelEntity toEntity() => LevelEntity(
    id: id,
    transform: TransformData(
      position: position.clone(),
      rotation: rotation,
      scale: scale.clone(),
      size: size.clone(),
    ),
    visual: VisualData(color: color),
    customProperties: Map<String, dynamic>.of(customProperties),
    layer: layer,
    groupId: groupId,
    isVisible: isVisible,
  );
}

/// Знімок однієї [LevelGroup].
class GroupSnapshot {
  GroupSnapshot._({
    required this.id,
    required this.position,
    required this.rotation,
    required this.scale,
  });

  factory GroupSnapshot.of(LevelGroup group) => GroupSnapshot._(
    id: group.id,
    position: group.position.clone(),
    rotation: group.rotation,
    scale: group.scale.clone(),
  );

  final String id;
  final Vector2 position;
  final double rotation;
  final Vector2 scale;

  LevelGroup toGroup() =>
      LevelGroup(id: id, position: position.clone(), rotation: rotation, scale: scale.clone());
}

/// Незалежний від Flame знімок усієї сцени в один момент часу — одиниця
/// undo/redo-історії в [HistoryController].
class SceneSnapshot {
  SceneSnapshot._(this.entities, this.groups);

  factory SceneSnapshot.capture(EntityRepository entities, GroupRepository groups) => SceneSnapshot._(
    entities.all.map(EntitySnapshot.of).toList(),
    groups.all.map(GroupSnapshot.of).toList(),
  );

  final List<EntitySnapshot> entities;
  final List<GroupSnapshot> groups;
}
