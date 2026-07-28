import 'package:flutter/services.dart';

/// Єдина відповідальність — розпізнати Delete/Backspace для видалення
/// поточного виділення. Не знає нічого про [SelectionTool] чи стан сцени.
class DeleteShortcut {
  const DeleteShortcut();

  bool isTrigger(KeyEvent event) =>
      event is KeyDownEvent &&
      (event.logicalKey == LogicalKeyboardKey.delete ||
          event.logicalKey == LogicalKeyboardKey.backspace);
}
