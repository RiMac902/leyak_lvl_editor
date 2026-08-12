import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leyak_lvl_editor/editor/input/merge_shortcut.dart';

KeyDownEvent _down(LogicalKeyboardKey key) =>
    KeyDownEvent(physicalKey: PhysicalKeyboardKey.keyM, logicalKey: key, timeStamp: Duration.zero);

void main() {
  const shortcut = MergeShortcut();

  test('triggers on Ctrl+M', () {
    final pressed = {LogicalKeyboardKey.controlLeft};

    expect(shortcut.isTrigger(_down(LogicalKeyboardKey.keyM), pressed), isTrue);
  });

  test('triggers on Cmd+M (meta)', () {
    final pressed = {LogicalKeyboardKey.metaRight};

    expect(shortcut.isTrigger(_down(LogicalKeyboardKey.keyM), pressed), isTrue);
  });

  test('does not trigger on M alone', () {
    expect(shortcut.isTrigger(_down(LogicalKeyboardKey.keyM), {}), isFalse);
  });
}
