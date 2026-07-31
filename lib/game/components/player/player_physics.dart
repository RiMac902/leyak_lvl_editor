import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:leyak_lvl_editor/game/components/player/player_input.dart';
import 'package:leyak_lvl_editor/game/components/player/player_state.dart';

/// Незмінний набір параметрів, спільний для всіх [PlayerPhysics] — той
/// самий екземпляр передається у всі 6 реалізацій з конструктора Player.
/// [player]/[block] у цьому файлі вважаються top-left-заякореними
/// (`position` = верхній лівий кут, `size` = ширина/висота) — так само,
/// як типово в Flame за замовчуванням.
class PhysicsParams {
  const PhysicsParams({
    required this.runSpeedPx,
    required this.gravityPx,
    required this.jumpVelocityPx,
    required this.groundY,
    required this.playerSize,
  });

  final double runSpeedPx;
  final double gravityPx;
  final double jumpVelocityPx;

  /// НЕ колізійна межа — рушій не має вбудованої землі (її розставляє сам
  /// дизайнер рівня звичайними [LevelBlock]-ами з `isSolid`). Лишається
  /// лише як орієнтир висоти старту гравця ([Player.onLoad]) і для
  /// клампу [SinePhysics].
  final double groundY;
  final double playerSize;
}

/// Патерн "стратегія" — по одному класу на [PlayerMode]. Кожен [step]
/// рухає `player.position` напряму (позиція не зберігається в
/// [PlayerState]) на основі поточних [state]/[input].
abstract class PlayerPhysics {
  const PlayerPhysics();

  void step(double dt, PositionComponent player, PlayerState state, PlayerInput input);
}

const double _snapTolerance = 4.0;
const double _dropTolerance = 6.0;

bool _overlapsX(PositionComponent player, double playerSize, PositionComponent block) {
  final playerLeft = player.position.x;
  final playerRight = playerLeft + playerSize;
  final blockLeft = block.position.x;
  final blockRight = blockLeft + block.size.x;
  return playerLeft < blockRight && playerRight > blockLeft;
}

/// Спільна для cube/ufo (і "падаючої" гілки ball) логіка "прилипання" до
/// верху [state.currentBlock]: відліплюється, коли зникає горизонтальний
/// перекрив (`_overlapsX`) чи падіння перевищує [_dropTolerance] нижче
/// блоку; прилипає точно до поверхні в межах [_snapTolerance], щоб не було
/// мерехтіння між "на блоці"/"у польоті". НЕМАЄ жодного автоматичного
/// "дна" — якщо [state.currentBlock] немає, гравець просто продовжує
/// падати: земля/платформи — звичайні [LevelBlock] з `isSolid`, які
/// розставляє сам дизайнер рівня, а не щось вбудоване в рушій.
void _resolveGroundedContact(PositionComponent player, PlayerState state, PhysicsParams params) {
  final block = state.currentBlock;
  if (block == null) return;

  if (!_overlapsX(player, params.playerSize, block)) {
    state.currentBlock = null;
    state.isOnGround = false;
    return;
  }

  final blockTop = block.position.y;
  final playerBottom = player.position.y + params.playerSize;
  if (state.velocityY >= 0 && (playerBottom - blockTop).abs() <= _snapTolerance) {
    player.position.y = blockTop - params.playerSize;
    state.velocityY = 0;
    state.isOnGround = true;
  } else if (playerBottom > blockTop + _dropTolerance) {
    state.currentBlock = null;
    state.isOnGround = false;
  }
}

/// Cube: класичний "стрибучий куб" — стрибок лише із землі/блоку
/// (`isOnGround`), напів-неявна інтеграція гравітації.
class EarthJumpPhysics extends PlayerPhysics {
  const EarthJumpPhysics(this.params);

  final PhysicsParams params;

  @override
  void step(double dt, PositionComponent player, PlayerState state, PlayerInput input) {
    if (input.jumpPressed && state.isOnGround) {
      state.velocityY = params.jumpVelocityPx;
      state.isOnGround = false;
    }

    state.velocityY += params.gravityPx * dt;
    player.position.y += state.velocityY * dt;

    _resolveGroundedContact(player, state, params);

    player.position.x += params.runSpeedPx * state.speedMultiplier * dt;
  }
}

/// Wave: пряма діагональна "пилка" — без гравітації й без інтеграції
/// прискорення. Утримання клавіші = вгору, відпускання = вниз. Завжди в
/// повітрі; [velocityY] тут лише для відображення нахилу (не інтегрується).
class WavePhysics extends PlayerPhysics {
  const WavePhysics(this.params);

  final PhysicsParams params;

  @override
  void step(double dt, PositionComponent player, PlayerState state, PlayerInput input) {
    final speed = params.runSpeedPx * state.speedMultiplier;
    final direction = input.jumpHeld ? -1.0 : 1.0;

    player.position.x += speed * dt;
    player.position.y += speed * direction * dt;

    state.velocityY = speed * direction;
    state.isOnGround = false;
    state.currentBlock = null;
  }
}

/// Ship: "флаппі"-керування — гравітація постійно вниз, утримання клавіші
/// додає протитягу вгору. Ніколи не торкається землі (гине при будь-якому
/// зіткненні з блоком/землею — обробляється в Player, не тут).
class ShipPhysics extends PlayerPhysics {
  const ShipPhysics(this.params);

