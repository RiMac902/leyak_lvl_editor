import 'package:flame/components.dart';
import 'package:leyak_lvl_editor/game/camera/camera_node.dart';
import 'package:leyak_lvl_editor/game/components/player.dart';

/// Розв'язані (проміжні, вже інтерпольовані за X гравця) параметри камери
/// на цей момент — не зберігається, лише проміжний результат [_resolve].
class _CameraTarget {
  _CameraTarget({required this.zoom, required this.offset, required this.transitionDuration});

  final double zoom;
  final Vector2 offset;
  final double transitionDuration;
}

/// Єдина відповідальність — вести камеру вздовж [CameraNode]-шляху: як
/// тільки гравець рухається, знаходить дві найближчі точки шляху, які
/// його обрамляють (за X), лінійно інтерполює між ними zoom/offset, а
/// потім ЩЕ РАЗ згладжує перехід у часі (через `transitionDuration`
/// найближчого відрізка) — тому й просторова зміна вздовж шляху, і
/// часова зміна при кожному новому відрізку виходять плавними, а не
/// стрибками.
///
/// [initialize] викликається один раз одразу після завантаження рівня —
/// миттєво "прилипає" до першої цілі БЕЗ згладжування (задовольняє вимогу
/// "камера миттєво фіксується на гравцеві на старті"), тоді як [update]
/// (щокадру) використовує повне згладжування для всіх наступних переходів.
class CameraPathController {
  CameraPathController(this.nodes);

  final List<CameraNode> nodes;

  double zoom = 1.0;
  Vector2 offset = Vector2.zero();

  void initialize(Player player) {
    final target = _resolve(_playerCenterX(player));
    zoom = target.zoom;
    offset = target.offset.clone();
  }

  void update(double dt, CameraComponent camera, Player player) {
    final target = _resolve(_playerCenterX(player));
    final t = target.transitionDuration <= 0
        ? 1.0
        : (dt / target.transitionDuration).clamp(0.0, 1.0);

    zoom += (target.zoom - zoom) * t;
    offset += (target.offset - offset) * t;

    camera.viewfinder.zoom = zoom;
    camera.viewfinder.position = _playerCenter(player) + offset;
  }

  double _playerCenterX(Player player) => player.position.x + player.playerSize / 2;

  Vector2 _playerCenter(Player player) =>
      player.position + Vector2.all(player.playerSize / 2);

  _CameraTarget _resolve(double playerX) {
    if (nodes.isEmpty) {
      return _CameraTarget(zoom: 1.0, offset: Vector2.zero(), transitionDuration: 0.3);
    }
    if (nodes.length == 1 || playerX <= nodes.first.x) {
      return _fromNode(nodes.first);
    }
    if (playerX >= nodes.last.x) {
      return _fromNode(nodes.last);
    }

    for (var i = 0; i < nodes.length - 1; i++) {
      final a = nodes[i];
      final b = nodes[i + 1];
      if (playerX >= a.x && playerX <= b.x) {
        final span = b.x - a.x;
        final t = span == 0 ? 0.0 : (playerX - a.x) / span;
        return _CameraTarget(
          zoom: _lerp(a.zoom, b.zoom, t),
          offset: Vector2(_lerp(a.offset.x, b.offset.x, t), _lerp(a.offset.y, b.offset.y, t)),
          transitionDuration: _lerp(a.transitionDuration, b.transitionDuration, t),
        );
      }
    }
    return _fromNode(nodes.last);
  }

  _CameraTarget _fromNode(CameraNode node) => _CameraTarget(
    zoom: node.zoom,
    offset: node.offset.clone(),
    transitionDuration: node.transitionDuration,
  );

  double _lerp(double a, double b, double t) => a + (b - a) * t;
}
