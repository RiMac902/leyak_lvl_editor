import 'package:flame/components.dart';
import 'package:leyak_lvl_editor/editor/entities/entity_repository.dart';
import 'package:leyak_lvl_editor/editor/geometry/grid_coordinate_converter.dart';
import 'package:leyak_lvl_editor/editor/geometry/path_bounds.dart';
import 'package:leyak_lvl_editor/editor/models/level_entity.dart';
import 'package:leyak_lvl_editor/editor/models/shape_type.dart';
import 'package:leyak_lvl_editor/editor/tools/editor_tool.dart';

/// Єдина відповідальність — інструмент "Pen tool": на відміну від
/// [DrawTool] (одне безперервне перетягування = одна форма), контур
/// будується з N ОКРЕМИХ click/drag-циклів — кожен `dragStart` додає нову
/// точку, а не комітить готову форму. Сутність існує в пам'яті (як
/// прев'ю — ще НЕ в [EntityRepository]) з першого кліку до явного
/// завершення: [finish] (Enter, відкритий контур) чи клік біля першої
/// точки (замикає й комітить, див. [dragStart]); [cancel] (Escape) —
/// скасовує без коміту.
class PathTool implements EditorTool {
  PathTool(this._repository, this._converter);

  final EntityRepository _repository;
  final GridCoordinateConverter _converter;

  /// Мінімальна відстань (у клітинках сітки) до першої точки, у межах якої
  /// клік трактується як "замкнути контур", а не "додати ще одну точку".
  static const double _closeThreshold = 0.4;

  /// Викликається безпосередньо перед комітом у репозиторій —
  /// композиційний корінь підключає сюди [HistoryController.checkpoint].
  void Function()? beforeCommit;

  /// Сутність, що будується — `null`, якщо зараз немає активного контуру.
  /// Читається [ToolOverlayRenderer] для прев'ю (та сама сутність, тим
  /// самим [shapePathFor], що й готова форма — прев'ю завжди чесно
  /// показує актуальний контур).
  LevelEntity? entity;

  Vector2? _pointDragStart;

  bool get isBuilding => entity != null;

  @override
  void dragStart(Vector2 worldPos) {
    final cell = _converter.worldToGrid(worldPos);
    final current = entity;

    if (current == null) {
      final created = LevelEntity.create(
        customProperties: {'isSolid': false, 'isDeadly': false},
        shapeType: ShapeType.path,
      )..transform.position = cell.clone();
      created.shapeStyle
        ..pathPoints.add(Vector2.zero())
        ..pathHandlesIn.add(Vector2.zero())
        ..pathHandlesOut.add(Vector2.zero());
      entity = created;
      _pointDragStart = cell;
      return;
    }

    final points = current.shapeStyle.pathPoints;
    if (points.length >= 3) {
      final firstAbsolute = current.transform.position + points.first;
      if ((cell - firstAbsolute).length <= _closeThreshold) {
        current.shapeStyle.pathClosed = true;
        _commit();
        return;
      }
    }

    final relative = cell - current.transform.position;
    current.shapeStyle
      ..pathPoints.add(relative)
      ..pathHandlesIn.add(Vector2.zero())
      ..pathHandlesOut.add(Vector2.zero());
    _pointDragStart = cell;
  }

  @override
  void dragUpdate(Vector2 worldPos) {
    final current = entity;
    final startCell = _pointDragStart;
    if (current == null || startCell == null) return;

    // Перетягування під час розміщення точки задає її bezier-хендли —
    // симетрично (in = -out), як в усіх Pen tool: плавна крива через цю
    // точку. Клік без драгу лишає обидва хендли нульовими (гострий кут).
    final cell = _converter.worldToGrid(worldPos);
    final delta = cell - startCell;
    final index = current.shapeStyle.pathPoints.length - 1;
    current.shapeStyle.pathHandlesOut[index] = delta.clone();
    current.shapeStyle.pathHandlesIn[index] = -delta;
  }

  @override
  void dragEnd() {
    // НЕ комітить і не чистить entity — контур росте далі наступним
    // dragStart, чи завершується через [finish]/[cancel]/замикання.
    _pointDragStart = null;
  }

  /// Enter — завершує ВІДКРИТИЙ контур. Замало точок (< 2) — скасовує
  /// замість коміту порожньої/безглуздої форми. Повертає, чи справді
  /// щось закомітилось (для HUD-нотифікації).
  bool finish() {
    final current = entity;
    if (current == null) return false;
    if (current.shapeStyle.pathPoints.length < 2) {
      cancel();
      return false;
    }
    _commit();
    return true;
  }

  /// Escape — скасовує побудову без коміту в репозиторій.
  void cancel() {
    entity = null;
    _pointDragStart = null;
  }

  void _commit() {
    final current = entity;
    if (current == null) return;

    recomputePathBounds(current);
    beforeCommit?.call();
    _repository.add(current);
    entity = null;
    _pointDragStart = null;
  }
}
