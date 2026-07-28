import 'package:flame/components.dart' show Vector2;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:leyak_lvl_editor/editor/entities/entity_repository.dart';
import 'package:leyak_lvl_editor/editor/entities/grouping_service.dart';
import 'package:leyak_lvl_editor/editor/history/history_controller.dart';
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
  SceneCubit(this._repository, this._selectionTool, this._groupingService, this._history)
    : super(const SceneState());

  final EntityRepository _repository;
  final SelectionTool _selectionTool;
  final GroupingService _groupingService;
  final HistoryController _history;

  void refresh() {
    emit(SceneState(entities: _repository.all, selected: List.of(_selectionTool.selected)));
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

  void setEntityScale(LevelEntity entity, Vector2 scale) {
    _history.checkpoint();
    entity.transform.scale = scale;
    refresh();
  }

  void setGroupRotation(LevelGroup group, double radians) {
    _history.checkpoint();
    group.rotation = radians;
    refresh();
  }

  void setGroupScale(LevelGroup group, Vector2 scale) {
    _history.checkpoint();
    group.scale = scale;
    refresh();
  }

  void deleteEntity(LevelEntity entity) {
    _history.checkpoint();
    _selectionTool.selected.remove(entity);
    _repository.remove(entity);
  }
}
