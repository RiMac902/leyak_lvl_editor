import 'package:flutter_test/flutter_test.dart';
import 'package:leyak_lvl_editor/editor/controllers/editor_mode_controller.dart';
import 'package:leyak_lvl_editor/editor/models/editor_mode.dart';

void main() {
  test('starts in draw mode', () {
    expect(EditorModeController().currentMode, EditorMode.draw);
  });

  test('setMode changes the mode and notifies listeners', () {
    EditorMode? notified;
    final controller = EditorModeController(onModeChanged: (m) => notified = m);

    controller.setMode(EditorMode.select);

    expect(controller.currentMode, EditorMode.select);
    expect(notified, EditorMode.select);
  });

  test('setMode with the same mode does not notify', () {
    var callCount = 0;
    final controller = EditorModeController(onModeChanged: (_) => callCount++);

    controller.setMode(EditorMode.draw);

    expect(callCount, 0);
  });

  test('setMode with a different mode after a no-op change does notify', () {
    var callCount = 0;
    final controller = EditorModeController(onModeChanged: (_) => callCount++);

    controller.setMode(EditorMode.draw);
    controller.setMode(EditorMode.cameraPath);

    expect(callCount, 1);
    expect(controller.currentMode, EditorMode.cameraPath);
  });
}
