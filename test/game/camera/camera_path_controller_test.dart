import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leyak_lvl_editor/game/camera/camera_node.dart';
import 'package:leyak_lvl_editor/game/camera/camera_path_controller.dart';
import 'package:leyak_lvl_editor/game/components/player.dart';

Player _playerAt(double x) {
  final player = Player(spawnPosition: Vector2.zero(), groundY: 500, playerSize: 32);
  player.position.setValues(x - player.playerSize / 2, 0);
  return player;
}

CameraNode _node({
  required double x,
  double zoom = 1.0,
  Vector2? offset,
  double transitionDuration = 0.3,
}) {
  return CameraNode(
    x: x,
    zoom: zoom,
    offset: offset ?? Vector2.zero(),
    transitionDuration: transitionDuration,
  );
}

void main() {
  group('initialize', () {
    test('with no nodes, snaps to the default zoom 1.0 / zero offset', () {
      final controller = CameraPathController([]);

      controller.initialize(_playerAt(100));

      expect(controller.zoom, 1.0);
      expect(controller.offset, Vector2.zero());
    });

    test('with a single node, snaps to that node regardless of player position', () {
      final controller = CameraPathController([_node(x: 0, zoom: 2.0, offset: Vector2(5, 5))]);

      controller.initialize(_playerAt(999));

      expect(controller.zoom, 2.0);
      expect(controller.offset, Vector2(5, 5));
    });

    test('snaps instantly, without any smoothing, to the resolved target', () {
      final controller = CameraPathController([_node(x: 0, zoom: 3.0)]);

      controller.initialize(_playerAt(0));

      expect(controller.zoom, 3.0);
    });
  });

  group('update - node resolution', () {
    test('player before the first node uses the first node target (flat extrapolation)', () {
      final controller = CameraPathController([
        _node(x: 100, zoom: 2.0),
        _node(x: 200, zoom: 4.0),
      ]);
      final camera = CameraComponent();

      controller.update(100.0, camera, _playerAt(0));

      expect(controller.zoom, 2.0);
    });

    test('player after the last node uses the last node target (flat extrapolation)', () {
      final controller = CameraPathController([
        _node(x: 100, zoom: 2.0),
        _node(x: 200, zoom: 4.0),
      ]);
      final camera = CameraComponent();

      controller.update(100.0, camera, _playerAt(9999));

      expect(controller.zoom, 4.0);
    });

    test('player exactly halfway between two nodes linearly interpolates zoom/offset', () {
      final controller = CameraPathController([
        _node(x: 0, zoom: 1.0, offset: Vector2(0, 0)),
        _node(x: 100, zoom: 3.0, offset: Vector2(10, 20)),
      ]);
      final camera = CameraComponent();

      // Large dt relative to transitionDuration forces an instant snap
      // (t clamped to 1.0), so we can assert the resolved target directly.
      controller.update(100.0, camera, _playerAt(50));

      expect(controller.zoom, closeTo(2.0, 1e-9));
      expect(controller.offset.x, closeTo(5.0, 1e-9));
      expect(controller.offset.y, closeTo(10.0, 1e-9));
    });
  });

  group('update - time smoothing', () {
    test('a small dt only partially closes the gap towards the target', () {
      final controller = CameraPathController([_node(x: 0, zoom: 2.0, transitionDuration: 1.0)])
        ..zoom = 1.0;
      final camera = CameraComponent();

      controller.update(0.1, camera, _playerAt(0));

      // t = dt / transitionDuration = 0.1 -> zoom moves 10% of the way from 1.0 to 2.0.
      expect(controller.zoom, closeTo(1.1, 1e-9));
    });

    test('transitionDuration <= 0 snaps instantly regardless of dt', () {
      final controller = CameraPathController([_node(x: 0, zoom: 5.0, transitionDuration: 0.0)])
        ..zoom = 1.0;
      final camera = CameraComponent();

      controller.update(0.001, camera, _playerAt(0));

      expect(controller.zoom, 5.0);
    });

    test('writes the resolved zoom/position into the camera viewfinder', () {
      final controller = CameraPathController([
        _node(x: 0, zoom: 2.0, offset: Vector2(10, 0), transitionDuration: 0.0),
      ]);
      final camera = CameraComponent();
      final player = _playerAt(0);

      controller.update(1.0, camera, player);

      expect(camera.viewfinder.zoom, 2.0);
      final expectedCenter = player.position + Vector2.all(player.playerSize / 2);
      expect(camera.viewfinder.position, expectedCenter + Vector2(10, 0));
    });
  });
}
