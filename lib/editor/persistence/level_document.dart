import 'dart:convert';

import 'package:flame/components.dart' show Vector2;
import 'package:flutter/material.dart';
import 'package:leyak_lvl_editor/editor/models/entity_part.dart';
import 'package:leyak_lvl_editor/editor/models/layer_folder.dart';
import 'package:leyak_lvl_editor/editor/models/level_entity.dart';
import 'package:leyak_lvl_editor/editor/models/level_group.dart';
import 'package:leyak_lvl_editor/editor/models/shape_style.dart';
import 'package:leyak_lvl_editor/editor/models/shape_type.dart';
import 'package:leyak_lvl_editor/editor/models/transform_data.dart';
import 'package:leyak_lvl_editor/editor/models/visual_data.dart';

/// Формат `.json`-файлу рівня на диску. Незалежний від [SceneSnapshot]
/// (той — знімок у пам'яті для undo/redo, тут — примітивні типи + версія
/// формату, призначені саме для збереження) — та сама ідея "плаский
/// знімок сцени", повторена окремо для іншої відповідальності, а не
/// перевикористана, щоб історія й диск-формат могли розвиватись незалежно.
const int levelFileFormatVersion = 1;

/// Кидається при спробі відкрити файл несумісної/невідомої версії
/// [levelFileFormatVersion] чи з пошкодженою структурою.
class LevelDocumentFormatException implements Exception {
  LevelDocumentFormatException(this.message);

  final String message;

  @override
  String toString() => 'LevelDocumentFormatException: $message';
}

class LevelDocument {
  const LevelDocument({
    required this.tileSize,
    required this.gridWidth,
    required this.gridLength,
    required this.entities,
    required this.groups,
    required this.folders,
  });

  final double tileSize;
  final int gridWidth;
  final int gridLength;
  final List<LevelEntity> entities;
  final List<LevelGroup> groups;
  final List<LayerFolder> folders;

