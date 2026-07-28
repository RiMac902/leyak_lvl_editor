import 'package:flame/components.dart';
import 'package:leyak_lvl_editor/editor/components/scene_component_registry.dart';
import 'package:leyak_lvl_editor/editor/components/transform_gizmo_component.dart';
import 'package:leyak_lvl_editor/editor/controllers/transform_target.dart';
import 'package:leyak_lvl_editor/editor/entities/entity_repository.dart';
import 'package:leyak_lvl_editor/editor/entities/grouping_service.dart';
import 'package:leyak_lvl_editor/editor/models/level_entity.dart';
import 'package:leyak_lvl_editor/editor/tools/selection_tool.dart';

/// Єдина відповідальність — показувати/ховати [TransformGizmoComponent]
/// відповідно до поточного виділення: рівно для однієї не згрупованої
/// сутності, або рівно однієї цілої групи (так само, як Inspector — для
/// решти випадків просто немає активної цілі трансформації).
class TransformGizmoController {
  TransformGizmoController(
    this._entities,
    this._groupingService,
    this._selectionTool,
    this._registry,
    this._host,
    this._tileSize,
    this._onTransformStarted,
    this._onTransformCommitted,
  );

  final EntityRepository _entities;
  final GroupingService _groupingService;
  final SelectionTool _selectionTool;
  final SceneComponentRegistry _registry;
  final Component _host;
  final double Function() _tileSize;

  /// Викликається на самому початку драгу гізмо (перед будь-якою зміною
  /// rotation/scale) — композиційний корінь підключає сюди
  /// [HistoryController.checkpoint].
  final void Function() _onTransformStarted;
  final void Function() _onTransformCommitted;

  TransformGizmoComponent? _gizmo;

  void onSelectionChanged() {
    _gizmo?.removeFromParent();
    _gizmo = null;

    final target = _resolveTarget(_selectionTool.selected);
    if (target == null) return;

    final gizmo = TransformGizmoComponent(
      target,
      onDragStarted: _onTransformStarted,
      // Запікаємо scale в реальні дані ПІСЛЯ кожного завершеного драгу
      // (не тільки scale-хендлів — rotation-драг теж проходить через цей
      // самий колбек, але bakeScale() безпечно ноуопить, якщо scale уже
      // (1,1)) — інакше scale лишався б суто візуальним множником, і
      // hit-test/снепінг далі рахували б за старим, немасштабованим
      // розміром.
      onCommitted: () {
        target.bakeScale();
        _onTransformCommitted();
      },
    );
    _gizmo = gizmo;
    _host.add(gizmo);
  }

  TransformTarget? _resolveTarget(List<LevelEntity> selected) {
    if (selected.length == 1 && selected.first.groupId == null) {
      final entity = selected.first;
      final component = _registry.componentOf(entity);
      if (component == null) return null;
      return EntityTransformTarget(entity, component, _tileSize());
    }

    final group = _groupingService.fullGroupSelectionOf(selected);
    if (group == null) return null;

    final component = _registry.groupComponentOf(group.id);
    if (component == null) return null;
    return GroupTransformTarget(group, component, _entities.membersOf(group.id), _tileSize());
  }
}
