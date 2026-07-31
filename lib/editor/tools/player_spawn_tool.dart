import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:leyak_lvl_editor/editor/entities/entity_repository.dart';
import 'package:leyak_lvl_editor/editor/geometry/grid_coordinate_converter.dart';
import 'package:leyak_lvl_editor/editor/models/level_entity.dart';
import 'package:leyak_lvl_editor/editor/models/shape_type.dart';
import 'package:leyak_lvl_editor/editor/tools/editor_tool.dart';

/// Єдина відповідальність — інструмент "клацни, щоб поставити точку
/// старту гравця". Клік-only ("stamp"): уся дія відбувається в
/// [dragStart], [dragUpdate]/[dragEnd] нічого не роблять — той самий
/// принцип, на якому вже працює клік-вибір у [SelectionTool] (драг без
/// переміщення все одно викликає dragStart/dragEnd).
///
/// "Лише одна точка старту на рівень" забезпечується тим, що кожен клік
/// видаляє попередню (якщо вона є) й додає нову на новому місці — тобто
/// повторний клік просто ПЕРЕНОСИТЬ єдину точку старту, а не створює
/// другу. Без окремої валідації/помилки — так ергономічніше.
class PlayerSpawnTool implements EditorTool {
  PlayerSpawnTool(this._repository, this._converter);

  final EntityRepository _repository;
  final GridCoordinateConverter _converter;

  /// Викликається перед кожною зміною репозиторію — композиційний корінь
  /// підключає сюди [HistoryController.checkpoint].
  void Function()? beforeCommit;

  @override
  void dragStart(Vector2 worldPos) {
    final cell = _converter.worldToGrid(worldPos);

    beforeCommit?.call();

    final existing = _repository.all
        .where((e) => e.customProperties['isPlayerSpawn'] == true)
        .toList();
    for (final spawn in existing) {
      _repository.remove(spawn);
    }

    final spawn = LevelEntity.create(
      customProperties: {'isPlayerSpawn': true},
      color: const Color(0xFF4FC3F7),
      shapeType: ShapeType.ellipse,
    )
      ..transform.position = cell
      ..layer = _repository.nextLayer;
    _repository.add(spawn);
  }

  @override
  void dragUpdate(Vector2 worldPos) {}

  @override
  void dragEnd() {}
}
