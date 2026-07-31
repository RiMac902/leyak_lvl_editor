import 'package:flame/components.dart' show Vector2;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:leyak_lvl_editor/editor/entities/entity_repository.dart';
import 'package:leyak_lvl_editor/editor/entities/grouping_service.dart';
import 'package:leyak_lvl_editor/editor/entities/layer_folder_repository.dart';
import 'package:leyak_lvl_editor/editor/entities/layer_folder_service.dart';
import 'package:leyak_lvl_editor/editor/geometry/scale_baking.dart';
import 'package:leyak_lvl_editor/editor/history/history_controller.dart';
import 'package:leyak_lvl_editor/editor/models/layer_folder.dart';
import 'package:leyak_lvl_editor/editor/models/level_entity.dart';
import 'package:leyak_lvl_editor/editor/models/level_group.dart';
import 'package:leyak_lvl_editor/editor/state/scene_state.dart';
import 'package:leyak_lvl_editor/editor/tools/selection_tool.dart';

/// Єдина відповідальність — читана модель сцени для Flutter UI
/// (Layers/Inspector) і фасад для редагування властивостей виділеної
/// сутності/групи. Не підписується на джерела сама — [ObjectManager]
/// (композиційний корінь) викликає [refresh] поруч з іншими підписниками
/// тих самих подій (наприклад [SceneComponentRegistry]), бо колбек-слоти
/// [EntityRepository]/[SelectionTool] одноразові й не можуть мати двох
/// незалежних підписників.
class SceneCubit extends Cubit<SceneState> {
  SceneCubit(
    this._repository,
    this._selectionTool,
    this._groupingService,
    this._history,
    this._layerFolders,
    this._layerFolderService,
  ) : super(const SceneState());

  final EntityRepository _repository;
  final SelectionTool _selectionTool;
  final GroupingService _groupingService;
  final HistoryController _history;
  final LayerFolderRepository _layerFolders;
  final LayerFolderService _layerFolderService;

  /// Останній рядок, клікнутий у Layers panel (звичайним кліком або
  /// shift-кліком) — якір для [selectRangeInLayers], як в Explorer/Finder:
  /// послідовні shift-кліки розширюють/звужують діапазон від того самого
  /// початку, а не від щойно клікнутого рядка.
  LevelEntity? _rangeAnchor;

  void refresh() {
    emit(
      SceneState(
        entities: _repository.sortedByLayer,
        selected: List.of(_selectionTool.selected),
        folders: _layerFolders.all,
      ),
    );
  }

  /// Створює папку шарів (Layers panel) з [selected] — не плутати з
  /// Ctrl+G ([GroupingService.groupEntities]): жодного зв'язку
  /// трансформації, лише організація z-порядку. Повертає `null`, якщо
  /// вибрано < 2 сутностей або хтось із них уже в папці.
  LayerFolder? createLayerFolder(List<LevelEntity> selected, String name) {
    if (selected.length < 2 || selected.any((e) => e.layerFolderId != null)) return null;

    _history.checkpoint();
    final folder = _layerFolderService.createFolder(selected, name);
    refresh();
    return folder;
  }

  /// Розпускає папку шарів — члени лишаються на своїх місцях у стеку,
  /// стають звичайними верхньорівневими рядками в Layers panel.
  void deleteLayerFolder(String folderId) {
    _history.checkpoint();
    _layerFolderService.deleteFolder(folderId);
    refresh();
  }

  void renameLayerFolder(String folderId, String name) {
    _history.checkpoint();
    _layerFolderService.renameFolder(folderId, name);
    refresh();
  }

  /// Згорнути/розгорнути папку в Layers panel — суто UI-стан, не
  /// undo-варте (не викликає [HistoryController.checkpoint]).
  void toggleFolderExpanded(String folderId) {
    _layerFolderService.toggleExpanded(folderId);
    refresh();
  }

  /// Позначає/знімає папку як фон рівня — див.
  /// [LayerFolderService.setFolderBackground].
  void setFolderBackground(String folderId, bool value) {
    _history.checkpoint();
    _layerFolderService.setFolderBackground(folderId, value);
    refresh();
  }

  /// Виділяє [entity] (клік по рядку в Layers panel) — якщо вона в
  /// постійній групі, виділяє одразу всю групу, як і клік на канвасі.
  /// Заблоковані сутності ігнорує — так само, як і hit-test на канвасі.
  void selectEntity(LevelEntity entity) {
    if (entity.isLocked) return;

    _rangeAnchor = entity;
    final groupId = entity.groupId;
    _selectionTool.selected
      ..clear()
      ..addAll(groupId != null ? _repository.membersOf(groupId) : [entity]);
    _selectionTool.onChanged?.call();
  }

