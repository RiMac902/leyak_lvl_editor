import 'package:leyak_lvl_editor/editor/models/level_group.dart';

/// Єдина відповідальність — зберігання [LevelGroup]. Дзеркалить форму
/// [EntityRepository].
class GroupRepository {
  final List<LevelGroup> _groups = [];

  void Function(LevelGroup group)? onGroupAdded;
  void Function(LevelGroup group)? onGroupRemoved;
  void Function()? onChanged;

  List<LevelGroup> get all => List.unmodifiable(_groups);

  LevelGroup? find(String id) {
    for (final group in _groups) {
      if (group.id == id) return group;
    }
    return null;
  }

  void add(LevelGroup group) {
    _groups.add(group);
    onGroupAdded?.call(group);
    onChanged?.call();
  }

  void remove(String id) {
    final group = find(id);
    if (group == null) return;
    _groups.remove(group);
    onGroupRemoved?.call(group);
    onChanged?.call();
  }

  /// Повністю замінює список (для відновлення знімка при undo/redo). Має
  /// відпрацювати ПІСЛЯ [EntityRepository.replaceAll] — [onGroupAdded]
  /// реперентить [EntityComponent] членів під новий [GroupComponent], а це
  /// можливо лише тоді, коли їхні компоненти вже існують.
  void replaceAll(List<LevelGroup> newGroups) {
    for (final group in List.of(_groups)) {
      _groups.remove(group);
      onGroupRemoved?.call(group);
    }
    for (final group in newGroups) {
      _groups.add(group);
      onGroupAdded?.call(group);
    }
    onChanged?.call();
  }
}
