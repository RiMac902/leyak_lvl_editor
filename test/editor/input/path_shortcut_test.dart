import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leyak_lvl_editor/editor/input/path_shortcut.dart';

KeyDownEvent _down(LogicalKeyboardKey key) =>
    KeyDownEvent(physicalKey: PhysicalKeyboardKey.enter, logicalKey: key, timeStamp: Duration.zero);

KeyUpEvent _up(LogicalKeyboardKey key) =>
    KeyUpEvent(physicalKey: PhysicalKeyboardKey.enter, logicalKey: key, timeStamp: Duration.zero);

void main() {
  const shortcut = PathShortcut();

  test('Enter resolves to finish', () {
    expect(shortcut.resolve(_down(LogicalKeyboardKey.enter)), PathShortcutAction.finish);
  });

  test('numpad Enter also resolves to finish', () {
    expect(shortcut.resolve(_down(LogicalKeyboardKey.numpadEnter)), PathShortcutAction.finish);
  });

  test('Escape resolves to cancel', () {
    expect(shortcut.resolve(_down(LogicalKeyboardKey.escape)), PathShortcutAction.cancel);
  });

  test('unrelated key resolves to null', () {
    expect(shortcut.resolve(_down(LogicalKeyboardKey.keyA)), isNull);
  });

  test('key up does not resolve', () {
    expect(shortcut.resolve(_up(LogicalKeyboardKey.enter)), isNull);
  });
}
