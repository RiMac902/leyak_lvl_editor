import 'dart:ui';

import 'package:flame/components.dart';
import 'package:leyak_lvl_editor/editor/animation/entity_motion_animator.dart';
import 'package:leyak_lvl_editor/editor/components/editor_world.dart';
import 'package:leyak_lvl_editor/editor/entities/entity_repository.dart';
import 'package:leyak_lvl_editor/editor/geometry/grid_coordinate_converter.dart';
import 'package:leyak_lvl_editor/editor/main_editor.dart';
import 'package:leyak_lvl_editor/editor/models/editor_mode.dart';
import 'package:leyak_lvl_editor/editor/rendering/object_scene_renderer.dart';
import 'package:leyak_lvl_editor/editor/state/scene_cubit.dart';
import 'package:leyak_lvl_editor/editor/tools/draw_tool.dart';
import 'package:leyak_lvl_editor/editor/tools/editor_tool.dart';
import 'package:leyak_lvl_editor/editor/tools/selection_tool.dart';

/// Композиційний корінь для роботи з об'єктами сцени: маршрутизує
/// drag-події до інструменту, що відповідає поточному режиму редактора,
/// і делегує рендер [ObjectSceneRenderer].
///
/// Усі поля ініціалізуються ліниво (`late final ... = ...`), тому Flutter
/// UI (Layers/Inspector) може безпечно читати [sceneCubit] одразу після
/// створення гри, не чекаючи на Flame-подію `onLoad`.
class ObjectManager extends Component
    with HasWorldReference<EditorWorld>, HasGameReference<MainEditor> {
  late final EntityRepository _repository = EntityRepository();

  late final GridCoordinateConverter _converter = GridCoordinateConverter(
    () => game.tileSize,
    () => world.snapController.snapEnabled,
  );

  late final DrawTool _drawTool = DrawTool(_repository, _converter);

  late final SelectionTool _selectionTool = SelectionTool(_repository, _converter);

  /// Читана Flutter-модель сцени + фасад редагування — єдина точка,
  /// через яку UI спостерігає й змінює дані сутностей.
  late final SceneCubit sceneCubit = SceneCubit(_repository, _selectionTool);

  final ObjectSceneRenderer _renderer = const ObjectSceneRenderer();
  final EntityMotionAnimator _motionAnimator = EntityMotionAnimator();

  EditorTool get _activeTool =>
      world.currentMode == EditorMode.draw ? _drawTool : _selectionTool;

  void handleDragStart(Vector2 worldPos) => _activeTool.dragStart(worldPos);

  void handleDragUpdate(Vector2 worldPos) => _activeTool.dragUpdate(worldPos);

  void handleDragEnd() => _activeTool.dragEnd();

  @override
  void onRemove() {
    sceneCubit.close();
    super.onRemove();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _motionAnimator.update(dt, _repository.all);
  }

  @override
  void render(Canvas canvas) {
    _renderer.render(
      canvas,
      _converter,
      _repository,
      _drawTool,
      _selectionTool,
      _motionAnimator,
    );
  }
}
