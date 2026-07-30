import 'dart:ui';

import 'package:flame/components.dart';
import 'package:leyak_lvl_editor/editor/components/editor_world.dart';
import 'package:leyak_lvl_editor/editor/components/scene_component_registry.dart';
import 'package:leyak_lvl_editor/editor/controllers/path_node_gizmo_controller.dart';
import 'package:leyak_lvl_editor/editor/controllers/transform_gizmo_controller.dart';
import 'package:leyak_lvl_editor/editor/entities/entity_repository.dart';
import 'package:leyak_lvl_editor/editor/entities/group_repository.dart';
import 'package:leyak_lvl_editor/editor/entities/grouping_service.dart';
import 'package:leyak_lvl_editor/editor/entities/layer_folder_repository.dart';
import 'package:leyak_lvl_editor/editor/entities/layer_folder_service.dart';
import 'package:leyak_lvl_editor/editor/entities/merge_service.dart';
import 'package:leyak_lvl_editor/editor/geometry/grid_coordinate_converter.dart';
import 'package:leyak_lvl_editor/editor/history/history_controller.dart';
import 'package:leyak_lvl_editor/editor/main_editor.dart';
import 'package:leyak_lvl_editor/editor/models/editor_mode.dart';
import 'package:leyak_lvl_editor/editor/models/entity_part.dart';
import 'package:leyak_lvl_editor/editor/models/level_entity.dart';
import 'package:leyak_lvl_editor/editor/models/shape_type.dart';
import 'package:leyak_lvl_editor/editor/models/transform_data.dart';
import 'package:leyak_lvl_editor/editor/models/visual_data.dart';
import 'package:leyak_lvl_editor/editor/rendering/tool_overlay_renderer.dart';
import 'package:leyak_lvl_editor/editor/state/scene_cubit.dart';
import 'package:leyak_lvl_editor/editor/tools/draw_tool.dart';
import 'package:leyak_lvl_editor/editor/tools/editor_tool.dart';
import 'package:leyak_lvl_editor/editor/tools/path_tool.dart';
import 'package:leyak_lvl_editor/editor/tools/selection_tool.dart';

