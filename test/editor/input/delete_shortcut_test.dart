import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leyak_lvl_editor/editor/input/delete_shortcut.dart';

KeyDownEvent _down(LogicalKeyboardKey key) =>
    KeyDownEvent(physicalKey: PhysicalKeyboardKey.delete, logicalKey: key, timeStamp: Duration.zero);

KeyUpEvent _up(LogicalKeyboardKey key) =>
    KeyUpEvent(physicalKey: PhysicalKeyboardKey.delete, logicalKey: key, timeStamp: Duration.zero);

void main() {
  const shortcut = DeleteShortcut();

  test('triggers on Delete key down', () {
    expect(shortcut.isTrigger(_down(LogicalKeyboardKey.delete)), isTrue);
  });

  test('triggers on Backspace key down', () {
    expect(shortcut.isTrigger(_down(LogicalKeyboardKey.backspace)), isTrue);
  });

  test('does not trigger on key up', () {
    expect(shortcut.isTrigger(_up(LogicalKeyboardKey.delete)), isFalse);
  });

  test('does not trigger on unrelated keys', () {
    expect(shortcut.isTrigger(_down(LogicalKeyboardKey.keyA)), isFalse);
  });
}
