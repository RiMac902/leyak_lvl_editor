import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leyak_lvl_editor/game/components/player/player_input.dart';
import 'package:leyak_lvl_editor/game/components/player/player_physics.dart';
import 'package:leyak_lvl_editor/game/components/player/player_state.dart';

const _params = PhysicsParams(
  runSpeedPx: 400.0,
  gravityPx: 1000.0,
  jumpVelocityPx: -500.0,
  groundY: 1000.0,
  playerSize: 50.0,
);

PositionComponent _player({required double x, required double y}) =>
    PositionComponent(position: Vector2(x, y), size: Vector2.all(_params.playerSize));

PositionComponent _block({required double x, required double y, double w = 100, double h = 20}) =>
    PositionComponent(position: Vector2(x, y), size: Vector2(w, h));

void main() {
  group('EarthJumpPhysics', () {
    test('jumps only when on the ground, then integrates gravity and horizontal run', () {
      const physics = EarthJumpPhysics(_params);
      final player = _player(x: 0, y: 450);
      final state = PlayerState()..isOnGround = true;
      final input = PlayerInput()..jumpPressed = true;

      physics.step(0.1, player, state, input);

      expect(state.velocityY, closeTo(-400, 1e-9)); // -500 jump + 1000*0.1 gravity
      expect(state.isOnGround, isFalse);
      expect(player.position.y, closeTo(410, 1e-9)); // 450 + (-400)*0.1
      expect(player.position.x, closeTo(40, 1e-9)); // 400*1.0*0.1
    });

    test('does not jump while airborne even if jumpPressed is true', () {
      const physics = EarthJumpPhysics(_params);
      final player = _player(x: 0, y: 450);
      final state = PlayerState()..isOnGround = false;
      final input = PlayerInput()..jumpPressed = true;

      physics.step(0.0, player, state, input);

      expect(state.velocityY, 0.0);
      expect(state.isOnGround, isFalse);
    });

    test('snaps onto the block top when falling within tolerance', () {
      const physics = EarthJumpPhysics(_params);
      final player = _player(x: 10, y: 450); // bottom = 500
      final block = _block(x: 0, y: 500);
      final state = PlayerState()
        ..velocityY = 50
        ..currentBlock = block;
      final input = PlayerInput();

      physics.step(0.0, player, state, input);

      expect(player.position.y, 450);
      expect(state.velocityY, 0);
      expect(state.isOnGround, isTrue);
    });

    test('releases the block once horizontal overlap is lost', () {
      const physics = EarthJumpPhysics(_params);
      final player = _player(x: 10, y: 450);
      final block = _block(x: 500, y: 500);
      final state = PlayerState()
        ..isOnGround = true
        ..currentBlock = block;
      final input = PlayerInput();

      physics.step(0.0, player, state, input);

      expect(state.currentBlock, isNull);
      expect(state.isOnGround, isFalse);
    });

    test('releases the block once the player falls past the drop tolerance', () {
      const physics = EarthJumpPhysics(_params);
      final player = _player(x: 10, y: 450); // bottom = 500
      final block = _block(x: 0, y: 400); // top = 400, 500 > 400 + 6
      final state = PlayerState()
        ..isOnGround = true
        ..currentBlock = block;
      final input = PlayerInput();

      physics.step(0.0, player, state, input);

      expect(state.currentBlock, isNull);
      expect(state.isOnGround, isFalse);
    });
  });

  group('UfoPhysics', () {
    test('can jump again mid-air, unlike EarthJumpPhysics', () {
      const physics = UfoPhysics(_params);
      final player = _player(x: 0, y: 450);
      final state = PlayerState()..isOnGround = false;
      final input = PlayerInput()..jumpPressed = true;

      physics.step(0.0, player, state, input);

      expect(state.velocityY, -500.0);
      expect(state.isOnGround, isFalse);
    });
  });

  group('WavePhysics', () {
    test('moves diagonally up while jump is held', () {
      const physics = WavePhysics(_params);
      final player = _player(x: 0, y: 100);
      final state = PlayerState()
        ..isOnGround = true
        ..currentBlock = _block(x: 0, y: 0);
      final input = PlayerInput()..jumpHeld = true;

      physics.step(0.1, player, state, input);

      final speed = _params.runSpeedPx;
      expect(player.position.x, closeTo(speed * 0.1, 1e-9));
      expect(player.position.y, closeTo(100 - speed * 0.1, 1e-9));
      expect(state.velocityY, closeTo(-speed, 1e-9));
      expect(state.isOnGround, isFalse);
      expect(state.currentBlock, isNull);
    });

    test('moves diagonally down while jump is released', () {
      const physics = WavePhysics(_params);
      final player = _player(x: 0, y: 100);
      final state = PlayerState();
      final input = PlayerInput()..jumpHeld = false;

      physics.step(0.1, player, state, input);

      final speed = _params.runSpeedPx;
      expect(player.position.y, closeTo(100 + speed * 0.1, 1e-9));
      expect(state.velocityY, closeTo(speed, 1e-9));
    });
  });

  group('ShipPhysics', () {
    test('falls under gravity when jump is not held', () {
      const physics = ShipPhysics(_params);
      final player = _player(x: 0, y: 0);
      final state = PlayerState();
      final input = PlayerInput()..jumpHeld = false;

      physics.step(0.1, player, state, input);

      expect(state.velocityY, closeTo(140, 1e-9)); // 1400 * 0.1
      expect(player.position.y, closeTo(14, 1e-9));
      expect(state.isOnGround, isFalse);
    });

    test('thrust counteracts gravity while jump is held', () {
      const physics = ShipPhysics(_params);
      final player = _player(x: 0, y: 0);
      final state = PlayerState();
      final input = PlayerInput()..jumpHeld = true;

      physics.step(0.1, player, state, input);

      // accel = 1400 - 3200 = -1800; velocityY = -180
      expect(state.velocityY, closeTo(-180, 1e-9));
    });

    test('clamps vertical velocity to maxVelocity', () {
      const physics = ShipPhysics(_params);
      final player = _player(x: 0, y: 0);
      final state = PlayerState()..velocityY = 850;
      final input = PlayerInput()..jumpHeld = false;

      physics.step(1.0, player, state, input);

      expect(state.velocityY, ShipPhysics.maxVelocity);
    });
  });

  group('SinePhysics', () {
    test('advances phase, x position, and y follows the sine curve deterministically', () {
      const physics = SinePhysics(_params);
      final player = _player(x: 0, y: 500);
      final state = PlayerState()..sineBaseY = 500;
      final input = PlayerInput();

      physics.step(0.1, player, state, input);

      final amplitude = _params.playerSize * SinePhysics.amplitudeBlocks;
      final period = _params.playerSize * SinePhysics.periodBlocks;
      final speed = _params.runSpeedPx;
      final omega = speed * (2 * math.pi) / period;
      final expectedPhase = (0 + omega * 0.1) % (2 * math.pi);
      final expectedY = 500 + amplitude * math.sin(expectedPhase);

      // Vector2/PositionComponent store components as 32-bit floats, so
      // only ~1e-4 precision survives the round trip through position.y.
      expect(state.sinePhase, closeTo(expectedPhase, 1e-4));
      expect(player.position.y, closeTo(expectedY, 1e-3));
      expect(player.position.x, closeTo(speed * 0.1, 1e-3));
      expect(state.isOnGround, isFalse);
    });

    test('ignores player input entirely', () {
      const physics = SinePhysics(_params);
      final playerA = _player(x: 0, y: 500);
      final playerB = _player(x: 0, y: 500);
      final stateA = PlayerState()..sineBaseY = 500;
      final stateB = PlayerState()..sineBaseY = 500;

      physics.step(0.1, playerA, stateA, PlayerInput());
      physics.step(0.1, playerB, stateB, PlayerInput()..jumpHeld = true);

      expect(playerA.position.y, playerB.position.y);
    });
  });

  group('BallPhysics', () {
    test('jumping while grounded flips gravitySign instead of launching upward', () {
      const physics = BallPhysics(_params);
      final player = _player(x: 0, y: 450);
      final state = PlayerState()..isOnGround = true;
      final input = PlayerInput()..jumpPressed = true;

      physics.step(0.0, player, state, input);

      expect(state.gravitySign, -1.0);
      expect(state.velocityY, 0);
      expect(state.isOnGround, isFalse);
    });

    test('with normal gravity, snaps onto a block below like EarthJumpPhysics', () {
      const physics = BallPhysics(_params);
      final player = _player(x: 10, y: 450); // bottom = 500
      final block = _block(x: 0, y: 500);
      final state = PlayerState()
        ..gravitySign = 1
        ..velocityY = 50
        ..currentBlock = block;
      final input = PlayerInput();

      physics.step(0.0, player, state, input);

      expect(player.position.y, 450);
      expect(state.velocityY, 0);
      expect(state.isOnGround, isTrue);
    });

    test('with inverted gravity, snaps onto a block above (ceiling contact)', () {
      const physics = BallPhysics(_params);
      final player = _player(x: 10, y: 120); // top = 120
      final block = _block(x: 0, y: 100); // bottom = 120
      final state = PlayerState()
        ..gravitySign = -1
        ..velocityY = -30
        ..currentBlock = block;
      final input = PlayerInput();

      physics.step(0.0, player, state, input);

      expect(player.position.y, 120);
      expect(state.velocityY, 0);
      expect(state.isOnGround, isTrue);
    });
  });
}
