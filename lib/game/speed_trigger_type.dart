/// Тип speed-тригера — множник горизонтальної швидкості, який він
/// призначає гравцю при перетині (див. `lib/game/components/speed_trigger.dart`).
enum SpeedTriggerType { slow, normal, fast15, fast20, fast25 }

extension SpeedTriggerMultiplier on SpeedTriggerType {
  double get multiplier => switch (this) {
    SpeedTriggerType.slow => 0.7,
    SpeedTriggerType.normal => 1.0,
    SpeedTriggerType.fast15 => 1.5,
    SpeedTriggerType.fast20 => 2.0,
    SpeedTriggerType.fast25 => 2.5,
  };
}

/// Розбір значення з [LevelEntity.customProperties]\['speedTrigger'\].
SpeedTriggerType? speedTriggerTypeFromString(String? value) {
  for (final type in SpeedTriggerType.values) {
    if (type.name == value) return type;
  }
  return null;
}