/// Композиційний корінь для роботи з об'єктами сцени: маршрутизує
/// drag-події до інструменту, що відповідає поточному режиму редактора,
/// тримає дерево сутностей ([SceneComponentRegistry]) у синхроні з даними,
/// і складає докупи підписників подій [EntityRepository]/[GroupRepository]/
/// [SelectionTool] — їхні колбек-слоти одноразові, тож саме композиційний
/// корінь відповідає за те, щоб кожна подія доходила до всіх, кому вона
/// потрібна ([SceneCubit] для Flutter UI, [SceneComponentRegistry] для
/// дерева Flame).
///
/// Усі поля ініціалізуються ліниво (`late final ... = ...`), тому Flutter
/// UI (Layers/Inspector) може безпечно читати [sceneCubit] одразу після
/// створення гри, не чекаючи на Flame-подію `onLoad`.
class ObjectManager extends Component
    with HasWorldReference<EditorWorld>, HasGameReference<MainEditor> {
  late final GroupRepository _groups = GroupRepository();

  late final EntityRepository _repository = EntityRepository(
    resolveGroupOffset: (groupId) => _groups.find(groupId)?.position ?? Vector2.zero(),
  );

  late final GroupingService _groupingService = GroupingService(_repository, _groups);

  late final LayerFolderRepository _layerFolders = LayerFolderRepository();

  late final LayerFolderService _layerFolderService = LayerFolderService(
    _repository,
    _layerFolders,
  );

  final MergeService _mergeService = const MergeService();

  late final HistoryController _history = HistoryController(_repository, _groups, _layerFolders);

  late final GridCoordinateConverter _converter = GridCoordinateConverter(
    () => game.tileSize,
    () => world.snapController.snapEnabled,
  );

  late final DrawTool _drawTool = DrawTool(
    _repository,
    _converter,
    () => world.shapeController.current,
  );

  late final PathTool _pathTool = PathTool(_repository, _converter);

  late final SelectionTool _selectionTool = SelectionTool(
    _repository,
    _converter,
    _groupingService,
  );

  /// Читана Flutter-модель сцени + фасад редагування — єдина точка,
  /// через яку UI спостерігає й змінює дані сутностей.
  late final SceneCubit sceneCubit = SceneCubit(
    _repository,
    _selectionTool,
    _groupingService,
    _history,
    _layerFolders,
    _layerFolderService,
  );

  late final SceneComponentRegistry _registry = SceneComponentRegistry(
    _repository,
    _selectionTool,
  );

  late final TransformGizmoController _gizmoController = TransformGizmoController(
    _repository,
    _groupingService,
    _selectionTool,
    _registry,
    this,
    () => game.tileSize,
    _history.checkpoint,
    () => sceneCubit.refresh(),
  );

  late final PathNodeGizmoController _pathNodeGizmoController = PathNodeGizmoController(
    _selectionTool,
    _registry,
    this,
    () => game.tileSize,
    _history.checkpoint,
    () => sceneCubit.refresh(),
  );

  final ToolOverlayRenderer _overlayRenderer = const ToolOverlayRenderer();

  /// В режимі малювання (F) маршрутизує на [_pathTool], коли в
  /// [ShapeToolbar] обрано [ShapeType.path] — той самий перемикач шейпів,
  /// що й для решти форм, лише [PathTool] має свій, відмінний від
  /// [DrawTool] життєвий цикл (N кліків замість одного драгу).
  EditorTool get _activeTool {
    if (world.currentMode != EditorMode.draw) return _selectionTool;
    return world.shapeController.current == ShapeType.path ? _pathTool : _drawTool;
  }

  void handleDragStart(Vector2 worldPos) => _activeTool.dragStart(worldPos);

  void handleDragUpdate(Vector2 worldPos) => _activeTool.dragUpdate(worldPos);

  void handleDragEnd() => _activeTool.dragEnd();

  bool get hasSelection => _selectionTool.selected.isNotEmpty;

  /// Групує поточне виділення (Ctrl+G). Повертає false, якщо групувати
  /// нема що (менше 2 об'єктів або хтось із них вже в групі) — виклик
  /// показує HUD-нотифікацію лише при успіху.
  bool groupSelection() {
    final selected = List.of(_selectionTool.selected);
    if (selected.length < 2 || selected.any((e) => e.groupId != null)) return false;

    _history.checkpoint();
    final group = _groupingService.groupEntities(selected);
    if (group == null) return false;

    _selectionTool.selected
      ..clear()
      ..addAll(_repository.membersOf(group.id));
    _gizmoController.onSelectionChanged();
    sceneCubit.refresh();
    return true;
  }

  /// Розгруповує поточне виділення, якщо воно — рівно одна ціла група
  /// (Ctrl+Shift+G). Повертає false, якщо нема що розгруповувати.
  bool ungroupSelection() {
    final group = _groupingService.fullGroupSelectionOf(_selectionTool.selected);
    if (group == null) return false;

    _history.checkpoint();
    _groupingService.ungroup(group.id);
    _gizmoController.onSelectionChanged();
    sceneCubit.refresh();
    return true;
  }

  /// Видаляє все поточне виділення (Delete/Backspace). Якщо після цього
  /// в якоїсь групи не лишилось жодного члена — прибирає й саму групу
  /// (див. [onLoad]), щоб не накопичувати осиротілі записи.
  bool deleteSelection() {
    final toDelete = List.of(_selectionTool.selected);
    if (toDelete.isEmpty) return false;

    _history.checkpoint();
    for (final entity in toDelete) {
      _selectionTool.selected.remove(entity);
      _repository.remove(entity);
    }
    _gizmoController.onSelectionChanged();
    sceneCubit.refresh();
    return true;
  }

  /// Дублює поточне виділення (Cmd/Ctrl+D) зі зсувом на 1 клітинку, щоб
  /// копії було видно, а не накладено точно на оригінал. Якщо виділення —
  /// рівно ціла група, копії теж групуються між собою.
  bool duplicateSelection() {
    final selected = List.of(_selectionTool.selected);
    if (selected.isEmpty) return false;

    _history.checkpoint();

    final wasFullGroup = _groupingService.fullGroupSelectionOf(selected) != null;
    const offset = 1.0;
    final clones = <LevelEntity>[];
    final baseLayer = _repository.nextLayer;

    for (var i = 0; i < selected.length; i++) {
      final entity = selected[i];
      final clone = LevelEntity(
        id: '${DateTime.now().microsecondsSinceEpoch}_$i',
        transform: TransformData(
          position: entity.transform.position + Vector2.all(offset),
          rotation: entity.transform.rotation,
          scale: entity.transform.scale.clone(),
          size: entity.transform.size.clone(),
        ),
        visual: VisualData(
          color: entity.visual.color,
          spritePath: entity.visual.spritePath,
          shaderId: entity.visual.shaderId,
          videoPath: entity.visual.videoPath,
          shaderParams: Map<String, Object>.of(entity.visual.shaderParams),
        ),
        customProperties: Map<String, dynamic>.of(entity.customProperties),
        parts: entity.parts
            ?.map(
              (part) => EntityPart(
                relativePosition: part.relativePosition.clone(),
                size: part.size.clone(),
                color: part.color,
                shapeType: part.shapeType,
                shapeStyle: part.shapeStyle.clone(),
                shaderId: part.shaderId,
                videoPath: part.videoPath,
                shaderParams: Map<String, Object>.of(part.shaderParams),
              ),
            )
            .toList(),
        layer: baseLayer + i,
        shapeType: entity.shapeType,
        shapeStyle: entity.shapeStyle.clone(),
        isVisible: entity.isVisible,
      );
      _repository.add(clone);
      clones.add(clone);
    }

    if (wasFullGroup && clones.length >= 2) {
      _groupingService.groupEntities(clones);
    }

    _selectionTool.selected
      ..clear()
      ..addAll(clones);
    _gizmoController.onSelectionChanged();
    sceneCubit.refresh();
    return true;
  }

  /// Об'єднує поточне виділення (Cmd/Ctrl+M) в одну складену сутність —
  /// див. [MergeService]. Повертає false, якщо об'єднати не можна.
  bool mergeSelection() {
    final selected = List.of(_selectionTool.selected);
    final merged = _mergeService.merge(selected);
    if (merged == null) return false;

    _history.checkpoint();
    for (final entity in selected) {
      _selectionTool.selected.remove(entity);
      _repository.remove(entity);
    }
    _repository.add(merged);

    _selectionTool.selected
      ..clear()
      ..add(merged);
    _gizmoController.onSelectionChanged();
    sceneCubit.refresh();
    return true;
  }

  bool undo() {
    final didUndo = _history.undo();
    if (didUndo) {
      _selectionTool.selected.clear();
      _gizmoController.onSelectionChanged();
      sceneCubit.refresh();
    }
    return didUndo;
  }

  bool redo() {
    final didRedo = _history.redo();
    if (didRedo) {
      _selectionTool.selected.clear();
      _gizmoController.onSelectionChanged();
      sceneCubit.refresh();
    }
    return didRedo;
  }

  /// Чи зараз будується контур (для [PathShortcut] — Enter/Escape мають
  /// щось робити лише поки контур активний, інакше "проковтували" б ці
  /// клавіші завжди).
  bool get isBuildingPath => _pathTool.isBuilding;

  /// Enter — завершує контур, що будує [_pathTool] (мінімум 2 точки).
  /// Повертає, чи справді щось закомітилось (для HUD-нотифікації).
  bool finishPath() => _pathTool.finish();

  /// Escape — скасовує побудову контуру без коміту.
  void cancelPath() => _pathTool.cancel();

  @override
  Future<void> onLoad() async {
    await add(_registry);

    _drawTool.beforeCommit = _history.checkpoint;
    _pathTool.beforeCommit = _history.checkpoint;
    _selectionTool.beforeMove = _history.checkpoint;

    _repository.onEntityAdded = _registry.spawn;
    _repository.onEntityRemoved = (entity) {
      _registry.despawn(entity);
      final groupId = entity.groupId;
      if (groupId != null && _repository.membersOf(groupId).isEmpty) {
        _groups.remove(groupId);
      }
    };
    _repository.onChanged = sceneCubit.refresh;
    _groups.onGroupAdded = _registry.spawnGroup;
    _groups.onGroupRemoved = _registry.despawnGroup;
    _selectionTool.onChanged = () {
      _registry.updateSelectionHighlight();
      _gizmoController.onSelectionChanged();
      _pathNodeGizmoController.onSelectionChanged();
      sceneCubit.refresh();
    };
  }

  @override
  void onRemove() {
    sceneCubit.close();
    super.onRemove();
  }

  @override
  void render(Canvas canvas) {
    _overlayRenderer.render(canvas, _converter, _drawTool, _pathTool, _selectionTool);
  }
}
