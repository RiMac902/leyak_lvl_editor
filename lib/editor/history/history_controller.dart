import 'package:leyak_lvl_editor/editor/entities/entity_repository.dart';
import 'package:leyak_lvl_editor/editor/entities/group_repository.dart';
import 'package:leyak_lvl_editor/editor/history/scene_snapshot.dart';

/// Єдина відповідальність — undo/redo для сцени, на рівні повних знімків
/// (не окремих полів): простіше й надійніше за command-патерн, тим більше,
/// що дані й так поки не серіалізуються десь ще. Ціна — undo не "плавний",
/// а миттєвий стрибок до попереднього стану, що для undo є очікуваною,
/// а не гіршою поведінкою.
class HistoryController {
  HistoryController(this._entities, this._groups, {this.maxDepth = 100});

  final EntityRepository _entities;
  final GroupRepository _groups;
  final int maxDepth;

  final List<SceneSnapshot> _undoStack = [];
  final List<SceneSnapshot> _redoStack = [];

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  /// Викликати ПЕРЕД кожною завершеною користувацькою дією, що міняє дані
  /// (не для кожного проміжного кадру драгу) — фіксує стан ДО цієї дії.
  /// Будь-яка дія після checkpoint скидає redo-історію, як і очікується.
  void checkpoint() {
    _undoStack.add(SceneSnapshot.capture(_entities, _groups));
    if (_undoStack.length > maxDepth) _undoStack.removeAt(0);
    _redoStack.clear();
  }

  bool undo() {
    if (_undoStack.isEmpty) return false;
    _redoStack.add(SceneSnapshot.capture(_entities, _groups));
    _restore(_undoStack.removeLast());
    return true;
  }

  bool redo() {
    if (_redoStack.isEmpty) return false;
    _undoStack.add(SceneSnapshot.capture(_entities, _groups));
    _restore(_redoStack.removeLast());
    return true;
  }

  /// Порядок важливий: групи мають відновлюватись ПІСЛЯ сутностей, бо
  /// реперентинг [EntityComponent] під [GroupComponent] (реакція на
  /// [GroupRepository.onGroupAdded]) потребує, щоб компоненти сутностей вже
  /// існували.
  void _restore(SceneSnapshot snapshot) {
    _entities.replaceAll(snapshot.entities.map((e) => e.toEntity()).toList());
    _groups.replaceAll(snapshot.groups.map((g) => g.toGroup()).toList());
  }
}
