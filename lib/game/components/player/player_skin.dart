import 'dart:ui';

/// Єдина відповідальність — чистий рендер (canvas draw) для одного
/// [PlayerMode]. Без фізики/хітбоксів — ті визначаються окремо в
/// [Player._updateHitboxes] (форма хітбокса й форма скіна для одного мода
/// НЕ обов'язково той самий клас, хоч здебільшого й збігаються).
///
/// У джерела (окремий проєкт "Geo Game") тут були власні художні спрайти —
/// їх немає в цьому репозиторії, тож кожен скін тут — проста фігура-
/// примітив (та сама форма, що й хітбокс мода, де це доречно), з
/// відмінним кольором на мод, щоб моди читались з першого погляду під час
/// playtest.
abstract class PlayerSkin {
  const PlayerSkin();

  /// Малює в локальному квадраті `[0,0]..[size,size]` — той самий простір,
  /// у якому [Player] визначає свій хітбокс.
  void render(Canvas canvas, double size);
}

class CubeSkin extends PlayerSkin {
  const CubeSkin();

  @override
  void render(Canvas canvas, double size) {
    final rect = Rect.fromLTWH(0, 0, size, size);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(size * 0.12));
    canvas.drawRRect(rrect, Paint()..color = const Color(0xFFFF9800));
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = const Color(0xFFE65100)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }
}

class WaveSkin extends PlayerSkin {
  const WaveSkin();

  @override
  void render(Canvas canvas, double size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size, size / 2)
      ..lineTo(0, size)
      ..close();
    canvas.drawPath(path, Paint()..color = const Color(0xFF00E5FF));
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF006064)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }
}

class ShipSkin extends PlayerSkin {
  const ShipSkin();

  @override
  void render(Canvas canvas, double size) {
    final w = size / 2;
    final h = size / 2;
    final path = Path()
      ..moveTo(-w * 0.4, -h)
      ..lineTo(w * 0.4, -h)
      ..lineTo(w, 0)
      ..lineTo(w * 0.4, h)
      ..lineTo(-w * 0.4, h)
      ..lineTo(-w, 0)
      ..close();
    canvas.save();
    canvas.translate(w, h);
    canvas.drawPath(path, Paint()..color = const Color(0xFFAB47BC));
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF4A148C)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.restore();
  }
}

class BallSkin extends PlayerSkin {
  const BallSkin();

  @override
  void render(Canvas canvas, double size) {
    final center = Offset(size / 2, size / 2);
    final radius = size / 2;
    canvas.drawCircle(center, radius, Paint()..color = const Color(0xFFFFEB3B));
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = const Color(0xFFF57F17)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }
}

class SineSkin extends PlayerSkin {
  const SineSkin();

  @override
  void render(Canvas canvas, double size) {
    final half = size / 2;
    final path = Path()
      ..moveTo(half, 0)
      ..lineTo(size, half)
      ..lineTo(half, size)
      ..lineTo(0, half)
      ..close();
    canvas.drawPath(path, Paint()..color = const Color(0xFF66BB6A));
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF1B5E20)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }
}

class UfoSkin extends PlayerSkin {
  const UfoSkin();

  @override
  void render(Canvas canvas, double size) {
    final rect = Rect.fromLTWH(0, size * 0.2, size, size * 0.6);
    canvas.drawOval(rect, Paint()..color = const Color(0xFFEC407A));
    canvas.drawOval(
      rect,
      Paint()
        ..color = const Color(0xFF880E4F)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    final domeRect = Rect.fromLTWH(size * 0.28, 0, size * 0.44, size * 0.4);
    canvas.drawOval(domeRect, Paint()..color = const Color(0xFFF8BBD0));
  }
}