  final PhysicsParams params;

  static const double gravity = 1400.0;
  static const double thrust = 3200.0;
  static const double maxVelocity = 900.0;
  static const double maxAngle = 0.6;

  @override
  void step(double dt, PositionComponent player, PlayerState state, PlayerInput input) {
    final accel = gravity - (input.jumpHeld ? thrust : 0.0);
    state.velocityY = (state.velocityY + accel * dt).clamp(-maxVelocity, maxVelocity);
    player.position.y += state.velocityY * dt;
    player.position.x += params.runSpeedPx * state.speedMultiplier * dt;

    state.isOnGround = false;
    state.currentBlock = null;
  }
}

/// UFO: структурно ідентичний [EarthJumpPhysics], окрім умови стрибка —
/// немає вимоги `isOnGround`, тож можна "плескати крилами" повторно в
/// повітрі на кожен тап (мульти-стрибок).
class UfoPhysics extends PlayerPhysics {
  const UfoPhysics(this.params);

  final PhysicsParams params;

  @override
  void step(double dt, PositionComponent player, PlayerState state, PlayerInput input) {
    if (input.jumpPressed) {
      state.velocityY = params.jumpVelocityPx;
      state.isOnGround = false;
    }

    state.velocityY += params.gravityPx * dt;
    player.position.y += state.velocityY * dt;

    _resolveGroundedContact(player, state, params);

    player.position.x += params.runSpeedPx * state.speedMultiplier * dt;
  }
}

/// Sine: детермінована синусоїда — позиція присвоюється напряму (не
/// інтегрується зі швидкості), просторовий період лишається сталим
/// незалежно від множника швидкості (omega рахується з поточної
/// швидкості). Повністю ігнорує ввід; завжди в повітрі.
class SinePhysics extends PlayerPhysics {
  const SinePhysics(this.params);

  final PhysicsParams params;

  static const double amplitudeBlocks = 1.5;
  static const double periodBlocks = 4.0;

  @override
  void step(double dt, PositionComponent player, PlayerState state, PlayerInput input) {
    final amplitude = params.playerSize * amplitudeBlocks;
    final period = params.playerSize * periodBlocks;
    final speed = params.runSpeedPx * state.speedMultiplier;
    final omega = speed * (2 * math.pi) / period;

    state.sinePhase = (state.sinePhase + omega * dt) % (2 * math.pi);

    // groundY - playerSize - amplitude (не лише groundY - amplitude, як у
    // джерелі): тут player.position.y — верхній край гравця (top-left
    // якір), тож треба враховувати і playerSize, інакше пік хвилі міг би
    // штовхнути НИЗ гравця під землю.
    final clampedBase = math.min(
      state.sineBaseY,
      params.groundY - params.playerSize - amplitude,
    );
    player.position.y = clampedBase + amplitude * math.sin(state.sinePhase);
    state.velocityY = amplitude * omega * math.cos(state.sinePhase);

    player.position.x += speed * dt;
    state.isOnGround = false;
    state.currentBlock = null;
  }
}

/// Ball: натискання не стрибає, а інвертує гравітацію ([gravitySign]).
/// Колізія з блоком розгалужується за знаком: падіння — верх блоку є
/// підлогою, інвертована гравітація — низ блоку є стелею. Без блоку під
/// (чи над) гравцем — просто падає далі, як і cube/ufo.
class BallPhysics extends PlayerPhysics {
  const BallPhysics(this.params);

  final PhysicsParams params;

  @override
  void step(double dt, PositionComponent player, PlayerState state, PlayerInput input) {
    if (input.jumpPressed && state.isOnGround) {
      state.gravitySign *= -1.0;
      state.velocityY = 0;
      state.isOnGround = false;
      state.currentBlock = null;
    }

    state.velocityY += params.gravityPx * state.gravitySign * dt;
    player.position.y += state.velocityY * dt;

    final block = state.currentBlock;
    if (block != null) {
      if (!_overlapsX(player, params.playerSize, block)) {
        state.currentBlock = null;
        state.isOnGround = false;
      } else if (state.gravitySign > 0) {
        final blockTop = block.position.y;
        final playerBottom = player.position.y + params.playerSize;
        if (state.velocityY >= 0 && (playerBottom - blockTop).abs() <= _snapTolerance) {
          player.position.y = blockTop - params.playerSize;
          state.velocityY = 0;
          state.isOnGround = true;
        } else if (playerBottom > blockTop + _dropTolerance) {
          state.currentBlock = null;
          state.isOnGround = false;
        }
      } else {
        final blockBottom = block.position.y + block.size.y;
        final playerTop = player.position.y;
        if (state.velocityY <= 0 && (playerTop - blockBottom).abs() <= _snapTolerance) {
          player.position.y = blockBottom;
          state.velocityY = 0;
          state.isOnGround = true;
        } else if (playerTop < blockBottom - _dropTolerance) {
          state.currentBlock = null;
          state.isOnGround = false;
        }
      }
    }

    player.position.x += params.runSpeedPx * state.speedMultiplier * dt;
  }
}
