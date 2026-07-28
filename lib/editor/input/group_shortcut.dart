import 'package:flutter/services.dart';

enum GroupShortcutAction { group, ungroup }

/// Єдина відповідальність — розпізнати Ctrl+G (групувати) і Ctrl+Shift+G
/// (розгрупувати). Не знає нічого про [GroupingService] чи стан редактора.
/// Вимагає утриманого Control, тому не конфліктує зі звичайним G
/// ([GridSnapShortcut]) — але composition root все одно мусить перевіряти
/// цей клас РАНІШЕ за [GridSnapShortcut], бо той сам по собі реагує на
/// будь-яке натискання G незалежно від модифікаторів.
class GroupShortcut {
  const GroupShortcut();

  static const _key = LogicalKeyboardKey.keyG;

  GroupShortcutAction? resolve(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (event is! KeyDownEvent || event.logicalKey != _key) return null;

    final isControlHeld =
        keysPressed.contains(LogicalKeyboardKey.controlLeft) ||
        keysPressed.contains(LogicalKeyboardKey.controlRight) ||
        keysPressed.contains(LogicalKeyboardKey.metaLeft) ||
        keysPressed.contains(LogicalKeyboardKey.metaRight);
    if (!isControlHeld) return null;

    final isShiftHeld =
        keysPressed.contains(LogicalKeyboardKey.shiftLeft) ||
        keysPressed.contains(LogicalKeyboardKey.shiftRight);

    return isShiftHeld ? GroupShortcutAction.ungroup : GroupShortcutAction.group;
  }
}
