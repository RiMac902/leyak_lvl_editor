import 'package:flame/components.dart';
import 'package:leyak_lvl_editor/game/player_mode.dart';

/// Увесь мутабельний стан симуляції гравця — єдине джерело правди для
/// [PlayerPhysics]. Немає окремого `velocityX`/`position` тут: горизонтальна
/// швидкість завжди = `GameConstants.gameSpeed * speedMultiplier` (постійний
/// скрол), а позиція живе на самому `Player` (PositionComponent.position).
class PlayerState {
  double velocityY = 0.0;
  bool isOnGround = false;
  bool isDead = false;
  bool isWon = false;
  PositionComponent? currentBlock;
  double rotationAngle = 0.0;
  PlayerMode mode = PlayerMode.cube;
  double speedMultiplier = 1.0;

  /// +1 = гравітація вниз (звичайна), -1 = вгору (інвертована ball-модом).
  double gravitySign = 1.0;

  double sineBaseY = 0.0;
  double sinePhase = 0.0;
}
