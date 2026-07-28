import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/services.dart';
import 'package:leyak_lvl_editor/editor/geometry/vector_transform.dart';

/// Який кут bounding-box представляє хендл. dx/dy — знак напрямку від
/// центру цілі (-1 чи 1 по кожній осі).
enum GizmoCorner {
  topLeft(-1, -1),
  topRight(1, -1),
  bottomLeft(-1, 1),
  bottomRight(1, 1);

  const GizmoCorner(this.dx, this.dy);
  final double dx;
  final double dy;
}

/// Єдина відповідальність — хендл перетягування одного кута bounding-box
/// для зміни масштабу цілі. Навмисно НЕ успадковує кут повороту гізмо
/// (лишається axis-aligned у власній системі координат) — інакше дельта
/// перетягування самореференційно залежала б від кута, який саме змінює
/// цей самий драг. [TransformGizmoComponent] сам ставить [position] у
/// правильну повернуту точку щокадру через [rotateScale].
class ScaleHandleComponent extends PositionComponent with DragCallbacks {
  ScaleHandleComponent({
    required this.corner,
    required this.scaleOf,
    required this.halfLocalSizeOf,
    required this.rotationOf,
    required this.onScaleChanged,
    required this.onDragStarted,
    required this.onCommitted,
  }) : super(anchor: Anchor.center);

  final GizmoCorner corner;
  final Vector2 Function() scaleOf;
  final Vector2 Function() halfLocalSizeOf;

  /// Поточний кут цілі — потрібен, щоб спроєктувати світовий drag-delta на
  /// локальні (повернуті) осі цілі: тягнути кут поверненої фігури має
  /// відчуватись природно, вздовж її власних сторін, а не світових осей.
  final double Function() rotationOf;
  final void Function(Vector2 newScale) onScaleChanged;

  /// Викликається на самому початку драгу — композиційний корінь підключає
  /// сюди [HistoryController.checkpoint], бо ця зміна не йде через
  /// [SceneCubit].
  final void Function() onDragStarted;
  final void Function() onCommitted;

  Vector2? _initialScale;
  Vector2? _halfLocalSize;
  final Vector2 _accumulatedDelta = Vector2.zero();

  bool get _isShiftHeld =>
      HardwareKeyboard.instance.logicalKeysPressed.contains(LogicalKeyboardKey.shiftLeft) ||
      HardwareKeyboard.instance.logicalKeysPressed.contains(LogicalKeyboardKey.shiftRight);

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    onDragStarted();
    _initialScale = scaleOf().clone();
    _halfLocalSize = halfLocalSizeOf().clone();
    _accumulatedDelta.setZero();
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    final initialScale = _initialScale;
    final halfSize = _halfLocalSize;
    if (initialScale == null || halfSize == null) return;

    _accumulatedDelta.add(event.localDelta);
    final localDelta = rotateScale(_accumulatedDelta, -rotationOf(), Vector2.all(1));

    final deltaX = localDelta.x / (corner.dx * halfSize.x);
    final deltaY = localDelta.y / (corner.dy * halfSize.y);

    if (_isShiftHeld) {
      // Shift = пропорційний масштаб: обидві осі рухаються на ту саму
      // дельту — тягнути кут в будь-якому напрямку однаково масштабує
      // фігуру рівномірно, а не спотворює її.
      final uniformDelta = deltaX.abs() > deltaY.abs() ? deltaX : deltaY;
      onScaleChanged(
        Vector2(initialScale.x + uniformDelta, initialScale.y + uniformDelta),
      );
    } else {
      onScaleChanged(Vector2(initialScale.x + deltaX, initialScale.y + deltaY));
    }
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    _initialScale = null;
    _halfLocalSize = null;
    onCommitted();
  }

  @override
  void onDragCancel(DragCancelEvent event) {
    super.onDragCancel(event);
    _initialScale = null;
    _halfLocalSize = null;
  }

  @override
  void render(Canvas canvas) {
    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
    canvas.drawRect(rect, Paint()..color = const Color(0xFFFFFFFF));
    canvas.drawRect(
      rect,
      Paint()
        ..color = const Color(0xFF4A9EFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }
}
