import 'package:flutter_test/flutter_test.dart';
import 'package:leyak_lvl_editor/game/player_mode.dart';

void main() {
  group('playerModeFromString', () {
    test('parses every valid enum name', () {
      for (final mode in PlayerMode.values) {
        expect(playerModeFromString(mode.name), mode);
      }
    });

    test('returns null for an unknown string', () {
      expect(playerModeFromString('robot'), isNull);
    });

    test('returns null for null input', () {
      expect(playerModeFromString(null), isNull);
    });
  });
}
