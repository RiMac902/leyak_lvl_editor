import 'dart:ui';

import 'package:flame/components.dart';

class _TrailPoint {
  _TrailPoint(this.position);
  final Vector2 position;
  double age = 0;
}

/// Згасаючий слід — семплюється з позиції [sampleTarget] (у світових
/// координатах, той самий простір, у якому рухається [Player]), увімкнений
/// лише для wave/ship (див. [enabled], яким керує [Player._applyModeVisuals]).
/// Незалежний [Component] (не дочірній до Player) — точки мають лишатись
/// НЕРУХОМИМИ у світі після семплювання, а не рухатись разом із гравцем.
class PlayerTrail extends Component {
  PlayerTrail({required this.sampleTarget});

  final PositionComponent sampleTarget;
  bool enabled = false;

  static const int _maxPoints = 24;
  static const double _sampleInterval = 0.02;
  static const double _lifetime = 0.5;

  final List<_TrailPoint> _points = [];
  double _timeSinceSample = 0;

  static const Color _color = Color(0xFF29B6F6);

  @override
  void update(double dt) {
    super.update(dt);
    for (final point in _points) {
      point.age += dt;
    }
    _points.removeWhere((point) => point.age > _lifetime);

    if (!enabled) return;
    _timeSinceSample += dt;
    if (_timeSinceSample < _sampleInterval) return;
    _timeSinceSample = 0;

    _points.add(_TrailPoint(sampleTarget.position.clone()));
    if (_points.length > _maxPoints) _points.removeAt(0);
  }

  @override
  void render(Canvas canvas) {
    for (final point in _points) {
      final alpha = (1 - point.age / _lifetime).clamp(0.0, 1.0);
      canvas.drawCircle(
        Offset(point.position.x, point.position.y),
        4 * alpha,
        Paint()..color = _color.withValues(alpha: alpha * 0.6),
      );
    }
  }
}
