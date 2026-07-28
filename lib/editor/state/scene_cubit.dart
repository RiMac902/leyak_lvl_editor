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

  /// Змінює колір одного [EntityPart] складеної (compound) сутності — аналог
  /// зміни fill в одного `<rect>` всередині SVG-групи.
  void setPartColor(LevelEntity entity, int partIndex, Color color) {
    final parts = entity.parts;
    if (parts == null || partIndex < 0 || partIndex >= parts.length) return;

    _history.checkpoint();
    parts[partIndex].color = color;
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
