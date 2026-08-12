import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/services.dart';
import 'package:leyak_lvl_editor/game/components/finish_line.dart';
import 'package:leyak_lvl_editor/game/components/level_block.dart';
import 'package:leyak_lvl_editor/game/components/player/player_input.dart';
import 'package:leyak_lvl_editor/game/components/player/player_particle.dart';
import 'package:leyak_lvl_editor/game/components/player/player_physics.dart';
import 'package:leyak_lvl_editor/game/components/player/player_skin.dart';
import 'package:leyak_lvl_editor/game/components/player/player_state.dart';
import 'package:leyak_lvl_editor/game/components/player/player_trail.dart';
import 'package:leyak_lvl_editor/game/game_constants.dart';
import 'package:leyak_lvl_editor/game/player_mode.dart';

/// Гравець — "оркестратор": володіє [state]/[input], перемикає між 6
/// парами фізика+скін+хітбокс за [PlayerMode], веде щокадровий update,
/// відповідає на колізії, смерть/перемогу. Порт 1:1 з довідкового проєкту
/// "Geo Game" (див. план), адаптований під дані цього редактора.
///
/// [angle] цього компонента НІКОЛИ не чіпається — обертання скіна ([state.
/// rotationAngle]) суто візуальне (канвас-трансформ у [render]), а не
/// трансформ компонента, інакше воно б крутило й хітбокси. Єдиний виняток
/// — ship: там кут явно застосовується і до скіна (через [render]), і до
/// [_shipHitbox] окремо (`_shipHitbox.angle`), як і в довідковому проєкті.
class Player extends PositionComponent with CollisionCallbacks, KeyboardHandler {
  Player({required this.spawnPosition, required this.groundY, this.playerSize = 32.0})
    : super(anchor: Anchor.topLeft);

  static const double defaultPlayerSize = 32.0;

  /// Точка спавну (пікселі), розміщена дизайнером через `PlayerSpawnTool`
  /// у редакторі; якщо на рівні немає маркера — [buildLevel] підставляє
  /// запасний варіант на основі [groundY].
  final Vector2 spawnPosition;

  /// Орієнтир для клампу [SinePhysics] — НЕ колізійна межа. Реальна
  /// підлога — звичайні [LevelBlock] з `isSolid`, розставлені дизайнером
  /// рівня; якщо під точкою спавну нічого немає, гравець одразу почне
  /// падати.
  final double groundY;
  final double playerSize;

  final PlayerState state = PlayerState();
  final PlayerInput input = PlayerInput();

  void Function()? onDied;
  void Function()? onWon;

  late final PlayerTrail trail = PlayerTrail(sampleTarget: this);

  late final PhysicsParams _params;
  PlayerPhysics? _physics;
  PlayerSkin? _activeSkin;

  late final RectangleHitbox _cubeHitbox;
  late final PolygonHitbox _waveHitbox;
  late final PolygonHitbox _shipHitbox;
  late final CircleHitbox _ballHitbox;

  Vector2 _prevPosition = Vector2.zero();
  double _sparkTimer = 0;

  static const double jumpDistanceBlocks = 4.0;
  static const double jumpHeightBlocks = 3.0;
  static const double _collisionTolerance = 4.0;
  static const double _sparkInterval = 0.05;

  static const List<PlayerMode> _debugCycle = [
    PlayerMode.cube,
    PlayerMode.wave,
    PlayerMode.ship,
    PlayerMode.ball,
    PlayerMode.sine,
    PlayerMode.ufo,
  ];

  bool get isDead => state.isDead;
  bool get isWon => state.isWon;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    size = Vector2.all(playerSize);
    position = spawnPosition.clone();
    _prevPosition = position.clone();

    // gravity = 8H/T², jumpVelocity = -4H/T (кінематика параболічного
    // стрибка, точні формули з довідкового проєкту) — з GameConstants,
    // узгодженими з tileSize редактора (див. game_constants.dart).
    final jumpTotalTime = (jumpDistanceBlocks * GameConstants.gridSize) / GameConstants.gameSpeed;
    final jumpHeightPx = GameConstants.gridSize * jumpHeightBlocks;
    final gravity = 8 * jumpHeightPx / (jumpTotalTime * jumpTotalTime);
    final jumpVelocity = -4 * jumpHeightPx / jumpTotalTime;

    _params = PhysicsParams(
      runSpeedPx: GameConstants.gameSpeed,
      gravityPx: gravity,
      jumpVelocityPx: jumpVelocity,
      groundY: groundY,
      playerSize: playerSize,
    );

