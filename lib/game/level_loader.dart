import 'package:flame/components.dart';
import 'package:leyak_lvl_editor/editor/models/level_entity.dart';
import 'package:leyak_lvl_editor/game/camera/camera_node.dart';
import 'package:leyak_lvl_editor/game/components/finish_line.dart';
import 'package:leyak_lvl_editor/game/components/level_block.dart';
import 'package:leyak_lvl_editor/game/components/mode_trigger.dart';
import 'package:leyak_lvl_editor/game/components/player.dart';
import 'package:leyak_lvl_editor/game/components/speed_trigger.dart';
import 'package:leyak_lvl_editor/game/player_mode.dart';
import 'package:leyak_lvl_editor/game/speed_trigger_type.dart';

/// Результат [buildLevel] — компоненти для додавання у світ гри +
/// прямий доступ до [player] (потрібен [PlaytestGame] для камери й
/// колбеків смерті/перемоги) і [cameraNodes], відсортований шлях камери
/// (може бути порожнім — тоді камера просто лишається на zoom 1.0).
class LoadedLevel {
  LoadedLevel({required this.components, required this.player, required this.cameraNodes});

  final List<Component> components;
  final Player player;
  final List<CameraNode> cameraNodes;
}

/// Перетворює сутності редактора на playtest-компоненти. Завжди додає
/// [Player] (спавниться в точці, розставленій `PlayerSpawnTool`, у
/// cube-моді; якщо дизайнер не поставив маркер — запасний варіант на
/// x=0 висотою [groundY], як і раніше). БЕЗ жодної автоматичної землі —
/// дизайнер рівня сам розставляє підлогу звичайними фігурами з
/// `isSolid` (той самий шлях, що й будь-який інший блок геометрії).
/// Роль кожної [LevelEntity] визначається за `customProperties`:
/// - `isPlayerSpawn == true` → точка спавну (не стає [LevelBlock])
/// - `isCameraNode == true` → вузол [CameraNode] (не стає [LevelBlock])
/// - `modeTrigger` (рядкове ім'я [PlayerMode]) → [ModeTrigger]
/// - `speedTrigger` (рядкове ім'я [SpeedTriggerType]) → [SpeedTrigger]
/// - `isFinish == true` → [FinishLine]
/// - інакше → звичайний [LevelBlock] (`isSolid`/`isDeadly` з тих самих
///   customProperties, які вже редагує Inspector).
LoadedLevel buildLevel(
  List<LevelEntity> entities, {
  required double tileSize,
  required double groundY,
}) {
  final components = <Component>[];
  Vector2? spawnPosition;
  final cameraNodes = <CameraNode>[];

  for (final entity in entities) {
    if (entity.customProperties['isPlayerSpawn'] == true) {
      spawnPosition = entity.transform.position * tileSize;
      continue;
    }

    if (entity.customProperties['isCameraNode'] == true) {
      cameraNodes.add(CameraNode.fromEntity(entity, tileSize));
      continue;
    }

    final mode = playerModeFromString(entity.customProperties['modeTrigger'] as String?);
    if (mode != null) {
      components.add(ModeTrigger(entity, mode, tileSize: tileSize));
      continue;
    }

    final speedType = speedTriggerTypeFromString(
      entity.customProperties['speedTrigger'] as String?,
    );
    if (speedType != null) {
      components.add(SpeedTrigger(entity, speedType, tileSize: tileSize));
      continue;
    }

    if (entity.customProperties['isFinish'] == true) {
      components.add(FinishLine(entity, tileSize: tileSize));
      continue;
    }

    components.add(LevelBlock(entity, tileSize: tileSize));
  }

  cameraNodes.sort((a, b) => a.x.compareTo(b.x));

  final player = Player(
    spawnPosition: spawnPosition ?? Vector2(0, groundY - Player.defaultPlayerSize),
    groundY: groundY,
  );
  components
    ..add(player)
    ..add(player.trail);

  return LoadedLevel(components: components, player: player, cameraNodes: cameraNodes);
}
