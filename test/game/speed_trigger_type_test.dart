import 'package:flutter_test/flutter_test.dart';
import 'package:leyak_lvl_editor/game/speed_trigger_type.dart';

void main() {
  group('SpeedTriggerMultiplier', () {
    test('maps each type to its documented multiplier', () {
      expect(SpeedTriggerType.slow.multiplier, 0.7);
      expect(SpeedTriggerType.normal.multiplier, 1.0);
      expect(SpeedTriggerType.fast15.multiplier, 1.5);
      expect(SpeedTriggerType.fast20.multiplier, 2.0);
      expect(SpeedTriggerType.fast25.multiplier, 2.5);
    });
  });

  group('speedTriggerTypeFromString', () {
    test('parses a valid enum name', () {
      expect(speedTriggerTypeFromString('fast20'), SpeedTriggerType.fast20);
    });

    test('returns null for an unknown string', () {
      expect(speedTriggerTypeFromString('warp'), isNull);
    });

    test('returns null for null input', () {
      expect(speedTriggerTypeFromString(null), isNull);
    });
  });
}
