import 'package:flutter/services.dart';

/// Єдина відповідальність — розпізнати клавішу перемикання snap-to-grid.
/// Не знає нічого про [GridSnapController] чи стан редактора.
class GridSnapShortcut {
  const GridSnapShortcut();

  static const _key = LogicalKeyboardKey.keyG;

  bool isToggle(KeyEvent event) => event is KeyDownEvent && event.logicalKey == _key;
}
