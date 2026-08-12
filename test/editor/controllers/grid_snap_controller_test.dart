import 'package:flutter_test/flutter_test.dart';
import 'package:leyak_lvl_editor/editor/controllers/grid_snap_controller.dart';

void main() {
  test('starts with snap enabled', () {
    expect(GridSnapController().snapEnabled, isTrue);
  });

  test('toggle flips the flag and notifies with the new value', () {
    bool? notified;
    final controller = GridSnapController(onSnapChanged: (v) => notified = v);

    controller.toggle();

    expect(controller.snapEnabled, isFalse);
    expect(notified, isFalse);
  });

  test('toggling twice returns to the original state', () {
    final controller = GridSnapController();

    controller.toggle();
    controller.toggle();

    expect(controller.snapEnabled, isTrue);
  });

  test('works without a listener attached', () {
    final controller = GridSnapController();

    expect(controller.toggle, returnsNormally);
  });
}
