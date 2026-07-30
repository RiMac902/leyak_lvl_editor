/// Форма, якою малюється [LevelEntity]/[EntityPart]. Завжди вписана в той
/// самий bounding-box ([TransformData.position]/[size] або
/// [EntityPart.relativePosition]/[size]) — drag/hit-test/снепінг лишаються
/// прямокутними незалежно від форми (той самий підхід, що й у більшості
/// векторних редакторів: тягнеш прямокутну рамку, форма малюється всередині).
///
/// Навмисно без diamond/star — це не базові форми: ромб отримується
/// поворотом прямокутника ([TransformData.rotation]), зірка — об'єднанням
/// (`MergeService`) кількох трикутних частинок.
enum ShapeType { rectangle, ellipse, triangle, line }
