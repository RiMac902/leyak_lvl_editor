import 'package:flame/components.dart';

/// Спільний контракт для інструментів редактора (малювання, виділення).
/// Дозволяє [ObjectManager] маршрутизувати drag-події, не знаючи деталей
/// конкретного інструменту.
abstract class EditorTool {
  void dragStart(Vector2 worldPos);
  void dragUpdate(Vector2 worldPos);
  void dragEnd();
}
