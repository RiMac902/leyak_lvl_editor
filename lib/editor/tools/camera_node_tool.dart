import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:leyak_lvl_editor/editor/entities/entity_repository.dart';
import 'package:leyak_lvl_editor/editor/geometry/grid_coordinate_converter.dart';
import 'package:leyak_lvl_editor/editor/models/level_entity.dart';
import 'package:leyak_lvl_editor/editor/models/shape_type.dart';
import 'package:leyak_lvl_editor/editor/tools/editor_tool.dart';

/// Той самий клік-only "stamp"-паттерн, що й [PlayerSpawnTool], лише
/// кожен клік ДОДАЄ новий вузол камери (без дедуплікації — шлях камери
/// складається з кількох вузлів). `cameraNodeOrder` — послідовний номер
/// (максимум наявних + 1, той самий підхід, що й
/// [EntityRepository.nextLayer]) визначає порядок вузлів уздовж шляху,
/// незалежно від того, як вони фактично розташовані по X — переміщення
/// вузла звичайним Select-інструментом не міняє його місце в послідовності.
class CameraNodeTool implements EditorTool {
  CameraNodeTool(this._repository, this._converter);

  final EntityRepository _repository;
  final GridCoordinateConverter _converter;

  /// Викликається перед кожним доданим вузлом — композиційний корінь
  /// підключає сюди [HistoryController.checkpoint].
  void Function()? beforeCommit;

  @override
  void dragStart(Vector2 worldPos) {
    final cell = _converter.worldToGrid(worldPos);

    beforeCommit?.call();

    final existingOrders = _repository.all
        .where((e) => e.customProperties['isCameraNode'] == true)
        .map((e) => e.customProperties['cameraNodeOrder'] as int? ?? 0);
    final nextOrder = existingOrders.isEmpty
        ? 0
        : existingOrders.reduce((a, b) => a > b ? a : b) + 1;

    final node = LevelEntity.create(
      customProperties: {
        'isCameraNode': true,
        'cameraZoom': 1.0,
        'cameraOffsetX': 0.0,
        'cameraOffsetY': 0.0,
        'cameraTransitionDuration': 1.0,
        'cameraNodeOrder': nextOrder,
      },
      color: const Color(0xFFFFC107),
      shapeType: ShapeType.ellipse,
    )
      ..transform.position = cell
      ..transform.size = Vector2.all(0.5)
      ..layer = _repository.nextLayer;
    _repository.add(node);
  }

  @override
  void dragUpdate(Vector2 worldPos) {}

  @override
  void dragEnd() {}
}
