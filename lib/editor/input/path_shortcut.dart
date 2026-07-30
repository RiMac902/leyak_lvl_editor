import 'package:flutter/services.dart';

/// Дії, що завершують побудову контуру [PathTool] — не плутати з
/// [UndoRedoAction]/[GroupShortcutAction]: тут завжди рівно одна активна
/// дія на подію (Enter XOR Escape), тож досить enum без окремого resolve-
/// перевантаження за модифікаторами.
enum PathShortcutAction { finish, cancel }

/// Єдина відповідальність — розпізнати Enter (завершити відкритий контур)
/// і Escape (скасувати побудову) під час малювання [PathTool]. Не знає
/// нічого про сам [PathTool] чи стан сцени.
class PathShortcut {
  const PathShortcut();

  PathShortcutAction? resolve(KeyEvent event) {
    if (event is! KeyDownEvent) return null;
    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter) {
      return PathShortcutAction.finish;
    }
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      return PathShortcutAction.cancel;
    }
    return null;
  }
}
