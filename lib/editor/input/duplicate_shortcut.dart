import 'package:flutter/services.dart';

/// Єдина відповідальність — розпізнати Cmd/Ctrl+D для дублювання поточного
/// виділення. Не знає нічого про сутності чи стан сцени.
class DuplicateShortcut {
  const DuplicateShortcut();

  static const _key = LogicalKeyboardKey.keyD;

  bool isTrigger(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (event is! KeyDownEvent || event.logicalKey != _key) return false;

    return keysPressed.contains(LogicalKeyboardKey.controlLeft) ||
        keysPressed.contains(LogicalKeyboardKey.controlRight) ||
        keysPressed.contains(LogicalKeyboardKey.metaLeft) ||
        keysPressed.contains(LogicalKeyboardKey.metaRight);
  }
}
