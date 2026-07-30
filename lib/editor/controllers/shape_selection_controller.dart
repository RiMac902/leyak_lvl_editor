import 'package:leyak_lvl_editor/editor/models/shape_type.dart';

/// Єдина відповідальність — яку [ShapeType] малює [DrawTool] наступного
/// разу. Обирається через [ShapeToolbar] у Flutter-дереві; сам нічого не
/// знає ні про UI, ні про [DrawTool] — суто держатель поточного значення.
class ShapeSelectionController {
  ShapeType _current = ShapeType.rectangle;

  ShapeType get current => _current;

  void select(ShapeType shape) => _current = shape;
}
