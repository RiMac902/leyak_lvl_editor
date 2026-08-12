import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leyak_lvl_editor/editor/models/level_entity.dart';
import 'package:leyak_lvl_editor/editor/models/transform_data.dart';
import 'package:leyak_lvl_editor/game/components/finish_line.dart';
import 'package:leyak_lvl_editor/game/components/level_block.dart';
import 'package:leyak_lvl_editor/game/components/mode_trigger.dart';
import 'package:leyak_lvl_editor/game/components/player.dart';
import 'package:leyak_lvl_editor/game/components/speed_trigger.dart';
import 'package:leyak_lvl_editor/game/level_loader.dart';
import 'package:leyak_lvl_editor/game/player_mode.dart';
import 'package:leyak_lvl_editor/game/speed_trigger_type.dart';

LevelEntity _entity({
  String id = 'e',
  Vector2? position,
  Map<String, dynamic>? customProperties,
}) {
  return LevelEntity(
    id: id,
    transform: TransformData(position: position ?? Vector2.zero(), size: Vector2(1, 1)),
    customProperties: customProperties,
  );
}

void main() {
  group('buildLevel player spawn', () {
    test('uses the marked spawn entity position, scaled by tileSize, and excludes it from components', () {
      final spawn = _entity(position: Vector2(3, 4), customProperties: {'isPlayerSpawn': true});

      final level = buildLevel([spawn], tileSize: 10.0, groundY: 500);

      expect(level.player.spawnPosition, Vector2(30, 40));
      expect(level.components.whereType<LevelBlock>(), isEmpty);
    });

    test('falls back to a default spawn above groundY when no spawn marker exists', () {
      final level = buildLevel([], tileSize: 10.0, groundY: 500);

      expect(level.player.spawnPosition, Vector2(0, 500 - Player.defaultPlayerSize));
    });

    test('always adds exactly one player and its trail to components', () {
      final level = buildLevel([_entity()], tileSize: 10.0, groundY: 500);

      expect(level.components.whereType<Player>().length, 1);
      expect(identical(level.components.whereType<Player>().single, level.player), isTrue);
    });
  });

  group('buildLevel camera nodes', () {
    test('collects camera-node entities separately from components, sorted by x', () {
      final nodeB = _entity(
        id: 'b',
        position: Vector2(5, 0),
        customProperties: {'isCameraNode': true},
      );
      final nodeA = _entity(
        id: 'a',
        position: Vector2(1, 0),
        customProperties: {'isCameraNode': true},
      );

      final level = buildLevel([nodeB, nodeA], tileSize: 10.0, groundY: 500);

      expect(level.cameraNodes.map((n) => n.x), [10.0, 50.0]);
      expect(level.components.length, 2); // player + trail only
    });
  });

  group('buildLevel entity classification', () {
    test('a modeTrigger entity becomes a ModeTrigger with the parsed mode', () {
      final entity = _entity(customProperties: {'modeTrigger': 'wave'});

      final level = buildLevel([entity], tileSize: 10.0, groundY: 500);

      final trigger = level.components.whereType<ModeTrigger>().single;
      expect(trigger.mode, PlayerMode.wave);
    });

    test('a speedTrigger entity becomes a SpeedTrigger with the parsed type', () {
      final entity = _entity(customProperties: {'speedTrigger': 'fast20'});

      final level = buildLevel([entity], tileSize: 10.0, groundY: 500);

      final trigger = level.components.whereType<SpeedTrigger>().single;
      expect(trigger.type, SpeedTriggerType.fast20);
    });

    test('an isFinish entity becomes a FinishLine', () {
      final entity = _entity(customProperties: {'isFinish': true});

      final level = buildLevel([entity], tileSize: 10.0, groundY: 500);

      expect(level.components.whereType<FinishLine>().length, 1);
    });

    test('a plain entity becomes a LevelBlock', () {
      final entity = _entity();

      final level = buildLevel([entity], tileSize: 10.0, groundY: 500);

      expect(level.components.whereType<LevelBlock>().length, 1);
    });

    test('an unrecognized modeTrigger/speedTrigger string falls through to LevelBlock', () {
      final entity = _entity(customProperties: {'modeTrigger': 'not_a_real_mode'});

      final level = buildLevel([entity], tileSize: 10.0, groundY: 500);

      expect(level.components.whereType<LevelBlock>().length, 1);
      expect(level.components.whereType<ModeTrigger>(), isEmpty);
    });

    test('classifies a mixed batch of entities correctly and preserves entity identity', () {
      final spawn = _entity(id: 'spawn', customProperties: {'isPlayerSpawn': true});
      final camera = _entity(id: 'camera', customProperties: {'isCameraNode': true});
      final mode = _entity(id: 'mode', customProperties: {'modeTrigger': 'ship'});
      final speed = _entity(id: 'speed', customProperties: {'speedTrigger': 'slow'});
      final finish = _entity(id: 'finish', customProperties: {'isFinish': true});
      final block = _entity(id: 'block');

      final level = buildLevel(
        [spawn, camera, mode, speed, finish, block],
        tileSize: 10.0,
        groundY: 500,
      );

      expect(level.cameraNodes, hasLength(1));
      expect(level.components.whereType<ModeTrigger>().single.entity.id, 'mode');
      expect(level.components.whereType<SpeedTrigger>().single.entity.id, 'speed');
      expect(level.components.whereType<FinishLine>().single.entity.id, 'finish');
      expect(level.components.whereType<LevelBlock>().single.entity.id, 'block');
      // player + trail + mode + speed + finish + block = 6
      expect(level.components, hasLength(6));
    });
  });
}
