import 'dart:ui';

import 'package:flame/components.dart';
import 'package:leyak_lvl_editor/editor/components/editor_world.dart';
import 'package:leyak_lvl_editor/editor/entities/entity_repository.dart';
import 'package:leyak_lvl_editor/editor/geometry/grid_coordinate_converter.dart';
import 'package:leyak_lvl_editor/editor/main_editor.dart';
import 'package:leyak_lvl_editor/editor/models/editor_mode.dart';
import 'package:leyak_lvl_editor/editor/models/entity_type.dart';
import 'package:leyak_lvl_editor/editor/models/level_entity.dart';
import 'package:leyak_lvl_editor/editor/rendering/object_scene_renderer.dart';
import 'package:leyak_lvl_editor/editor/tools/draw_tool.dart';
import 'package:leyak_lvl_editor/editor/tools/editor_tool.dart';
import 'package:leyak_lvl_editor/editor/tools/selection_tool.dart';

/// Композиційний корінь для роботи з об'єктами сцени: маршрутизує
/// drag-події до інструменту, що відповідає поточному режиму редактора,
/// і делегує рендер [ObjectSceneRenderer].
class ObjectManager extends Component
    with HasWorldReference<EditorWorld>, HasGameReference<MainEditor> {
  late final EntityRepository _repository;
  late final DrawTool _drawTool;
  late final SelectionTool _selectionTool;

  final ObjectSceneRenderer _renderer = const ObjectSceneRenderer();

  List<LevelEntity> get entities => _repository.all;
  List<LevelEntity> get selectedEntities => _selectionTool.selected;

  EntityType get currentTool => _drawTool.currentType;
  set currentTool(EntityType type) => _drawTool.currentType = type;

  @override
  Future<void> onLoad() async {
    final converter = GridCoordinateConverter(game.tileSize);
    _repository = EntityRepository();
    _drawTool = DrawTool(_repository, converter);
    _selectionTool = SelectionTool(_repository, converter);
  }

  EditorTool get _activeTool =>
      world.currentMode == EditorMode.draw ? _drawTool : _selectionTool;

  void handleDragStart(Vector2 worldPos) => _activeTool.dragStart(worldPos);

  void handleDragUpdate(Vector2 worldPos) => _activeTool.dragUpdate(worldPos);

  void handleDragEnd() => _activeTool.dragEnd();

  @override
  void render(Canvas canvas) {
    _renderer.render(canvas, game.tileSize, _repository, _drawTool, _selectionTool);
  }
}
