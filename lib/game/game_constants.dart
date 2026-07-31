/// Константи ігрового playtest-рантайму — окремі від `lib/editor/`, який
/// має власний `MainEditor.tileSize`.
///
/// [gridSize]/[gameSpeed] узгоджені з `MainEditor.tileSize = 64` (див.
/// `lib/editor/main_editor.dart`) — вихідні значення довідкового проєкту
/// (gridSize=32, gameSpeed=200 px/s) масштабовані ×2, щоб зберегти той
/// самий "філ" (та сама дистанція/висота стрибка в клітинках, та сама
/// швидкість у клітинках/с), а не просто продубльовані як є.
class GameConstants {
  const GameConstants._();

  static const double gridSize = 64.0;
  static const double gameSpeed = 400.0;
}