  factory LevelDocument.fromJson(Map<String, dynamic> json) {
    final version = json['version'];
    if (version != levelFileFormatVersion) {
      throw LevelDocumentFormatException('Unsupported level file version: $version');
    }
    return LevelDocument(
      tileSize: (json['tileSize'] as num).toDouble(),
      gridWidth: json['gridWidth'] as int,
      gridLength: json['gridLength'] as int,
      entities: (json['entities'] as List)
          .map((e) => _entityFromJson(e as Map<String, dynamic>))
          .toList(),
      groups: (json['groups'] as List)
          .map((e) => _groupFromJson(e as Map<String, dynamic>))
          .toList(),
      folders: (json['folders'] as List)
          .map((e) => _folderFromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  factory LevelDocument.decode(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map<String, dynamic>) {
      throw LevelDocumentFormatException('Expected a JSON object at the top level');
    }
    return LevelDocument.fromJson(decoded);
  }

  Map<String, dynamic> toJson() => {
    'version': levelFileFormatVersion,
    'tileSize': tileSize,
    'gridWidth': gridWidth,
    'gridLength': gridLength,
    'entities': entities.map(_entityToJson).toList(),
    'groups': groups.map(_groupToJson).toList(),
    'folders': folders.map(_folderToJson).toList(),
  };

  String encode() => jsonEncode(toJson());
}

Map<String, dynamic> _vectorToJson(Vector2 v) => {'x': v.x, 'y': v.y};

Vector2 _vectorFromJson(Map<String, dynamic> json) =>
    Vector2((json['x'] as num).toDouble(), (json['y'] as num).toDouble());

Map<String, dynamic> _shapeStyleToJson(ShapeStyle style) => {
  'cornerRadii': style.cornerRadii,
  'lineThickness': style.lineThickness,
  'lineStart': _vectorToJson(style.lineStart),
  'lineEnd': _vectorToJson(style.lineEnd),
  'pathPoints': style.pathPoints.map(_vectorToJson).toList(),
  'pathHandlesIn': style.pathHandlesIn.map(_vectorToJson).toList(),
  'pathHandlesOut': style.pathHandlesOut.map(_vectorToJson).toList(),
  'pathClosed': style.pathClosed,
};

ShapeStyle _shapeStyleFromJson(Map<String, dynamic> json) => ShapeStyle(
  cornerRadii: (json['cornerRadii'] as List).map((e) => (e as num).toDouble()).toList(),
  lineThickness: (json['lineThickness'] as num).toDouble(),
  lineStart: _vectorFromJson(json['lineStart'] as Map<String, dynamic>),
  lineEnd: _vectorFromJson(json['lineEnd'] as Map<String, dynamic>),
  pathPoints: (json['pathPoints'] as List)
      .map((e) => _vectorFromJson(e as Map<String, dynamic>))
      .toList(),
  pathHandlesIn: (json['pathHandlesIn'] as List)
      .map((e) => _vectorFromJson(e as Map<String, dynamic>))
      .toList(),
  pathHandlesOut: (json['pathHandlesOut'] as List)
      .map((e) => _vectorFromJson(e as Map<String, dynamic>))
      .toList(),
  pathClosed: json['pathClosed'] as bool,
);

/// [VisualData.shaderParams]/[EntityPart.shaderParams] значення завжди
/// double ([ShaderParamType.number]) чи [Color] ([ShaderParamType.color]) —
/// JSON не розрізняє їх без явного тегу, тож кожне значення кодується як
/// `{"t": "n"|"c", "v": ...}` (число як є, колір як 32-бітний ARGB int).
Map<String, dynamic> _shaderParamsToJson(Map<String, Object> params) => {
  for (final entry in params.entries)
    entry.key: entry.value is Color
        ? {'t': 'c', 'v': (entry.value as Color).toARGB32()}
        : {'t': 'n', 'v': entry.value as double},
};

Map<String, Object> _shaderParamsFromJson(Map<String, dynamic> json) => {
  for (final entry in json.entries)
    entry.key: (() {
      final tagged = entry.value as Map<String, dynamic>;
      return tagged['t'] == 'c' ? Color(tagged['v'] as int) : (tagged['v'] as num).toDouble();
    })(),
};

Map<String, dynamic> _partToJson(EntityPart part) => {
  'relativePosition': _vectorToJson(part.relativePosition),
  'size': _vectorToJson(part.size),
  'color': part.color.toARGB32(),
  'shapeType': part.shapeType.name,
  'shapeStyle': _shapeStyleToJson(part.shapeStyle),
  'shaderId': part.shaderId,
  'videoPath': part.videoPath,
  'shaderParams': _shaderParamsToJson(part.shaderParams),
};

EntityPart _partFromJson(Map<String, dynamic> json) => EntityPart(
  relativePosition: _vectorFromJson(json['relativePosition'] as Map<String, dynamic>),
  size: _vectorFromJson(json['size'] as Map<String, dynamic>),
  color: Color(json['color'] as int),
  shapeType: ShapeType.values.byName(json['shapeType'] as String),
  shapeStyle: _shapeStyleFromJson(json['shapeStyle'] as Map<String, dynamic>),
  shaderId: json['shaderId'] as String?,
  videoPath: json['videoPath'] as String?,
  shaderParams: _shaderParamsFromJson(json['shaderParams'] as Map<String, dynamic>),
);

Map<String, dynamic> _entityToJson(LevelEntity entity) => {
  'id': entity.id,
  'position': _vectorToJson(entity.transform.position),
  'rotation': entity.transform.rotation,
  'scale': _vectorToJson(entity.transform.scale),
  'size': _vectorToJson(entity.transform.size),
  'color': entity.visual.color.toARGB32(),
  'spritePath': entity.visual.spritePath,
  'shaderId': entity.visual.shaderId,
  'videoPath': entity.visual.videoPath,
  'shaderParams': _shaderParamsToJson(entity.visual.shaderParams),
  'customProperties': entity.customProperties,
  'parts': entity.parts?.map(_partToJson).toList(),
  'layer': entity.layer,
  'groupId': entity.groupId,
  'layerFolderId': entity.layerFolderId,
  'isVisible': entity.isVisible,
  'isLocked': entity.isLocked,
  'shapeType': entity.shapeType.name,
  'shapeStyle': _shapeStyleToJson(entity.shapeStyle),
};

LevelEntity _entityFromJson(Map<String, dynamic> json) => LevelEntity(
  id: json['id'] as String,
  transform: TransformData(
    position: _vectorFromJson(json['position'] as Map<String, dynamic>),
    rotation: (json['rotation'] as num).toDouble(),
    scale: _vectorFromJson(json['scale'] as Map<String, dynamic>),
    size: _vectorFromJson(json['size'] as Map<String, dynamic>),
  ),
  visual: VisualData(
    spritePath: json['spritePath'] as String?,
    shaderId: json['shaderId'] as String?,
    videoPath: json['videoPath'] as String?,
    color: Color(json['color'] as int),
    shaderParams: _shaderParamsFromJson(json['shaderParams'] as Map<String, dynamic>),
  ),
  customProperties: Map<String, dynamic>.of(json['customProperties'] as Map<String, dynamic>),
  parts: (json['parts'] as List?)?.map((e) => _partFromJson(e as Map<String, dynamic>)).toList(),
  layer: json['layer'] as int,
  groupId: json['groupId'] as String?,
  layerFolderId: json['layerFolderId'] as String?,
  shapeType: ShapeType.values.byName(json['shapeType'] as String),
  shapeStyle: _shapeStyleFromJson(json['shapeStyle'] as Map<String, dynamic>),
  isVisible: json['isVisible'] as bool,
  isLocked: json['isLocked'] as bool,
);

Map<String, dynamic> _groupToJson(LevelGroup group) => {
  'id': group.id,
  'position': _vectorToJson(group.position),
  'rotation': group.rotation,
  'scale': _vectorToJson(group.scale),
};

LevelGroup _groupFromJson(Map<String, dynamic> json) => LevelGroup(
  id: json['id'] as String,
  position: _vectorFromJson(json['position'] as Map<String, dynamic>),
  rotation: (json['rotation'] as num).toDouble(),
  scale: _vectorFromJson(json['scale'] as Map<String, dynamic>),
);

Map<String, dynamic> _folderToJson(LayerFolder folder) => {
  'id': folder.id,
  'name': folder.name,
  'isExpanded': folder.isExpanded,
  'isBackground': folder.isBackground,
};

LayerFolder _folderFromJson(Map<String, dynamic> json) => LayerFolder(
  id: json['id'] as String,
  name: json['name'] as String,
  isExpanded: json['isExpanded'] as bool,
  isBackground: json['isBackground'] as bool,
);
