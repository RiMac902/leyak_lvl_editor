import 'package:flame/components.dart';

/// Додаткові параметри форми, що не вписуються в загальний
/// position/size/rotation — специфічні для конкретних [ShapeType]:
///
/// - [cornerRadii] — незалежний радіус заокруглення КОЖНОГО кута, в
///   координатах сітки (масштабується з tileSize, як і [TransformData.size]).
///   Список завжди довжини 4, але сенс індексів залежить від [ShapeType]
///   (див. [shapePathFor]):
///   - [ShapeType.rectangle]: 0..3 = top-left, top-right, bottom-right,
///     bottom-left (як CSS `border-radius`).
///   - [ShapeType.triangle]: 0..2 = вершина (top), bottom-right,
///     bottom-left; індекс 3 не використовується.
///   - [ShapeType.line]: 0 = заокруглення початкового кінця, 1 —
///     кінцевого; індекси 2-3 не використовуються.
///   - [ShapeType.ellipse]: не використовується (кутів немає).
/// - [lineThickness] — товщина лінії (лише [ShapeType.line]), окремий
///   незалежний параметр, а НЕ похідний від bounding-box — інакше товщина
///   мимоволі "гуляла" б разом із довжиною/кутом лінії під час малювання.
/// - [lineStart]/[lineEnd] — реальні дві точки, між якими проведено лінію
///   (лише [ShapeType.line]), відносно [TransformData.position]/
///   [EntityPart.relativePosition]. Зберігаються явно, а не виводяться з
///   bounding-box (min/max кутів) — інакше напрямок лінії "стрибав" би
///   залежно від того, в який бік тягнеш драг.
class ShapeStyle {
  ShapeStyle({
    List<double>? cornerRadii,
    double? lineThickness,
    Vector2? lineStart,
    Vector2? lineEnd,
  }) : cornerRadii = cornerRadii ?? List<double>.filled(4, 0),
       lineThickness = lineThickness ?? 0.15,
       lineStart = lineStart ?? Vector2.zero(),
       lineEnd = lineEnd ?? Vector2.all(1.0);

  List<double> cornerRadii;
  double lineThickness;
  Vector2 lineStart;
  Vector2 lineEnd;

  ShapeStyle clone() => ShapeStyle(
    cornerRadii: List<double>.of(cornerRadii),
    lineThickness: lineThickness,
    lineStart: lineStart.clone(),
    lineEnd: lineEnd.clone(),
  );
}