  /// Shift-клік у Layers panel: виділяє весь діапазон рядків між останнім
  /// клікнутим (якорем, [_rangeAnchor]) і [clicked] за ВИДИМИМ порядком
  /// рядків панелі ([visibleOrder] — той самий список, що й показаний
  /// користувачу, з урахуванням згорнутих/розгорнутих папок), як у
  /// Windows Explorer/Finder. Якщо якоря ще нема (перший клік у сесії) чи
  /// когось із двох не знайдено у [visibleOrder] — просто виділяє
  /// [clicked], як звичайний клік. Заблоковані сутності в діапазоні
  /// пропускаються.
  void selectRangeInLayers(List<LevelEntity> visibleOrder, LevelEntity clicked) {
    if (clicked.isLocked) return;

    final anchor = _rangeAnchor;
    final anchorIndex = anchor == null ? -1 : visibleOrder.indexOf(anchor);
    final clickedIndex = visibleOrder.indexOf(clicked);
    if (anchorIndex == -1 || clickedIndex == -1) {
      selectEntity(clicked);
      return;
    }

    final start = anchorIndex < clickedIndex ? anchorIndex : clickedIndex;
    final end = anchorIndex < clickedIndex ? clickedIndex : anchorIndex;
    _selectionTool.selected
      ..clear()
      ..addAll(visibleOrder.sublist(start, end + 1).where((e) => !e.isLocked));
    _selectionTool.onChanged?.call();
  }

  /// Перезаписує [LevelEntity.layer] усіх сутностей у [topToBottomOrder]
  /// так, щоб їхній z-порядок точно відповідав цьому списку (індекс 0 —
  /// найвищий шар). Викликається після drag-and-drop реордеру в Layers
  /// panel — простіше й надійніше за "зсув на одну позицію", бо
  /// перетягування може одразу міняти відносний порядок кількох сутностей.
  void reorderLayers(List<LevelEntity> topToBottomOrder) {
    _history.checkpoint();
    for (var i = 0; i < topToBottomOrder.length; i++) {
      topToBottomOrder[i].layer = topToBottomOrder.length - 1 - i;
    }
    refresh();
  }

  /// Якщо поточне виділення — рівно одна ціла постійна група, повертає її
  /// (для Inspector, щоб показати редактор групи замість редактора сутності).
  LevelGroup? fullGroupSelectionOf(List<LevelEntity> selected) =>
      _groupingService.fullGroupSelectionOf(selected);

  void setEntityColor(LevelEntity entity, Color color) {
    _history.checkpoint();
    entity.visual.color = color;
    refresh();
  }

  void setEntityProperty(LevelEntity entity, String key, dynamic value) {
    _history.checkpoint();
    entity.customProperties[key] = value;
    refresh();
  }

  void setEntityRotation(LevelEntity entity, double radians) {
    _history.checkpoint();
    entity.transform.rotation = radians;
    refresh();
  }

  /// Одразу "запікає" [scale] в реальний [TransformData.size] (див.
  /// [bakeEntityScale]) — з Inspector-поля це фактично "змасштабувати
  /// відносно поточного розміру одноразово", а не тримати окремий
  /// постійний множник, який hit-test/снепінг все одно ігнорують.
  void setEntityScale(LevelEntity entity, Vector2 scale) {
    _history.checkpoint();
    entity.transform.scale = scale;
    bakeEntityScale(entity);
    refresh();
  }

  void setGroupRotation(LevelGroup group, double radians) {
    _history.checkpoint();
    group.rotation = radians;
    refresh();
  }

  /// Те саме, що [setEntityScale], але для групи — розганяє [scale] по
  /// відносних position/size усіх членів (див. [bakeGroupScale]).
  void setGroupScale(LevelGroup group, Vector2 scale) {
    _history.checkpoint();
    group.scale = scale;
    bakeGroupScale(group, _repository.membersOf(group.id));
    refresh();
  }

  /// Змінює колір одного [EntityPart] складеної (compound) сутності — аналог
  /// зміни fill в одного `<rect>` всередині SVG-групи.
  void setPartColor(LevelEntity entity, int partIndex, Color color) {
    final parts = entity.parts;
    if (parts == null || partIndex < 0 || partIndex >= parts.length) return;

    _history.checkpoint();
    parts[partIndex].color = color;
    refresh();
  }

