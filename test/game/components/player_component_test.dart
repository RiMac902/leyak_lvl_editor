import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leyak_lvl_editor/game/components/finish_line.dart';
import 'package:leyak_lvl_editor/game/components/level_block.dart';
import 'package:leyak_lvl_editor/game/components/player.dart';
import 'package:leyak_lvl_editor/editor/models/level_entity.dart';
import 'package:leyak_lvl_editor/game/player_mode.dart';

KeyDownEvent _mDown() => const KeyDownEvent(
  physicalKey: PhysicalKeyboardKey.keyM,
  logicalKey: LogicalKeyboardKey.keyM,
  timeStamp: Duration.zero,
);

LevelBlock _blockAt(double x, double y, {double w = 100, double h = 20, bool isSolid = false, bool isDeadly = false}) {
  final block = LevelBlock(
    LevelEntity(
      id: 'b',
      customProperties: {'isSolid': isSolid, 'isDeadly': isDeadly},
    ),
    tileSize: 1.0,
  );
  block.position.setValues(x, y);
  block.size.setValues(w, h);
  return block;
}

FinishLine _finishAt(double x, double y) {
  final finish = FinishLine(LevelEntity(id: 'f'), tileSize: 1.0);
  finish.position.setValues(x, y);
  finish.size.setValues(50, 50);
  return finish;
}

