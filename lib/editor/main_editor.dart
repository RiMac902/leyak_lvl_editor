import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:leyak_lvl_editor/editor/components/editor_world.dart';

class MainEditor extends FlameGame
    with ScrollDetector, ScaleDetector, HasKeyboardHandlerComponents {
  late final EditorWorld editorWorld;

  double zoom = 1.0;
  double _startZoom = 1.0;

  double tileSize = 64.0;
  int gridWidth = 50;
  int gridLength = 50;

  bool _hasCenteredCamera = false;

  MainEditor() {
    editorWorld = EditorWorld();
    world = editorWorld;

    camera = CameraComponent(world: editorWorld)
      ..viewfinder.anchor = Anchor.center;

    camera.viewfinder.position = Vector2(0, 0);
  }

  /// [size] (реальний розмір канви) невідомий у конструкторі — Flame
  /// повідомляє його лише тут, при першому/наступних resize. Одноразово
  /// (за [_hasCenteredCamera]) центруємо камеру на BackgroundFrameComponent
  /// (перший екран рівня, прив'язаний до підлоги) замість (0,0) — після
  /// того, як сітка стала стартувати з x=0 замість центру, (0,0) — це
  /// верхній лівий кут рівня, і камера там показувала здебільшого
  /// порожнечу з контентом, "стирчащим" у правому нижньому куті екрана.
  /// Лише один раз — щоб зміна розміру вікна не смикала камеру назад,
  /// якщо користувач уже кудись перейшов.
  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (_hasCenteredCamera) return;
    _hasCenteredCamera = true;

    final groundY = gridLength * tileSize;
    camera.viewfinder.position = Vector2(size.x / 2, groundY - size.y / 2);
  }

  @override
  void onScaleStart(ScaleStartInfo info) {
    _startZoom = zoom;
  }

  @override
  void onScaleUpdate(ScaleUpdateInfo info) {
    final moveDelta = info.delta.global;
    if (!moveDelta.isZero()) {
      camera.moveBy(-moveDelta / zoom);
    }

    if (info.scale.global.x != 1.0) {
      zoom = (_startZoom * info.scale.global.x).clamp(0.2, 5.0);
      camera.viewfinder.zoom = zoom;
    }
  }

  @override
  void onScroll(PointerScrollInfo info) {
    final scrollDelta = info.scrollDelta.global;
    if (!scrollDelta.isZero()) {
      camera.moveBy(scrollDelta / zoom);
    }
  }
}
