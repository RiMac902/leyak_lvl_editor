import 'package:flutter_test/flutter_test.dart';
import 'package:leyak_lvl_editor/editor/models/editor_mode.dart';

void main() {
  group('EditorModeLabel', () {
    test('every mode has a distinct, non-empty label', () {
      final labels = EditorMode.values.map((m) => m.label).toSet();

      expect(labels, hasLength(EditorMode.values.length));
      expect(labels.every((l) => l.isNotEmpty), isTrue);
    });

    test('maps each mode to its documented label', () {
      expect(EditorMode.draw.label, 'DRAW / FORMS');
      expect(EditorMode.select.label, 'SELECT & MOVE');
      expect(EditorMode.placeSpawn.label, 'PLAYER SPAWN');
      expect(EditorMode.cameraPath.label, 'CAMERA PATH');
    });
  });
}
