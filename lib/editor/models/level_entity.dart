import 'package:leyak_lvl_editor/editor/models/entity_type.dart';
import 'package:leyak_lvl_editor/editor/models/transform_data.dart';
import 'package:leyak_lvl_editor/editor/models/visual_data.dart';

class LevelEntity {
  final String id;
  final EntityType type;
  final TransformData transform;
  final VisualData visual;
  final Map<String, dynamic> customProperties;

  int layer;
  String? groupId;
  bool isVisible;

  LevelEntity({
    required this.id,
    required this.type,
    TransformData? transform,
    VisualData? visual,
    Map<String, dynamic>? customProperties,
    this.layer = 0,
    this.groupId,
    this.isVisible = true,
  }) : transform = transform ?? TransformData(),
       visual = visual ?? VisualData(),
       customProperties = customProperties ?? {};

  LevelEntity.create(EntityType type)
    : this(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: type,
        transform: TransformData(),
        visual: VisualData(),
        customProperties: {},
      );
}
