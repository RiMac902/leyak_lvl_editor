import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';

/// Єдина відповідальність — хендл перетягування для обертання цілі.
/// Так само, як [ScaleHandleComponent], навмисно не успадковує кут
/// повороту гізмо ([TransformGizmoComponent] сам ставить [position] у
/// правильну повернуту точку щокадру) — це тримає координати драгу в
/// стабільній, не самореференційній системі відліку.
class RotationHandleComponent extends PositionComponent with DragCallbacks {
  RotationHandleComponent({
    required this.rotationOf,
    required this.onRotationChanged,
    required this.onDragStarted,
    required this.onCommitted,
  }) : super(anchor: Anchor.center);

  final double Function() rotationOf;
  final void Function(double newRotation) onRotationChanged;

  /// Викликається на самому початку драгу — композиційний корінь підключає
  /// сюди [HistoryController.checkpoint], бо ця зміна не йде через
  /// [SceneCubit].
  final void Function() onDragStarted;
  final void Function() onCommitted;

  double? _initialRotation;
  double? _initialPointerAngle;

  double _pointerAngle(Vector2 localPositionFromAnchor) {
    // event.local*Position вимірюється від верхнього лівого кута хендла,
    // а не від його anchor-центру (де насправді сидить [position]) —
    // компенсуємо зсувом на половину розміру.
    final offsetFromAnchor = localPositionFromAnchor - size / 2;
    final pivotRelative = position + offsetFromAnchor;
    return math.atan2(pivotRelative.y, pivotRelative.x);
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    onDragStarted();
    _initialRotation = rotationOf();
    _initialPointerAngle = _pointerAngle(event.localPosition);
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);
    final initialRotation = _initialRotation;
    final initialPointerAngle = _initialPointerAngle;
    if (initialRotation == null || initialPointerAngle == null) return;

    final currentAngle = _pointerAngle(event.localEndPosition);
    onRotationChanged(initialRotation + (currentAngle - initialPointerAngle));
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    _initialRotation = null;
    _initialPointerAngle = null;
    onCommitted();
  }

  @override
  void onDragCancel(DragCancelEvent event) {
    super.onDragCancel(event);
    _initialRotation = null;
    _initialPointerAngle = null;
  }

  @override
  void render(Canvas canvas) {
    canvas.drawCircle(
      Offset(size.x / 2, size.y / 2),
      size.x / 2,
      Paint()..color = const Color(0xFFFFFFFF),
    );
    canvas.drawCircle(
      Offset(size.x / 2, size.y / 2),
      size.x / 2,
      Paint()
        ..color = const Color(0xFF4A9EFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }
}
