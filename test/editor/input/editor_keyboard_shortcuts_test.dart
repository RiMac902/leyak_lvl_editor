import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leyak_lvl_editor/editor/input/editor_keyboard_shortcuts.dart';
import 'package:leyak_lvl_editor/editor/models/editor_mode.dart';

KeyDownEvent _down(LogicalKeyboardKey key) =>
    KeyDownEvent(physicalKey: PhysicalKeyboardKey.keyS, logicalKey: key, timeStamp: Duration.zero);

KeyUpEvent _up(LogicalKeyboardKey key) =>
    KeyUpEvent(physicalKey: PhysicalKeyboardKey.keyS, logicalKey: key, timeStamp: Duration.zero);

void main() {
  const shortcuts = EditorKeyboardShortcuts();

  test('S resolves to select mode', () {
    expect(shortcuts.resolve(_down(LogicalKeyboardKey.keyS)), EditorMode.select);
  });

  test('F resolves to draw mode', () {
    expect(shortcuts.resolve(_down(LogicalKeyboardKey.keyF)), EditorMode.draw);
  });

  test('P resolves to placeSpawn mode', () {
    expect(shortcuts.resolve(_down(LogicalKeyboardKey.keyP)), EditorMode.placeSpawn);
  });

  test('C resolves to cameraPath mode', () {
    expect(shortcuts.resolve(_down(LogicalKeyboardKey.keyC)), EditorMode.cameraPath);
  });

  test('unbound key resolves to null', () {
    expect(shortcuts.resolve(_down(LogicalKeyboardKey.keyZ)), isNull);
  });

  test('key up does not resolve', () {
    expect(shortcuts.resolve(_up(LogicalKeyboardKey.keyS)), isNull);
  });
}
