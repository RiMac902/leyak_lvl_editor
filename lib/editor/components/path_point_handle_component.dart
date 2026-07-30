import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';

/// Єдина відповідальність — хендл перетягування ОДНОЇ точки path-контуру:
/// або якірної точки ([ShapeStyle.pathPoints]), або одного bezier-хендла
/// ([pathHandlesIn]/[pathHandlesOut]) — байдуже якої саме, обидві мають
/// однаковий "grid-позиція → grid-позиція" контракт, тож один клас
/// обслуговує всі три ролі через передані колбеки. Той самий 4-колбековий
/// драг-паттерн, що й [ScaleHandleComponent] (initial-знімок при
/// dragStart, накопичена дельта, onCommitted при відпусканні) — тут БЕЗ
/// компенсації повороту (path-гізмо завжди axis-aligned, обертання не
/// підтримується).
class PathPointHandleComponent extends PositionComponent with DragCallbacks {
  PathPointHandleComponent({
    required this.color,
    required this.gridPositionOf,
    required this.onGridPositionChanged,
    required this.onDragStarted,
    required this.onCommitted,
    required this.tileSizeOf,
  }) : super(anchor: Anchor.center);

  final Color color;
  final Vector2 Function() gridPositionOf;
  final void Function(Vector2 newGridPosition) onGridPositionChanged;

  /// Викликається на самому початку драгу — композиційний корінь підключає
  /// сюди [HistoryController.checkpoint].
  final void Function() onDragStarted;
  final void Function() onCommitted;
  final double Function() tileSizeOf;

  Vector2? _initialGridPosition;
  final Vector2 _accumulatedPixelDelta = Vector2.zero();

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    onDragStarted();
    _initialGridPosition = gridPositionOf().clone();
    _accumulatedPixelDelta.setZero();
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    final initial = _initialGridPosition;
    if (initial == null) return;

    _accumulatedPixelDelta.add(event.localDelta);
    onGridPositionChanged(initial + _accumulatedPixelDelta / tileSizeOf());
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    _initialGridPosition = null;
    onCommitted();
  }

  @override
  void onDragCancel(DragCancelEvent event) {
    super.onDragCancel(event);
    _initialGridPosition = null;
  }

  @override
  void render(Canvas canvas) {
    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
    canvas.drawRect(rect, Paint()..color = const Color(0xFFFFFFFF));
    canvas.drawRect(
      rect,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }
}
