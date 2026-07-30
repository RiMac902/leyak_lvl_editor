import 'package:leyak_lvl_editor/editor/models/layer_folder.dart';

/// Єдина відповідальність — зберігання [LayerFolder]. Дзеркалить форму
/// [GroupRepository], але простіше: жоден Flame-компонент не реагує на
/// появу/зникнення папки (на відміну від [LevelGroup]/[GroupComponent]),
/// тож досить одного загального [onChanged] замість пари
/// onAdded/onRemoved.
class LayerFolderRepository {
  final List<LayerFolder> _folders = [];

  void Function()? onChanged;

  List<LayerFolder> get all => List.unmodifiable(_folders);

  LayerFolder? find(String id) {
    for (final folder in _folders) {
      if (folder.id == id) return folder;
    }
    return null;
  }

  void add(LayerFolder folder) {
    _folders.add(folder);
    onChanged?.call();
  }

  void remove(String id) {
    _folders.removeWhere((f) => f.id == id);
    onChanged?.call();
  }

  /// Повністю замінює список (для відновлення знімка при undo/redo).
  void replaceAll(List<LayerFolder> newFolders) {
    _folders
      ..clear()
      ..addAll(newFolders);
    onChanged?.call();
  }
}
