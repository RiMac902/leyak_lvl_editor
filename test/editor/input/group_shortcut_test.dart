import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leyak_lvl_editor/editor/input/group_shortcut.dart';

KeyDownEvent _down(LogicalKeyboardKey key) =>
    KeyDownEvent(physicalKey: PhysicalKeyboardKey.keyG, logicalKey: key, timeStamp: Duration.zero);

void main() {
  const shortcut = GroupShortcut();

  test('Ctrl+G resolves to group', () {
    final pressed = {LogicalKeyboardKey.controlLeft};

    expect(shortcut.resolve(_down(LogicalKeyboardKey.keyG), pressed), GroupShortcutAction.group);
  });

  test('Ctrl+Shift+G resolves to ungroup', () {
    final pressed = {LogicalKeyboardKey.controlLeft, LogicalKeyboardKey.shiftLeft};

    expect(shortcut.resolve(_down(LogicalKeyboardKey.keyG), pressed), GroupShortcutAction.ungroup);
  });

  test('Cmd+G (meta) resolves to group', () {
    final pressed = {LogicalKeyboardKey.metaLeft};

    expect(shortcut.resolve(_down(LogicalKeyboardKey.keyG), pressed), GroupShortcutAction.group);
  });

  test('plain G without a modifier resolves to null', () {
    expect(shortcut.resolve(_down(LogicalKeyboardKey.keyG), {}), isNull);
  });

  test('Ctrl+other key resolves to null', () {
    final pressed = {LogicalKeyboardKey.controlLeft};

    expect(
      shortcut.resolve(
        KeyDownEvent(
          physicalKey: PhysicalKeyboardKey.keyH,
          logicalKey: LogicalKeyboardKey.keyH,
          timeStamp: Duration.zero,
        ),
        pressed,
      ),
      isNull,
    );
  });
}
