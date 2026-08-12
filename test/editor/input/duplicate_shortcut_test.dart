import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leyak_lvl_editor/editor/input/duplicate_shortcut.dart';

KeyDownEvent _down(LogicalKeyboardKey key) =>
    KeyDownEvent(physicalKey: PhysicalKeyboardKey.keyD, logicalKey: key, timeStamp: Duration.zero);

KeyUpEvent _up(LogicalKeyboardKey key) =>
    KeyUpEvent(physicalKey: PhysicalKeyboardKey.keyD, logicalKey: key, timeStamp: Duration.zero);

void main() {
  const shortcut = DuplicateShortcut();

  test('triggers on Ctrl+D', () {
    final pressed = {LogicalKeyboardKey.controlLeft};

    expect(shortcut.isTrigger(_down(LogicalKeyboardKey.keyD), pressed), isTrue);
  });

  test('triggers on Cmd+D (meta)', () {
    final pressed = {LogicalKeyboardKey.metaLeft};

    expect(shortcut.isTrigger(_down(LogicalKeyboardKey.keyD), pressed), isTrue);
  });

  test('does not trigger on D alone', () {
    expect(shortcut.isTrigger(_down(LogicalKeyboardKey.keyD), {}), isFalse);
  });

  test('does not trigger on Ctrl+other key', () {
    final pressed = {LogicalKeyboardKey.controlLeft};

    expect(shortcut.isTrigger(_down(LogicalKeyboardKey.keyA), pressed), isFalse);
  });

  test('does not trigger on key up even with modifier held', () {
    final pressed = {LogicalKeyboardKey.controlLeft};

    expect(shortcut.isTrigger(_up(LogicalKeyboardKey.keyD), pressed), isFalse);
  });
}
