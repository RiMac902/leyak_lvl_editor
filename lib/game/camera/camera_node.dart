import 'package:flame/components.dart';
import 'package:leyak_lvl_editor/editor/models/level_entity.dart';

/// Один вузол шляху камери — незмінний знімок даних одного `LevelEntity`
/// з `customProperties['isCameraNode'] == true` (розставляється
/// `CameraNodeTool` в редакторі), спожитий [CameraPathController].
class CameraNode {
  const CameraNode({
    required this.x,
    required this.zoom,
    required this.offset,
    required this.transitionDuration,
  });

  /// Позиція вузла вздовж рівня, у пікселях (те саме `tileSize`, що й уся
  /// інша геометрія рівня) — за нею [CameraPathController] визначає, між
  /// якими двома вузлами зараз перебуває гравець.
  final double x;
  final double zoom;
  final Vector2 offset;
  final double transitionDuration;

  factory CameraNode.fromEntity(LevelEntity entity, double tileSize) {
    final props = entity.customProperties;
    return CameraNode(
      x: entity.transform.position.x * tileSize,
      zoom: (props['cameraZoom'] as double?) ?? 1.0,
      offset: Vector2(
        (props['cameraOffsetX'] as double?) ?? 0.0,
        (props['cameraOffsetY'] as double?) ?? 0.0,
      ),
      transitionDuration: (props['cameraTransitionDuration'] as double?) ?? 1.0,
    );
  }
}
