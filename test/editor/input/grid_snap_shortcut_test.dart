import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leyak_lvl_editor/editor/input/grid_snap_shortcut.dart';

void main() {
  const shortcut = GridSnapShortcut();

  test('toggles on G key down', () {
    final event = KeyDownEvent(
      physicalKey: PhysicalKeyboardKey.keyG,
      logicalKey: LogicalKeyboardKey.keyG,
      timeStamp: Duration.zero,
    );

    expect(shortcut.isToggle(event), isTrue);
  });

  test('does not toggle on G key up', () {
    final event = KeyUpEvent(
      physicalKey: PhysicalKeyboardKey.keyG,
      logicalKey: LogicalKeyboardKey.keyG,
      timeStamp: Duration.zero,
    );

    expect(shortcut.isToggle(event), isFalse);
  });

  test('does not toggle on unrelated key', () {
    final event = KeyDownEvent(
      physicalKey: PhysicalKeyboardKey.keyH,
      logicalKey: LogicalKeyboardKey.keyH,
      timeStamp: Duration.zero,
    );

    expect(shortcut.isToggle(event), isFalse);
  });
}
