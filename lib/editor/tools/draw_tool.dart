import 'package:flame/components.dart';
import 'package:leyak_lvl_editor/editor/entities/entity_repository.dart';
import 'package:leyak_lvl_editor/editor/geometry/grid_coordinate_converter.dart';
import 'package:leyak_lvl_editor/editor/geometry/grid_rect.dart';
import 'package:leyak_lvl_editor/editor/models/level_entity.dart';
import 'package:leyak_lvl_editor/editor/tools/editor_tool.dart';

/// Єдина відповідальність — інструмент "малювання": життєвий цикл
/// створення нової сутності перетягуванням по сітці. Нова сутність
/// завжди стартує з нейтральними властивостями — редагувати їх можна
/// пізніше через Inspector, коли об'єкт виділено.
class DrawTool implements EditorTool {
  DrawTool(this._repository, this._converter);

  final EntityRepository _repository;
  final GridCoordinateConverter _converter;

  /// Викликається безпосередньо перед тим, як нова сутність потрапляє в
  /// репозиторій — композиційний корінь підключає сюди
  /// [HistoryController.checkpoint], щоб малювання можна було скасувати.
  void Function()? beforeCommit;

  Vector2? _startCell;
  Vector2? origin;
  LevelEntity? entity;

  @override
  void dragStart(Vector2 worldPos) {
    final cell = _converter.worldToGrid(worldPos);
    _startCell = cell;
    origin = cell;
    entity = LevelEntity.create(
      customProperties: {'isSolid': false, 'isDeadly': false},
    )..transform.position = cell;
  }

  @override
  void dragUpdate(Vector2 worldPos) {
    if (entity == null || _startCell == null) return;

    final rect = GridRect.fromCorners(
      _startCell!,
      _converter.worldToGrid(worldPos),
      inclusive: _converter.snapping,
    );

    origin = rect.position;
    entity!.transform.position = rect.position;
    entity!.transform.size = rect.size;
  }

  @override
  void dragEnd() {
    if (entity != null) {
      beforeCommit?.call();
      _repository.add(entity!);
    }
    _startCell = null;
    origin = null;
    entity = null;
  }
}
