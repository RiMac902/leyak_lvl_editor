import 'dart:async';

import 'package:flame/game.dart';

/// Єдина відповідальність — показ і автоматичне приховування короткого
/// текстового HUD-сповіщення. Не знає нічого про режими чи snap — лише
/// текст, який їй передають в [show].
class NotificationController {
  NotificationController(this._game);

  static const overlayId = 'HudNotification';
  static const _visibleDuration = Duration(milliseconds: 1200);

  final Game _game;
  Timer? _hideTimer;

  String message = '';

  void show(String text) {
    message = text;
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
