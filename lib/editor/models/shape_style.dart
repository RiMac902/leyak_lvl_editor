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
///   - [ShapeType.ellipse]/[ShapeType.path]: не використовується.
/// - [lineThickness] — товщина лінії (лише [ShapeType.line]), окремий
///   незалежний параметр, а НЕ похідний від bounding-box — інакше товщина
///   мимоволі "гуляла" б разом із довжиною/кутом лінії під час малювання.
/// - [lineStart]/[lineEnd] — реальні дві точки, між якими проведено лінію
///   (лише [ShapeType.line]), відносно [TransformData.position]/
///   [EntityPart.relativePosition]. Зберігаються явно, а не виводяться з
///   bounding-box (min/max кутів) — інакше напрямок лінії "стрибав" би
///   залежно від того, в який бік тягнеш драг.
/// - [pathPoints]/[pathHandlesIn]/[pathHandlesOut]/[pathClosed] — лише
///   [ShapeType.path], див. документацію кожного поля нижче.
class ShapeStyle {
  ShapeStyle({
    List<double>? cornerRadii,
    double? lineThickness,
    Vector2? lineStart,
    Vector2? lineEnd,
    List<Vector2>? pathPoints,
    List<Vector2>? pathHandlesIn,
    List<Vector2>? pathHandlesOut,
    this.pathClosed = false,
  }) : cornerRadii = cornerRadii ?? List<double>.filled(4, 0),
       lineThickness = lineThickness ?? 0.15,
       lineStart = lineStart ?? Vector2.zero(),
       lineEnd = lineEnd ?? Vector2.all(1.0),
       pathPoints = pathPoints ?? [],
       pathHandlesIn = pathHandlesIn ?? [],
       pathHandlesOut = pathHandlesOut ?? [];

  List<double> cornerRadii;
  double lineThickness;
  Vector2 lineStart;
  Vector2 lineEnd;

  /// Якірні точки контуру (лише [ShapeType.path]), у координатах сітки,
  /// ВІДНОСНО [TransformData.position] — той самий bounding-box-відносний
  /// підхід, що й [lineStart]/[lineEnd]. На відміну від решти форм, bbox
  /// тут похідний від цих точок (див. `recomputePathBounds`), а не навпаки.
  List<Vector2> pathPoints;

  /// Bezier-хендл кривої, що входить у [pathPoints]\[i\] (з боку
  /// попередньої точки) — відносно САМОЇ [pathPoints]\[i\] (не
  /// transform.position), тож не потребує перерахунку, коли рухається
  /// сам якір. Нульовий вектор = гострий кут (без кривої з цього боку).
  List<Vector2> pathHandlesIn;

  /// Те саме, що [pathHandlesIn], але для кривої, що виходить із
  /// [pathPoints]\[i\] у бік наступної точки.
  List<Vector2> pathHandlesOut;

  /// Якщо true — контур замкнений: остання точка з'єднується кривою з
  /// першою (полігон), інакше лишається відкритим відрізком-лінією.
  bool pathClosed;

  ShapeStyle clone() => ShapeStyle(
    cornerRadii: List<double>.of(cornerRadii),
    lineThickness: lineThickness,
    lineStart: lineStart.clone(),
    lineEnd: lineEnd.clone(),
    pathPoints: pathPoints.map((v) => v.clone()).toList(),
    pathHandlesIn: pathHandlesIn.map((v) => v.clone()).toList(),
    pathHandlesOut: pathHandlesOut.map((v) => v.clone()).toList(),
    pathClosed: pathClosed,
  );
}
