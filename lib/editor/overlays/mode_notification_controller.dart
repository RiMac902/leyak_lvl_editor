import 'dart:async';

import 'package:flame/game.dart';

/// Єдина відповідальність — показ і автоматичне приховування
/// оверлею 'ModeNotification'. Не знає нічого про режими редактора.
class ModeNotificationController {
  ModeNotificationController(this._game);

  static const overlayId = 'ModeNotification';
  static const _visibleDuration = Duration(milliseconds: 1200);

  final Game _game;
  Timer? _hideTimer;

  void show() {
    _hideTimer?.cancel();
    _game.overlays.add(overlayId);
    _hideTimer = Timer(_visibleDuration, () {
      _game.overlays.remove(overlayId);
    });
  }

  void dispose() {
    _hideTimer?.cancel();
  }
}
