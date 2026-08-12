import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leyak_lvl_editor/editor/input/undo_redo_shortcut.dart';

KeyDownEvent _down(LogicalKeyboardKey key) =>
    KeyDownEvent(physicalKey: PhysicalKeyboardKey.keyZ, logicalKey: key, timeStamp: Duration.zero);

void main() {
  const shortcut = UndoRedoShortcut();

  test('Ctrl+Z resolves to undo', () {
    final pressed = {LogicalKeyboardKey.controlLeft};

    expect(shortcut.resolve(_down(LogicalKeyboardKey.keyZ), pressed), UndoRedoAction.undo);
  });

  test('Ctrl+Shift+Z resolves to redo', () {
    final pressed = {LogicalKeyboardKey.controlLeft, LogicalKeyboardKey.shiftLeft};

    expect(shortcut.resolve(_down(LogicalKeyboardKey.keyZ), pressed), UndoRedoAction.redo);
  });

  test('Ctrl+Y resolves to redo regardless of shift', () {
    final pressed = {LogicalKeyboardKey.controlLeft};

    expect(shortcut.resolve(_down(LogicalKeyboardKey.keyY), pressed), UndoRedoAction.redo);
  });

  test('Cmd+Z (meta) resolves to undo', () {
    final pressed = {LogicalKeyboardKey.metaLeft};

    expect(shortcut.resolve(_down(LogicalKeyboardKey.keyZ), pressed), UndoRedoAction.undo);
  });

  test('Z without a modifier resolves to null', () {
    expect(shortcut.resolve(_down(LogicalKeyboardKey.keyZ), {}), isNull);
  });

  test('Ctrl+other key resolves to null', () {
    final pressed = {LogicalKeyboardKey.controlLeft};

    expect(
      shortcut.resolve(
        KeyDownEvent(
          physicalKey: PhysicalKeyboardKey.keyA,
          logicalKey: LogicalKeyboardKey.keyA,
          timeStamp: Duration.zero,
        ),
        pressed,
      ),
      isNull,
    );
  });
}
