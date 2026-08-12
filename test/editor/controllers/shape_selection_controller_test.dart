import 'package:flutter_test/flutter_test.dart';
import 'package:leyak_lvl_editor/editor/controllers/shape_selection_controller.dart';
import 'package:leyak_lvl_editor/editor/models/shape_type.dart';

void main() {
  test('starts with rectangle selected', () {
    expect(ShapeSelectionController().current, ShapeType.rectangle);
  });

  test('select updates the current shape', () {
    final controller = ShapeSelectionController();

    controller.select(ShapeType.ellipse);

    expect(controller.current, ShapeType.ellipse);
  });

  test('select can be called repeatedly with different shapes', () {
    final controller = ShapeSelectionController();

    controller.select(ShapeType.line);
    controller.select(ShapeType.path);

    expect(controller.current, ShapeType.path);
  });
}
