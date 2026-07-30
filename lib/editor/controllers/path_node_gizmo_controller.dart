import 'package:flame/components.dart';
import 'package:leyak_lvl_editor/editor/components/path_node_gizmo_component.dart';
import 'package:leyak_lvl_editor/editor/components/scene_component_registry.dart';
import 'package:leyak_lvl_editor/editor/models/shape_type.dart';
import 'package:leyak_lvl_editor/editor/tools/selection_tool.dart';

/// Єдина відповідальність — показувати/ховати [PathNodeGizmoComponent]
/// відповідно до поточного виділення: рівно для однієї не згрупованої
/// path-сутності. Аналог [TransformGizmoController], але для path-точок
/// замість rotate/scale — обидва контролери підписані на те саме
/// [SelectionTool.onChanged], і рівно один з них щоразу знаходить свою
/// ціль (нормальний гізмо навмисно виключає path — див.
/// [TransformGizmoController._resolveTarget]).
class PathNodeGizmoController {
  PathNodeGizmoController(
    this._selectionTool,
    this._registry,
    this._host,
    this._tileSize,
    this._onEditStarted,
    this._onEditCommitted,
  );

  final SelectionTool _selectionTool;
  final SceneComponentRegistry _registry;
  final Component _host;
  final double Function() _tileSize;
  final void Function() _onEditStarted;
  final void Function() _onEditCommitted;

  PathNodeGizmoComponent? _gizmo;

  void onSelectionChanged() {
    _gizmo?.removeFromParent();
    _gizmo = null;

    final selected = _selectionTool.selected;
    if (selected.length != 1 || selected.first.groupId != null) return;

    final entity = selected.first;
    if (entity.shapeType != ShapeType.path) return;

    final component = _registry.componentOf(entity);
    if (component == null) return;

    final gizmo = PathNodeGizmoComponent(
      entity,
      component,
      tileSizeOf: _tileSize,
      onDragStarted: _onEditStarted,
      onCommitted: _onEditCommitted,
    );
    _gizmo = gizmo;
    _host.add(gizmo);
  }
}
