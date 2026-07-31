import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:leyak_lvl_editor/editor/models/level_entity.dart';
import 'package:leyak_lvl_editor/game/camera/camera_path_controller.dart';
import 'package:leyak_lvl_editor/game/level_loader.dart';

/// Ігровий playtest-рантайм — окремий `FlameGame` від редакторського
/// `MainEditor`. Приймає знімок сутностей поточного рівня (незалежну
/// глибоку копію — див. виклик на екрані запуску, `PlaytestScreen`) і
/// [tileSize]/[groundY], узгоджені з ЖИВИМИ значеннями `MainEditor` у
/// момент натискання Play (а не жорстко закодовані тут), щоб розміщена в
/// редакторі геометрія збігалась 1:1 у грі.
class PlaytestGame extends FlameGame with HasKeyboardHandlerComponents, HasCollisionDetection {
  PlaytestGame({
    required this.entities,
    required this.tileSize,
    required this.groundY,
    this.onDeath,
    this.onWin,
  });

  final List<LevelEntity> entities;
  final double tileSize;
  final double groundY;
  final void Function()? onDeath;
  final void Function()? onWin;

  late final LoadedLevel level;
  late final CameraPathController _cameraController;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    level = buildLevel(entities, tileSize: tileSize, groundY: groundY);
    await world.addAll(level.components);

    level.player.onDied = () => onDeath?.call();
    level.player.onWon = () => onWin?.call();

    // Камера НЕ використовує вбудований `camera.follow` — у нього немає
    // гачка для zoom/offset-інтерполяції вздовж CameraNode-шляху, тож
    // CameraPathController веде камеру сам, щокадру в [update].
    camera.viewfinder.anchor = Anchor.center;
    _cameraController = CameraPathController(level.cameraNodes);
    _cameraController.initialize(level.player);
    camera.viewfinder.zoom = _cameraController.zoom;
    camera.viewfinder.position = level.player.position + _cameraController.offset;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _cameraController.update(dt, camera, level.player);
  }
}
