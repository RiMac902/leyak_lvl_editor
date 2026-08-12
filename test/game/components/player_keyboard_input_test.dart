import 'package:flame/components.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leyak_lvl_editor/game/components/player.dart';

KeyDownEvent _spaceDown() => const KeyDownEvent(
  physicalKey: PhysicalKeyboardKey.space,
  logicalKey: LogicalKeyboardKey.space,
  timeStamp: Duration.zero,
);

KeyUpEvent _spaceUp() => const KeyUpEvent(
  physicalKey: PhysicalKeyboardKey.space,
  logicalKey: LogicalKeyboardKey.space,
  timeStamp: Duration.zero,
);

Player _player() => Player(spawnPosition: Vector2.zero(), groundY: 500);

void main() {
  group('onKeyEvent - space (jump)', () {
    test('space down sets both jumpPressed and jumpHeld, and is handled', () {
      final player = _player();

      final handled = player.onKeyEvent(_spaceDown(), {});

      expect(handled, isTrue);
      expect(player.input.jumpPressed, isTrue);
      expect(player.input.jumpHeld, isTrue);
    });

    test('space up clears jumpHeld and is handled', () {
      final player = _player();
      player.onKeyEvent(_spaceDown(), {});

      final handled = player.onKeyEvent(_spaceUp(), {});

      expect(handled, isTrue);
      expect(player.input.jumpHeld, isFalse);
    });

    test('holding space (repeated key down) does not re-set jumpPressed once already held', () {
      final player = _player();
      player.onKeyEvent(_spaceDown(), {});
      player.input.jumpPressed = false; // simulate Player.update() clearing per-frame input

      player.onKeyEvent(_spaceDown(), {});

      expect(player.input.jumpPressed, isFalse);
      expect(player.input.jumpHeld, isTrue);
    });

    test('an unrelated key is not handled', () {
      final player = _player();

      final handled = player.onKeyEvent(
        const KeyDownEvent(
          physicalKey: PhysicalKeyboardKey.keyA,
          logicalKey: LogicalKeyboardKey.keyA,
          timeStamp: Duration.zero,
        ),
        {},
      );

      expect(handled, isFalse);
      expect(player.input.jumpPressed, isFalse);
    });
  });
}
