import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:leyak_lvl_editor/editor/main_editor.dart';

/// Єдина відповідальність — вертикальна межа "кінця рівня" на
/// x = [MainEditor.gridWidth] * [MainEditor.tileSize], яку дизайнер сам
/// перетягує, щоб вирішити, де рівень закінчується (як у Geometry Dash).
/// Завжди видима (не залежить від виділення) — додається напряму в
/// [EditorWorld.onLoad], поруч із [GridComponent].
///
/// Хіт-бокс навмисно широкий (не крихітна іконка-хендл) і високий на всю
/// висоту сітки — за лінію можна тягнути в будь-якому місці по вертикалі,
/// той самий підхід "перетягуваного хендла", що й [ScaleHandleComponent]/
/// [PathPointHandleComponent], лише тут ціль — [MainEditor.gridWidth]
/// напряму, а не якесь поле сутності.
class LevelEndMarkerComponent extends PositionComponent
    with DragCallbacks, HasGameReference<MainEditor> {
  LevelEndMarkerComponent() : super(anchor: Anchor.topCenter);

  static const double _hitBoxWidth = 16.0;
  static const int _minGridWidth = 10;

  final Paint _linePaint = Paint()
    ..color = const Color(0xFFFF5C5C)
    ..strokeWidth = 2.0;

  final Paint _handlePaint = Paint()..color = const Color(0xFFFF5C5C);

  int? _initialGridWidth;
  final Vector2 _accumulatedDelta = Vector2.zero();

  @override
  void update(double dt) {
    super.update(dt);
    position.setValues(game.gridWidth * game.tileSize, 0);
    size = Vector2(_hitBoxWidth, game.gridLength * game.tileSize);
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    _initialGridWidth = game.gridWidth;
    _accumulatedDelta.setZero();
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    final initial = _initialGridWidth;
    if (initial == null) return;

    _accumulatedDelta.add(event.localDelta);
    final deltaTiles = (_accumulatedDelta.x / game.tileSize).round();
    game.gridWidth = (initial + deltaTiles) < _minGridWidth
        ? _minGridWidth
        : initial + deltaTiles;
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    _initialGridWidth = null;
  }

  @override
  void onDragCancel(DragCancelEvent event) {
    super.onDragCancel(event);
    _initialGridWidth = null;
  }

  @override
  void render(Canvas canvas) {
    final centerX = size.x / 2;
    canvas.drawLine(Offset(centerX, 0), Offset(centerX, size.y), _linePaint);

    // Маленький "прапорець"-хендл зверху — щоб було видно, що це саме
    // перетягуваний елемент, а не просто лінія сітки.
    final flag = Path()
      ..moveTo(centerX, 0)
      ..lineTo(centerX + 10, 6)
      ..lineTo(centerX, 12)
      ..close();
    canvas.drawPath(flag, _handlePaint);
  }
}
