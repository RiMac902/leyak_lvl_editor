/// Режим гравця (аналог модів Geometry Dash: cube/wave/ship/ball/ufo, плюс
/// окремий "sine" для синусоїдного руху — немає robot/spider).
enum PlayerMode { cube, wave, ship, ball, sine, ufo }

/// Розбір значення з [LevelEntity.customProperties]\['modeTrigger'\]
/// (див. `lib/game/level_loader.dart`) — рядкове ім'я enum-значення, або
/// `null`, якщо рядок невідомий/сутність не має цього ключа.
PlayerMode? playerModeFromString(String? value) {
  for (final mode in PlayerMode.values) {
    if (mode.name == value) return mode;
  }
  return null;
}
