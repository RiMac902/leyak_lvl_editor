import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:leyak_lvl_editor/editor/entities/entity_repository.dart';
import 'package:leyak_lvl_editor/editor/entities/group_repository.dart';
import 'package:leyak_lvl_editor/editor/entities/layer_folder_repository.dart';
import 'package:leyak_lvl_editor/editor/models/entity_part.dart';
import 'package:leyak_lvl_editor/editor/models/layer_folder.dart';
import 'package:leyak_lvl_editor/editor/models/level_entity.dart';
import 'package:leyak_lvl_editor/editor/models/level_group.dart';
import 'package:leyak_lvl_editor/editor/models/shape_style.dart';
import 'package:leyak_lvl_editor/editor/models/shape_type.dart';
import 'package:leyak_lvl_editor/editor/models/transform_data.dart';
import 'package:leyak_lvl_editor/editor/models/visual_data.dart';

/// Знімок [ShapeStyle].
class ShapeStyleSnapshot {
  ShapeStyleSnapshot._({
    required this.cornerRadii,
    required this.lineThickness,
    required this.lineStart,
    required this.lineEnd,
  });

  factory ShapeStyleSnapshot.of(ShapeStyle style) => ShapeStyleSnapshot._(
    cornerRadii: List<double>.of(style.cornerRadii),
    lineThickness: style.lineThickness,
    lineStart: style.lineStart.clone(),
    lineEnd: style.lineEnd.clone(),
  );

  final List<double> cornerRadii;
  final double lineThickness;
  final Vector2 lineStart;
  final Vector2 lineEnd;

  ShapeStyle toStyle() => ShapeStyle(
    cornerRadii: List<double>.of(cornerRadii),
    lineThickness: lineThickness,
    lineStart: lineStart.clone(),
    lineEnd: lineEnd.clone(),
  );
}

/// Знімок одного [EntityPart] складеної сутності.
class EntityPartSnapshot {
  EntityPartSnapshot._({
    required this.relativePosition,
    required this.size,
    required this.color,
    required this.shapeType,
    required this.shapeStyle,
    required this.shaderId,
    required this.videoPath,
    required this.shaderParams,
  });

  factory EntityPartSnapshot.of(EntityPart part) => EntityPartSnapshot._(
    relativePosition: part.relativePosition.clone(),
    size: part.size.clone(),
    color: part.color,
    shapeType: part.shapeType,
    shapeStyle: ShapeStyleSnapshot.of(part.shapeStyle),
    shaderId: part.shaderId,
    videoPath: part.videoPath,
    shaderParams: Map<String, Object>.of(part.shaderParams),
  );

  final Vector2 relativePosition;
  final Vector2 size;
  final Color color;
  final ShapeType shapeType;
  final ShapeStyleSnapshot shapeStyle;
  final String? shaderId;
  final String? videoPath;
  final Map<String, Object> shaderParams;

  EntityPart toPart() => EntityPart(
    relativePosition: relativePosition.clone(),
    size: size.clone(),
    color: color,
    shapeType: shapeType,
    shapeStyle: shapeStyle.toStyle(),
    shaderId: shaderId,
    videoPath: videoPath,
    shaderParams: Map<String, Object>.of(shaderParams),
  );
}

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
    required this.shapeType,
    required this.shapeStyle,
    required this.shaderId,
    required this.videoPath,
    required this.shaderParams,
    required this.customProperties,
    required this.parts,
    required this.layer,
    required this.groupId,
    required this.layerFolderId,
    required this.isVisible,
    required this.isLocked,
  });

  factory EntitySnapshot.of(LevelEntity entity) => EntitySnapshot._(
    id: entity.id,
    position: entity.transform.position.clone(),
    rotation: entity.transform.rotation,
    scale: entity.transform.scale.clone(),
    size: entity.transform.size.clone(),
    color: entity.visual.color,
    shapeType: entity.shapeType,
    shapeStyle: ShapeStyleSnapshot.of(entity.shapeStyle),
    shaderId: entity.visual.shaderId,
    videoPath: entity.visual.videoPath,
    shaderParams: Map<String, Object>.of(entity.visual.shaderParams),
    customProperties: Map<String, dynamic>.of(entity.customProperties),
    parts: entity.parts?.map(EntityPartSnapshot.of).toList(),
    layer: entity.layer,
    groupId: entity.groupId,
    layerFolderId: entity.layerFolderId,
    isVisible: entity.isVisible,
    isLocked: entity.isLocked,
  );

  final String id;
  final Vector2 position;
  final double rotation;
  final Vector2 scale;
  final Vector2 size;
  final Color color;
  final ShapeType shapeType;
  final ShapeStyleSnapshot shapeStyle;
  final String? shaderId;
  final String? videoPath;
  final Map<String, Object> shaderParams;
  final Map<String, dynamic> customProperties;
  final List<EntityPartSnapshot>? parts;
  final int layer;
  final String? groupId;
  final String? layerFolderId;
  final bool isVisible;
  final bool isLocked;

  LevelEntity toEntity() => LevelEntity(
    id: id,
    transform: TransformData(
      position: position.clone(),
      rotation: rotation,
      scale: scale.clone(),
      size: size.clone(),
    ),
    visual: VisualData(
      color: color,
      shaderId: shaderId,
      videoPath: videoPath,
      shaderParams: Map<String, Object>.of(shaderParams),
    ),
    shapeType: shapeType,
    shapeStyle: shapeStyle.toStyle(),
    customProperties: Map<String, dynamic>.of(customProperties),
    parts: parts?.map((p) => p.toPart()).toList(),
    layer: layer,
    groupId: groupId,
    layerFolderId: layerFolderId,
    isLocked: isLocked,
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

/// Знімок однієї [LayerFolder].
class LayerFolderSnapshot {
  LayerFolderSnapshot._({
    required this.id,
    required this.name,
    required this.isExpanded,
    required this.isBackground,
  });

  factory LayerFolderSnapshot.of(LayerFolder folder) => LayerFolderSnapshot._(
    id: folder.id,
    name: folder.name,
    isExpanded: folder.isExpanded,
    isBackground: folder.isBackground,
  );

  final String id;
  final String name;
  final bool isExpanded;
  final bool isBackground;

  LayerFolder toFolder() =>
      LayerFolder(id: id, name: name, isExpanded: isExpanded, isBackground: isBackground);
}

/// Незалежний від Flame знімок усієї сцени в один момент часу — одиниця
/// undo/redo-історії в [HistoryController].
class SceneSnapshot {
  SceneSnapshot._(this.entities, this.groups, this.layerFolders);

  factory SceneSnapshot.capture(
    EntityRepository entities,
    GroupRepository groups,
    LayerFolderRepository layerFolders,
  ) => SceneSnapshot._(
    entities.all.map(EntitySnapshot.of).toList(),
    groups.all.map(GroupSnapshot.of).toList(),
    layerFolders.all.map(LayerFolderSnapshot.of).toList(),
  );

  final List<EntitySnapshot> entities;
  final List<GroupSnapshot> groups;
  final List<LayerFolderSnapshot> layerFolders;
}
