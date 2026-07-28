import 'package:flutter/services.dart';

/// Єдина відповідальність — розпізнати Cmd/Ctrl+M для об'єднання поточного
/// виділення в одну складену сутність. Не знає нічого про [MergeService].
class MergeShortcut {
  const MergeShortcut();

  static const _key = LogicalKeyboardKey.keyM;

  bool isTrigger(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (event is! KeyDownEvent || event.logicalKey != _key) return false;

    return keysPressed.contains(LogicalKeyboardKey.controlLeft) ||
        keysPressed.contains(LogicalKeyboardKey.controlRight) ||
        keysPressed.contains(LogicalKeyboardKey.metaLeft) ||
        keysPressed.contains(LogicalKeyboardKey.metaRight);
  }
}
