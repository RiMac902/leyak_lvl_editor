import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:leyak_lvl_editor/editor/entities/entity_repository.dart';
import 'package:leyak_lvl_editor/editor/geometry/grid_coordinate_converter.dart';
import 'package:leyak_lvl_editor/editor/geometry/grid_rect.dart';
import 'package:leyak_lvl_editor/editor/models/level_entity.dart';
import 'package:leyak_lvl_editor/editor/models/shape_type.dart';
import 'package:leyak_lvl_editor/editor/tools/editor_tool.dart';

/// Єдина відповідальність — інструмент "малювання": життєвий цикл
/// створення нової сутності перетягуванням по сітці. Нова сутність
/// завжди стартує з нейтральними властивостями — редагувати їх можна
/// пізніше через Inspector, коли об'єкт виділено.
class DrawTool implements EditorTool {
  DrawTool(this._repository, this._converter, this._getShapeType);

  final EntityRepository _repository;
  final GridCoordinateConverter _converter;

  /// Яку форму зараз обрано в [ShapeToolbar] — читається лениво лише в
  /// момент старту малювання, а не збережено заздалегідь.
  final ShapeType Function() _getShapeType;

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
      shapeType: _getShapeType(),
    )
      ..transform.position = cell
      ..layer = _repository.nextLayer;
  }

  @override
  void dragUpdate(Vector2 worldPos) {
    if (entity == null || _startCell == null) return;

    final currentCell = _converter.worldToGrid(worldPos);

    // Лінія — особливий випадок: їй потрібні дві РЕАЛЬНІ точки драгу (звідки
    // і куди), а не нормалізований GridRect.fromCorners (той завжди
    // повертає top-left/bottom-right bounding-box, тож напрямок лінії
    // "стрибав" би між двома діагоналями залежно від того, у який бік
    // тягнеш). Товщина — окремий параметр (shapeStyle.lineThickness), а не
    // похідна від bounding-box, інакше вона мимоволі мінялась би разом із
    // довжиною/кутом лінії.
    if (entity!.shapeType == ShapeType.line) {
      final minX = math.min(_startCell!.x, currentCell.x);
      final minY = math.min(_startCell!.y, currentCell.y);
      final maxX = math.max(_startCell!.x, currentCell.x);
      final maxY = math.max(_startCell!.y, currentCell.y);
      final position = Vector2(minX, minY);

      origin = position;
      entity!.transform.position = position;
      entity!.transform.size = Vector2(maxX - minX, maxY - minY);
      entity!.shapeStyle.lineStart = _startCell! - position;
      entity!.shapeStyle.lineEnd = currentCell - position;
      return;
    }

    final rect = GridRect.fromCorners(
      _startCell!,
      currentCell,
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
