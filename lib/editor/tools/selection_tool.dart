import 'package:flame/components.dart';
import 'package:leyak_lvl_editor/editor/entities/entity_repository.dart';
import 'package:leyak_lvl_editor/editor/geometry/grid_coordinate_converter.dart';
import 'package:leyak_lvl_editor/editor/geometry/grid_rect.dart';
import 'package:leyak_lvl_editor/editor/models/level_entity.dart';
import 'package:leyak_lvl_editor/editor/tools/editor_tool.dart';

/// Єдина відповідальність — інструмент "виділення та переміщення":
/// клік-виділення, рамка виділення (marquee) і рух виділених об'єктів.
class SelectionTool implements EditorTool {
  SelectionTool(this._repository, this._converter);

  final EntityRepository _repository;
  final GridCoordinateConverter _converter;

  final List<LevelEntity> selected = [];

  Vector2? _dragStartCell;
  final Map<LevelEntity, Vector2> _originalPositions = {};

  Vector2? marqueeStart;
  Vector2? marqueeCurrent;

  @override
  void dragStart(Vector2 worldPos) {
    final cell = _converter.worldToGrid(worldPos);
    final clicked = _repository.findAt(cell);

    if (clicked != null) {
      if (!selected.contains(clicked)) {
        selected
          ..clear()
          ..add(clicked);
      }

      _dragStartCell = cell;
      _originalPositions.clear();
      for (final entity in selected) {
        _originalPositions[entity] = entity.transform.position.clone();
      }
    } else {
      selected.clear();
      marqueeStart = cell;
      marqueeCurrent = cell;
    }
  }

  @override
  void dragUpdate(Vector2 worldPos) {
    final currentCell = _converter.worldToGrid(worldPos);

    if (_dragStartCell != null && _originalPositions.isNotEmpty) {
      final delta = currentCell - _dragStartCell!;
      for (final entity in selected) {
        final original = _originalPositions[entity];
        if (original != null) {
          entity.transform.position = original + delta;
        }
      }
    } else if (marqueeStart != null) {
      marqueeCurrent = currentCell;
    }
  }

  @override
  void dragEnd() {
    if (marqueeStart != null && marqueeCurrent != null) {
      final region = GridRect.fromCorners(marqueeStart!, marqueeCurrent!);
      selected
        ..clear()
        ..addAll(_repository.findWithin(region));
    }

    _originalPositions.clear();
    _dragStartCell = null;
    marqueeStart = null;
    marqueeCurrent = null;
  }
}
