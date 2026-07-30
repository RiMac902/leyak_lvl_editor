/// Форма, якою малюється [LevelEntity]/[EntityPart]. Здебільшого вписана в
/// той самий bounding-box ([TransformData.position]/[size] або
/// [EntityPart.relativePosition]/[size]) — drag/hit-test/снепінг лишаються
/// прямокутними незалежно від форми (той самий підхід, що й у більшості
/// векторних редакторів: тягнеш прямокутну рамку, форма малюється всередині).
///
/// [path] — єдиний виняток: багатоточковий bezier-контур (Pen tool), де
/// bounding-box НЕ первинна геометрія, а похідне значення — перераховується
/// й "перебазовується" після кожної зміни точок (див.
/// `recomputePathBounds` у `lib/editor/geometry/path_bounds.dart`), а не
/// задається драгом однієї рамки, як в усіх інших форм.
///
/// Навмисно без diamond/star — це не базові форми: ромб отримується
/// поворотом прямокутника ([TransformData.rotation]), зірка — об'єднанням
/// (`MergeService`) кількох трикутних частинок.
enum ShapeType { rectangle, ellipse, triangle, line, path }
