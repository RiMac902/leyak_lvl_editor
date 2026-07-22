import 'package:flutter/material.dart';
import 'package:leyak_lvl_editor/editor/models/transform_data.dart';
import 'package:leyak_lvl_editor/editor/models/visual_data.dart';

/// Абстрактна фігура сцени. Її поведінка (solid, deadly, декор тощо)
/// визначається виключно [customProperties] — немає жорсткого типу.
class LevelEntity {
  final String id;
  final TransformData transform;
  final VisualData visual;
  final Map<String, dynamic> customProperties;

  int layer;
  String? groupId;
  bool isVisible;

  LevelEntity({
    required this.id,
    TransformData? transform,
    VisualData? visual,
    Map<String, dynamic>? customProperties,
    this.layer = 0,
    this.groupId,
    this.isVisible = true,
  }) : transform = transform ?? TransformData(),
       visual = visual ?? VisualData(),
       customProperties = customProperties ?? {};

  LevelEntity.create({Map<String, dynamic>? customProperties, Color? color})
    : this(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        transform: TransformData(),
        visual: VisualData(color: color ?? Colors.grey),
        customProperties: customProperties == null
            ? {}
            : Map<String, dynamic>.from(customProperties),
      );
}