  /// Призначає (чи знімає, якщо [shaderId] == null) кастомний шейдер
  /// одному [EntityPart].
  void setPartShader(LevelEntity entity, int partIndex, String? shaderId) {
    final parts = entity.parts;
    if (parts == null || partIndex < 0 || partIndex >= parts.length) return;

    _history.checkpoint();
    parts[partIndex].shaderId = shaderId;
    refresh();
  }

  /// Те саме, що [setPartShader], але для звичайної (не складеної)
  /// сутності — на її єдиному "шматку", [VisualData].
  void setEntityShader(LevelEntity entity, String? shaderId) {
    _history.checkpoint();
    entity.visual.shaderId = shaderId;
    refresh();
  }

  /// Змінює значення одного налаштовуваного параметра поточного шейдера
  /// сутності (напр. колір/товщина "контуру" в `ring_glow`) — див.
  /// [ShaderCatalog.paramsFor].
  void setEntityShaderParam(LevelEntity entity, String key, Object value) {
    _history.checkpoint();
    entity.visual.shaderParams[key] = value;
    refresh();
  }

  /// Те саме, що [setEntityShaderParam], але для одного [EntityPart].
  void setPartShaderParam(LevelEntity entity, int partIndex, String key, Object value) {
    final parts = entity.parts;
    if (parts == null || partIndex < 0 || partIndex >= parts.length) return;

    _history.checkpoint();
    parts[partIndex].shaderParams[key] = value;
    refresh();
  }

  /// Призначає (чи знімає, якщо [path] == null) шлях до відео-файлу, кадри
  /// якого подаються як текстура шейдерам, що цього потребують — див.
  /// [ShaderCatalog.needsTexture]. [EntityComponent] сам підхопить/звільнить
  /// відповідний [VideoTextureManager] на наступному кадрі.
  void setPartVideo(LevelEntity entity, int partIndex, String? path) {
    final parts = entity.parts;
    if (parts == null || partIndex < 0 || partIndex >= parts.length) return;

    _history.checkpoint();
    parts[partIndex].videoPath = path;
    refresh();
  }

  /// Те саме, що [setPartVideo], але для звичайної (не складеної) сутності.
  void setEntityVideo(LevelEntity entity, String? path) {
    _history.checkpoint();
    entity.visual.videoPath = path;
    refresh();
  }

  /// Радіус заокруглення одного кута/кінця (за [index]) — сенс індексу
  /// залежить від `shapeType`, див. [ShapeStyle.cornerRadii].
  void setEntityCornerRadius(LevelEntity entity, int index, double radius) {
    _history.checkpoint();
    entity.shapeStyle.cornerRadii[index] = radius;
    refresh();
  }

  void setPartCornerRadius(LevelEntity entity, int partIndex, int index, double radius) {
    final parts = entity.parts;
    if (parts == null || partIndex < 0 || partIndex >= parts.length) return;

    _history.checkpoint();
    parts[partIndex].shapeStyle.cornerRadii[index] = radius;
    refresh();
  }

  /// Товщина лінії — незалежний параметр від bounding-box (див.
  /// [ShapeStyle.lineThickness]), застосовується лише коли
  /// `shapeType == ShapeType.line`.
  void setEntityLineThickness(LevelEntity entity, double thickness) {
    _history.checkpoint();
    entity.shapeStyle.lineThickness = thickness;
    refresh();
  }

  void setPartLineThickness(LevelEntity entity, int partIndex, double thickness) {
    final parts = entity.parts;
    if (parts == null || partIndex < 0 || partIndex >= parts.length) return;

    _history.checkpoint();
    parts[partIndex].shapeStyle.lineThickness = thickness;
    refresh();
  }

  void deleteEntity(LevelEntity entity) {
    if (entity.isLocked) return;

    _history.checkpoint();
    _selectionTool.selected.remove(entity);
    _repository.remove(entity);
    // repository.remove вже викликає onChanged (=refresh), але не знає про
    // зміну виділення — без цього виклику підсвітка/гізмо лишились би
    // застарілими, якби сутність була виділена в момент видалення.
    _selectionTool.onChanged?.call();
  }

  /// Перемикає lock: заблокована сутність не потрапляє в hit-test
  /// ([EntityRepository.findAt]/[findWithin]), тож її не можна виділити,
  /// перемістити, видалити чи згрупувати з канвасу. Якщо вона була
  /// виділена в момент блокування — знімає виділення, інакше гізмо/
  /// підсвітка лишились би вказувати на щось більше не інтерактивне.
  void toggleLock(LevelEntity entity) {
    entity.isLocked = !entity.isLocked;
    if (entity.isLocked) {
      _selectionTool.selected.remove(entity);
    }
    _selectionTool.onChanged?.call();
  }
}
