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

  MainEditor() {
    editorWorld = EditorWorld();
    world = editorWorld;

    camera = CameraComponent(world: editorWorld)
      ..viewfinder.anchor = Anchor.center;

    camera.viewfinder.position = Vector2(0, 0);
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
