/// Прапорці вводу гравця.
///
/// [jumpPressed] — одноразовий: true лише на кадрі натискання, скидається
/// в кінці `Player.update()` через [clearFrameInput] — щоб "натискання"
/// не інтерпретувалось повторно щокадру, поки клавішу тримають.
/// [jumpHeld] — тримається true весь час, поки клавішу утримують (потрібен
/// wave/ship, де керує саме утримання, а не одноразовий тап).
class PlayerInput {
  bool jumpPressed = false;
  bool jumpHeld = false;

  void clearFrameInput() {
    jumpPressed = false;
  }
}