void main() {
  group('Player mode cycling (M key)', () {
    testWithFlameGame('cycles cube -> wave -> ship -> ball -> sine -> ufo -> cube', (game) async {
      final player = Player(spawnPosition: Vector2.zero(), groundY: 500);
      await game.ensureAdd(player);

      const expectedOrder = [
        PlayerMode.wave,
        PlayerMode.ship,
        PlayerMode.ball,
        PlayerMode.sine,
        PlayerMode.ufo,
        PlayerMode.cube,
      ];

      expect(player.state.mode, PlayerMode.cube);
      for (final expectedMode in expectedOrder) {
        player.onKeyEvent(_mDown(), {});
        expect(player.state.mode, expectedMode);
      }
    });

    testWithFlameGame('switching away from cube clears ground/velocity state', (game) async {
      final player = Player(spawnPosition: Vector2.zero(), groundY: 500);
      await game.ensureAdd(player);
      player.state
        ..isOnGround = true
        ..velocityY = 42
        ..currentBlock = _blockAt(0, 0);

      player.setMode(PlayerMode.wave);

      expect(player.state.isOnGround, isFalse);
      expect(player.state.velocityY, 0.0);
      expect(player.state.currentBlock, isNull);
    });

    testWithFlameGame('switching to ball resets gravitySign to normal', (game) async {
      final player = Player(spawnPosition: Vector2.zero(), groundY: 500);
      await game.ensureAdd(player);
      player.state.gravitySign = -1.0;

      player.setMode(PlayerMode.ball);

      expect(player.state.gravitySign, 1.0);
    });

    testWithFlameGame('switching to sine anchors sineBaseY to the current position', (game) async {
      final player = Player(spawnPosition: Vector2(0, 123), groundY: 500);
      await game.ensureAdd(player);

      player.setMode(PlayerMode.sine);

      expect(player.state.sineBaseY, player.position.y);
      expect(player.state.sinePhase, 0.0);
    });
  });

  group('Player.onCollisionStart', () {
    testWithFlameGame('a deadly block kills the player and fires onDied', (game) async {
      final player = Player(spawnPosition: Vector2.zero(), groundY: 500);
      await game.ensureAdd(player);
      var died = false;
      player.onDied = () => died = true;

      player.onCollisionStart({}, _blockAt(0, 0, isDeadly: true));

      expect(player.isDead, isTrue);
      expect(died, isTrue);
    });

    testWithFlameGame('a finish line wins the game and fires onWon', (game) async {
      final player = Player(spawnPosition: Vector2.zero(), groundY: 500);
      await game.ensureAdd(player);
      var won = false;
      player.onWon = () => won = true;

      player.onCollisionStart({}, _finishAt(0, 0));

      expect(player.isWon, isTrue);
      expect(won, isTrue);
    });

    testWithFlameGame('cube landing on top of a solid block from above is safe', (game) async {
      final player = Player(spawnPosition: Vector2(0, 0), groundY: 500, playerSize: 32);
      await game.ensureAdd(player);
      // Simulate last frame being fully above the block, falling.
      player.position.setValues(0, 68);
      player.update(0.0); // captures _prevPosition = (0, 68)
      player.position.setValues(0, 70);
      player.state.velocityY = 50;
      final block = _blockAt(0, 100, w: 200, h: 20, isSolid: true);

      player.onCollisionStart({}, block);

      expect(player.isDead, isFalse);
      expect(player.state.isOnGround, isTrue);
      expect(player.state.currentBlock, block);
      expect(player.position.y, 100 - 32);
      expect(player.state.velocityY, 0);
    });

    testWithFlameGame('cube hitting a solid block from the side dies', (game) async {
      final player = Player(spawnPosition: Vector2(90, 100), groundY: 500, playerSize: 32);
      await game.ensureAdd(player);
      player.update(0.0); // _prevPosition = (90, 100), overlapping the block's Y range already
      player.position.setValues(95, 100);
      final block = _blockAt(100, 90, w: 200, h: 60, isSolid: true);
      var died = false;
      player.onDied = () => died = true;

      player.onCollisionStart({}, block);

      expect(player.isDead, isTrue);
      expect(died, isTrue);
    });

    for (final mode in [PlayerMode.wave, PlayerMode.ship, PlayerMode.sine]) {
      testWithFlameGame('$mode always dies on a solid block, even landing cleanly from above', (game) async {
        final player = Player(spawnPosition: Vector2(0, 0), groundY: 500, playerSize: 32);
        await game.ensureAdd(player);
        player.setMode(mode);
        player.position.setValues(0, 68);
        player.update(0.0);
        player.position.setValues(0, 70);
        final block = _blockAt(0, 100, w: 200, h: 20, isSolid: true);

        player.onCollisionStart({}, block);

        expect(player.isDead, isTrue);
      });
    }

    group('ball mode', () {
      testWithFlameGame('normal gravity: lands on top of a solid block like cube', (game) async {
        final player = Player(spawnPosition: Vector2(0, 0), groundY: 500, playerSize: 32);
        await game.ensureAdd(player);
        player.setMode(PlayerMode.ball);
        player.position.setValues(0, 68);
        player.update(0.0);
        player.position.setValues(0, 70);
        player.state.velocityY = 50;
        final block = _blockAt(0, 100, w: 200, h: 20, isSolid: true);

        player.onCollisionStart({}, block);

        expect(player.isDead, isFalse);
        expect(player.state.isOnGround, isTrue);
        expect(player.position.y, 100 - 32);
      });

      testWithFlameGame('inverted gravity: lands on the underside of a block above (ceiling)', (game) async {
        final player = Player(spawnPosition: Vector2(0, 100), groundY: 500, playerSize: 32);
        await game.ensureAdd(player);
        player.setMode(PlayerMode.ball);
        player.state.gravitySign = -1.0;
        player.position.setValues(0, 100);
        player.update(0.0); // _prevPosition = (0, 100), below the block
        player.position.setValues(0, 98);
        player.state.velocityY = -50;
        final block = _blockAt(0, 50, w: 200, h: 20, isSolid: true); // bottom = 70... adjust below

        player.onCollisionStart({}, block);

        expect(player.isDead, isFalse);
        expect(player.state.isOnGround, isTrue);
        expect(player.position.y, 70); // snapped to blockBottom
      });

      testWithFlameGame('inverted gravity: hitting the block from the side dies', (game) async {
        final player = Player(spawnPosition: Vector2(90, 40), groundY: 500, playerSize: 32);
        await game.ensureAdd(player);
        player.setMode(PlayerMode.ball);
        player.state.gravitySign = -1.0;
        player.update(0.0); // _prevPosition = (90, 40), overlapping Y already
        player.position.setValues(95, 40);
        final block = _blockAt(100, 30, w: 200, h: 60, isSolid: true);

        player.onCollisionStart({}, block);

        expect(player.isDead, isTrue);
      });
    });

    testWithFlameGame('collisions are ignored once the player is already dead', (game) async {
      final player = Player(spawnPosition: Vector2.zero(), groundY: 500);
      await game.ensureAdd(player);
      player.onCollisionStart({}, _blockAt(0, 0, isDeadly: true));
      expect(player.isDead, isTrue);
      var diedAgain = false;
      player.onDied = () => diedAgain = true;

      player.onCollisionStart({}, _finishAt(0, 0));

      expect(player.isWon, isFalse);
      expect(diedAgain, isFalse);
    });
  });

  group('PlayerMode coverage', () {
    // _physicsFor/_skinFor in player.dart are exhaustive switches (no
    // `default`), so a new PlayerMode value already fails to COMPILE
    // until both are updated. This test is the runtime backstop: it
    // exercises setMode -> update -> render for every value, so a
    // case that compiles but is wired to the wrong behavior (or throws
    // when actually used) still gets caught.
    testWithFlameGame('every PlayerMode sets, steps, and renders without throwing', (game) async {
      final player = Player(spawnPosition: Vector2.zero(), groundY: 500);
      await game.ensureAdd(player);

      for (final mode in PlayerMode.values) {
        player.setMode(mode);
        expect(player.state.mode, mode, reason: 'setMode did not apply $mode');
        expect(() => player.update(1 / 60), returnsNormally, reason: '$mode threw during update');

        final canvas = Canvas(PictureRecorder());
        expect(() => player.render(canvas), returnsNormally, reason: '$mode threw during render');
      }
    });
  });
}
