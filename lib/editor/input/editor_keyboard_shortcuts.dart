import 'package:flutter/services.dart';
import 'package:leyak_lvl_editor/editor/models/editor_mode.dart';

/// Єдина відповідальність — переклад клавіатурної події у [EditorMode].
/// Нічого не знає про стан редактора чи оверлеї.
class EditorKeyboardShortcuts {
  const EditorKeyboardShortcuts();

  static final Map<LogicalKeyboardKey, EditorMode> _bindings = {
    LogicalKeyboardKey.keyS: EditorMode.select,
    LogicalKeyboardKey.keyF: EditorMode.draw,
  };

  EditorMode? resolve(KeyEvent event) {
    if (event is! KeyDownEvent) return null;
    return _bindings[event.logicalKey];
  }
}
