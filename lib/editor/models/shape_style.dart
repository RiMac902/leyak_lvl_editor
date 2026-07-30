import 'package:flame/components.dart';

/// Додаткові параметри форми, що не вписуються в загальний
/// position/size/rotation — специфічні для конкретних [ShapeType]:
///
/// - [cornerRadius] — радіус заокруглення кутів (лише [ShapeType.rectangle]),
///   у координатах сітки (масштабується з tileSize, як і [TransformData.size]).
/// - [lineThickness] — товщина лінії (лише [ShapeType.line]), окремий
///   незалежний параметр, а НЕ похідний від bounding-box — інакше товщина
///   мимоволі "гуляла" б разом із довжиною/кутом лінії під час малювання.
/// - [lineStart]/[lineEnd] — реальні дві точки, між якими проведено лінію
///   (лише [ShapeType.line]), відносно [TransformData.position]/
///   [EntityPart.relativePosition]. Зберігаються явно, а не виводяться з
///   bounding-box (min/max кутів) — інакше напрямок лінії "стрибав" би
///   залежно від того, в який бік тягнеш драг.
class ShapeStyle {
  ShapeStyle({double? cornerRadius, double? lineThickness, Vector2? lineStart, Vector2? lineEnd})
    : cornerRadius = cornerRadius ?? 0,
      lineThickness = lineThickness ?? 0.15,
      lineStart = lineStart ?? Vector2.zero(),
      lineEnd = lineEnd ?? Vector2.all(1.0);

  double cornerRadius;
  double lineThickness;
  Vector2 lineStart;
  Vector2 lineEnd;

  ShapeStyle clone() => ShapeStyle(
    cornerRadius: cornerRadius,
    lineThickness: lineThickness,
    lineStart: lineStart.clone(),
    lineEnd: lineEnd.clone(),
  );
}
