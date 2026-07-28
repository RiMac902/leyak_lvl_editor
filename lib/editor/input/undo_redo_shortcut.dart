import 'package:flutter/services.dart';

enum UndoRedoAction { undo, redo }

/// Єдина відповідальність — розпізнати Cmd/Ctrl+Z (undo), Cmd/Ctrl+Shift+Z
/// і Ctrl+Y (redo). Не знає нічого про [HistoryController].
class UndoRedoShortcut {
  const UndoRedoShortcut();

  static const _zKey = LogicalKeyboardKey.keyZ;
  static const _yKey = LogicalKeyboardKey.keyY;

  UndoRedoAction? resolve(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (event is! KeyDownEvent) return null;

    final isControlHeld =
        keysPressed.contains(LogicalKeyboardKey.controlLeft) ||
        keysPressed.contains(LogicalKeyboardKey.controlRight) ||
        keysPressed.contains(LogicalKeyboardKey.metaLeft) ||
        keysPressed.contains(LogicalKeyboardKey.metaRight);
    if (!isControlHeld) return null;

    if (event.logicalKey == _yKey) return UndoRedoAction.redo;
    if (event.logicalKey != _zKey) return null;

    final isShiftHeld =
        keysPressed.contains(LogicalKeyboardKey.shiftLeft) ||
        keysPressed.contains(LogicalKeyboardKey.shiftRight);
    return isShiftHeld ? UndoRedoAction.redo : UndoRedoAction.undo;
  }
}