    _cubeHitbox = RectangleHitbox();
    _waveHitbox = PolygonHitbox([
      Vector2(0, 0),
      Vector2(playerSize, playerSize / 2),
      Vector2(0, playerSize),
    ]);
    _shipHitbox = PolygonHitbox([
      Vector2(playerSize * 0.1, 0),
      Vector2(playerSize * 0.9, 0),
      Vector2(playerSize, playerSize / 2),
      Vector2(playerSize * 0.9, playerSize),
      Vector2(playerSize * 0.1, playerSize),
      Vector2(0, playerSize / 2),
    ], anchor: Anchor.center, position: Vector2.all(playerSize / 2));
    _ballHitbox = CircleHitbox();

    _physics = _physicsFor(PlayerMode.cube);
    _applyModeVisuals(PlayerMode.cube);
  }

  /// Exhaustive `switch` (без `default`) замість `Map<PlayerMode, ...>` —
  /// новий [PlayerMode] не скомпілюється, поки тут не додано відповідний
  /// case, на відміну від Map-літерала, що мовчки повернув би `null`.
  PlayerPhysics _physicsFor(PlayerMode mode) => switch (mode) {
    PlayerMode.cube => EarthJumpPhysics(_params),
    PlayerMode.wave => WavePhysics(_params),
    PlayerMode.ship => ShipPhysics(_params),
    PlayerMode.ball => BallPhysics(_params),
    PlayerMode.sine => SinePhysics(_params),
    PlayerMode.ufo => UfoPhysics(_params),
  };

  PlayerSkin _skinFor(PlayerMode mode) => switch (mode) {
    PlayerMode.cube => const CubeSkin(),
    PlayerMode.wave => const WaveSkin(),
    PlayerMode.ship => const ShipSkin(),
    PlayerMode.ball => const BallSkin(),
    PlayerMode.sine => const SineSkin(),
    PlayerMode.ufo => const UfoSkin(),
  };

  void _setMode(PlayerMode mode) {
    state.mode = mode;
    _physics = _physicsFor(mode);
    _applyModeVisuals(mode);
    state.rotationAngle = 0.0;

    // "Повітряні" моди (усе, крім cube) завжди стартують у польоті — щоб
    // не успадкувати isOnGround/currentBlock від попереднього мода.
    if (mode != PlayerMode.cube) {
      state.isOnGround = false;
      state.currentBlock = null;
      state.velocityY = 0.0;
    }
    if (mode == PlayerMode.ball) {
      state.gravitySign = 1.0;
    }
    if (mode == PlayerMode.sine) {
      state.sineBaseY = position.y;
      state.sinePhase = 0.0;
    }
  }

  /// Публічна обгортка — викликається [ModeTrigger] чи дебаг-читкодом.
  void setMode(PlayerMode mode) => _setMode(mode);

  void setSpeedMultiplier(double value) {
    state.speedMultiplier = value.clamp(0.1, 3.0);
  }

  void _applyModeVisuals(PlayerMode mode) {
    _activeSkin = _skinFor(mode);
    _updateHitboxes(mode);
    trail.enabled = mode == PlayerMode.wave || mode == PlayerMode.ship;
  }

  void _updateHitboxes(PlayerMode mode) {
    for (final hitbox in [_cubeHitbox, _waveHitbox, _shipHitbox, _ballHitbox]) {
      if (hitbox.isMounted) hitbox.removeFromParent();
    }
    switch (mode) {
      case PlayerMode.cube:
      case PlayerMode.sine:
      case PlayerMode.ufo:
        add(_cubeHitbox);
      case PlayerMode.wave:
        add(_waveHitbox);
      case PlayerMode.ship:
        add(_shipHitbox);
      case PlayerMode.ball:
        add(_ballHitbox);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _prevPosition = position.clone();

    final physics = _physics;
    if (physics != null && !state.isDead && !state.isWon) {
      physics.step(dt, this, state, input);
    }

    _updateGroundSparks(dt);
    _updateRotation(dt);
    input.clearFrameInput();
  }

  void _updateGroundSparks(double dt) {
    final grounded =
        state.isOnGround && (state.mode == PlayerMode.cube || state.mode == PlayerMode.ufo);
    if (!grounded) {
      _sparkTimer = 0;
      return;
    }
    _sparkTimer += dt;
    if (_sparkTimer < _sparkInterval) return;
    _sparkTimer = 0;

    final host = parent;
    if (host is Component) {
      spawnGroundSparks(host, position + Vector2(playerSize / 2, playerSize));
    }
  }

  void _updateRotation(double dt) {
    switch (state.mode) {
      case PlayerMode.cube:
        state.rotationAngle = state.isOnGround ? 0.0 : state.rotationAngle + math.pi * 2 * dt;
      case PlayerMode.wave:
      case PlayerMode.sine:
        state.rotationAngle = math.atan2(
          state.velocityY,
          GameConstants.gameSpeed * state.speedMultiplier,
        );
      case PlayerMode.ufo:
        state.rotationAngle = 0.0;
      case PlayerMode.ship:
        final t = (state.velocityY / ShipPhysics.maxVelocity).clamp(-1.0, 1.0);
        state.rotationAngle = t * ShipPhysics.maxAngle;
        _shipHitbox.angle = state.rotationAngle;
      case PlayerMode.ball:
        state.rotationAngle +=
            (GameConstants.gameSpeed * state.speedMultiplier / playerSize) * dt * state.gravitySign;
    }
  }

  @override
  void render(Canvas canvas) {
    canvas.save();
    canvas.translate(playerSize / 2, playerSize / 2);
    canvas.rotate(state.rotationAngle);
    canvas.translate(-playerSize / 2, -playerSize / 2);
    _activeSkin?.render(canvas, playerSize);
    canvas.restore();
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (state.isDead || state.isWon) return;

    if (other is LevelBlock && other.isDeadly) {
      _die();
      return;
    }
    if (other is FinishLine) {
      _win();
      return;
    }
    if (other is LevelBlock && other.isSolid) {
      switch (state.mode) {
        case PlayerMode.wave:
        case PlayerMode.ship:
        case PlayerMode.sine:
          _die();
        case PlayerMode.ball:
          _handleBallBlockCollision(other);
        case PlayerMode.cube:
        case PlayerMode.ufo:
          _handleBlockCollision(other);
      }
    }
  }

  // onCollisionEnd навмисно НЕ перевизначений: відліплення від блоку
  // ("падіння з платформи") вирішується щокадру всередині
  // PlayerPhysics.step (перевірки overlapsX/dropTolerance), а не тут — щоб
  // уникнути мерехтіння між "на блоці"/"у польоті".

  /// "Свіпове" визначення сторони зіткнення через [_prevPosition]: якщо на
  /// попередньому кадрі гравець був повністю над блоком — це приземлення
  /// зверху (безпечно), інакше — удар збоку/знизу (смерть).
  void _handleBlockCollision(LevelBlock block) {
    final blockTop = block.position.y;
    final blockLeft = block.position.x;
    final blockRight = block.position.x + block.size.x;

    final prevBottom = _prevPosition.y + playerSize;
    final cameFromAbove = prevBottom <= blockTop + _collisionTolerance;
    final overlapsXNow = position.x < blockRight && position.x + playerSize > blockLeft;

    if (cameFromAbove && overlapsXNow && state.velocityY >= 0) {
      position.y = blockTop - playerSize;
      state.velocityY = 0;
      state.isOnGround = true;
      state.currentBlock = block;
    } else {
      _die();
    }
  }

  void _handleBallBlockCollision(LevelBlock block) {
    final blockTop = block.position.y;
    final blockBottom = block.position.y + block.size.y;
    final blockLeft = block.position.x;
    final blockRight = block.position.x + block.size.x;
    final overlapsXNow = position.x < blockRight && position.x + playerSize > blockLeft;

    if (state.gravitySign > 0) {
      final prevBottom = _prevPosition.y + playerSize;
      final cameFromAbove = prevBottom <= blockTop + _collisionTolerance;
      if (cameFromAbove && overlapsXNow && state.velocityY >= 0) {
        position.y = blockTop - playerSize;
        state.velocityY = 0;
        state.isOnGround = true;
        state.currentBlock = block;
        return;
      }
    } else {
      final prevTop = _prevPosition.y;
      final cameFromBelow = prevTop >= blockBottom - _collisionTolerance;
      if (cameFromBelow && overlapsXNow && state.velocityY <= 0) {
        position.y = blockBottom;
        state.velocityY = 0;
        state.isOnGround = true;
        state.currentBlock = block;
        return;
      }
    }
    _die();
  }

  void _die() {
    if (state.isDead) return;
    state.isDead = true;

    final host = parent;
    if (host is Component) {
      spawnDeathParticles(host, position + Vector2.all(playerSize / 2));
    }
    onDied?.call();
  }

  void _win() {
    if (state.isWon) return;
    state.isWon = true;
    onWon?.call();
  }

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.keyM) {
      final currentIndex = _debugCycle.indexOf(state.mode);
      setMode(_debugCycle[(currentIndex + 1) % _debugCycle.length]);
      return true;
    }

    if (event.logicalKey == LogicalKeyboardKey.space) {
      if (event is KeyDownEvent) {
        if (!input.jumpHeld) input.jumpPressed = true;
        input.jumpHeld = true;
        return true;
      }
      if (event is KeyUpEvent) {
        input.jumpHeld = false;
        return true;
      }
    }

    return false;
  }
}
