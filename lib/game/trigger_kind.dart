import 'package:leyak_lvl_editor/editor/models/level_entity.dart';
import 'package:leyak_lvl_editor/game/player_mode.dart';
import 'package:leyak_lvl_editor/game/speed_trigger_type.dart';

/// Роль однієї [LevelEntity] у playtest-рантаймі — визначає, у який
/// компонент вона перетвориться в [buildLevel]. [classifyEntity] — єдине
/// місце, що знає про відповідні поля [LevelEntity.customProperties];
/// [buildLevel] далі веде exhaustive `switch` над цим enum замість
/// ланцюжка `if` над рядковими ключами — новий варіант ролі не
/// скомпілюється, поки не додано відповідний `case`, тоді як забутий
/// `if` у ланцюжку компілятор пропустив би мовчки.
enum TriggerKind { playerSpawn, cameraNode, modeTrigger, speedTrigger, finish, block }

TriggerKind classifyEntity(LevelEntity entity) {
  final props = entity.customProperties;

  if (props['isPlayerSpawn'] == true) return TriggerKind.playerSpawn;
  if (props['isCameraNode'] == true) return TriggerKind.cameraNode;
  if (playerModeFromString(props['modeTrigger'] as String?) != null) {
    return TriggerKind.modeTrigger;
  }
  if (speedTriggerTypeFromString(props['speedTrigger'] as String?) != null) {
    return TriggerKind.speedTrigger;
  }
  if (props['isFinish'] == true) return TriggerKind.finish;
  return TriggerKind.block;
}
