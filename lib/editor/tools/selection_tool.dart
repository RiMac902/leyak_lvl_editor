import 'package:flame/components.dart';
import 'package:leyak_lvl_editor/editor/entities/entity_repository.dart';
import 'package:leyak_lvl_editor/editor/entities/grouping_service.dart';
import 'package:leyak_lvl_editor/editor/geometry/grid_coordinate_converter.dart';
import 'package:leyak_lvl_editor/editor/geometry/grid_rect.dart';
import 'package:leyak_lvl_editor/editor/models/level_entity.dart';
import 'package:leyak_lvl_editor/editor/tools/editor_tool.dart';

/// Єдина відповідальність — інструмент "виділення та переміщення":
/// клік-виділення, рамка виділення (marquee) і рух виділених об'єктів.
/// Клік/marquee по учаснику постійної групи виділяє всю групу цілком.
class SelectionTool implements EditorTool {
  SelectionTool(this._repository, this._converter, this._groupingService);

  final EntityRepository _repository;
  final GridCoordinateConverter _converter;
  final GroupingService _groupingService;

  final List<LevelEntity> selected = [];

  /// Викликається, коли змінюється виділення або завершується рух
  /// об'єктів. Не залежить від Flutter — UI підписується через
  /// [SceneCubit].
  void Function()? onChanged;

  /// Викликається перед тим, як розпочнеться рух виділених об'єктів (не
  /// перед marquee, де дані не змінюються) — композиційний корінь
  /// підключає сюди [HistoryController.checkpoint].
  void Function()? beforeMove;

  Vector2? _dragStartCell;
  final Map<LevelEntity, Vector2> _originalPositions = {};

  /// Якщо поточне виділення — рівно повна група, рух зсуває піврот групи
  /// (а не позицію кожного члена окремо) — див. [GroupingService].
  Vector2? _groupOriginalPosition;

  Vector2? marqueeStart;
  Vector2? marqueeCurrent;

  void _selectMembersOf(LevelEntity entity) {
    final groupId = entity.groupId;
    selected.clear();
    if (groupId != null) {
      selected.addAll(_repository.membersOf(groupId));
    } else {
      selected.add(entity);
    }
  }

  @override
  void dragStart(Vector2 worldPos) {
    final cell = _converter.worldToGrid(worldPos);
    final clicked = _repository.findAt(cell);

    if (clicked != null) {
      if (!selected.contains(clicked)) {
        _selectMembersOf(clicked);
      }

      beforeMove?.call();
      _dragStartCell = cell;
      _originalPositions.clear();

      final group = _groupingService.fullGroupSelectionOf(selected);
      if (group != null) {
        _groupOriginalPosition = group.position.clone();
      } else {
        _groupOriginalPosition = null;
        for (final entity in selected) {
          _originalPositions[entity] = entity.transform.position.clone();
        }
      }
    } else {
      selected.clear();
      marqueeStart = cell;
      marqueeCurrent = cell;
    }

    onChanged?.call();
  }

  @override
  void dragUpdate(Vector2 worldPos) {
    final currentCell = _converter.worldToGrid(worldPos);

    if (_dragStartCell != null) {
      final delta = currentCell - _dragStartCell!;
      final groupOriginal = _groupOriginalPosition;
      if (groupOriginal != null) {
        final group = _groupingService.fullGroupSelectionOf(selected);
        group?.position = groupOriginal + delta;
      } else if (_originalPositions.isNotEmpty) {
        for (final entity in selected) {
          final original = _originalPositions[entity];
          if (original != null) {
            entity.transform.position = original + delta;
          }
        }
      }
    } else if (marqueeStart != null) {
      marqueeCurrent = currentCell;
    }
  }

  @override
  void dragEnd() {
    if (marqueeStart != null && marqueeCurrent != null) {
      final region = GridRect.fromCorners(
        marqueeStart!,
        marqueeCurrent!,
        inclusive: _converter.snapping,
      );

      final expanded = <LevelEntity>{};
      for (final entity in _repository.findWithin(region)) {
        final groupId = entity.groupId;
        if (groupId != null) {
          expanded.addAll(_repository.membersOf(groupId));
        } else {
          expanded.add(entity);
        }
      }
      selected
        ..clear()
        ..addAll(expanded);
    }

    _originalPositions.clear();
    _groupOriginalPosition = null;
    _dragStartCell = null;
    marqueeStart = null;
    marqueeCurrent = null;

    onChanged?.call();
  }
}
