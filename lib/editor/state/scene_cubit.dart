import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:leyak_lvl_editor/editor/entities/entity_repository.dart';
import 'package:leyak_lvl_editor/editor/models/level_entity.dart';
import 'package:leyak_lvl_editor/editor/state/scene_state.dart';
import 'package:leyak_lvl_editor/editor/tools/selection_tool.dart';

/// Єдина відповідальність — читана модель сцени для Flutter UI
/// (Layers/Inspector) і фасад для редагування властивостей виділеної
/// сутності. Тримає Flame-сторону ([EntityRepository]/[SelectionTool])
/// синхронізованою зі станом, який бачить Flutter.
class SceneCubit extends Cubit<SceneState> {
  SceneCubit(this._repository, this._selectionTool) : super(const SceneState()) {
    _repository.onChanged = refresh;
    _selectionTool.onChanged = refresh;
  }

  final EntityRepository _repository;
  final SelectionTool _selectionTool;

  void refresh() {
    emit(SceneState(entities: _repository.all, selected: List.of(_selectionTool.selected)));
  }

  void setEntityColor(LevelEntity entity, Color color) {
    entity.visual.color = color;
    refresh();
  }

  void setEntityProperty(LevelEntity entity, String key, dynamic value) {
    entity.customProperties[key] = value;
    refresh();
  }
}
