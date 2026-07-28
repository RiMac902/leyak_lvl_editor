import 'dart:ui';

import 'package:flame/components.dart';
import 'package:leyak_lvl_editor/editor/components/rotation_handle_component.dart';
import 'package:leyak_lvl_editor/editor/components/scale_handle_component.dart';
import 'package:leyak_lvl_editor/editor/controllers/transform_target.dart';
import 'package:leyak_lvl_editor/editor/geometry/vector_transform.dart';
import 'package:leyak_lvl_editor/editor/main_editor.dart';

/// Єдина відповідальність — показати рамку bounding-box цілі та хендли
/// обертання/масштабування, тримаючи їх у правильних, повернутих позиціях.
///
/// Сам гізмо НЕ успадковує кут повороту цілі (лишається axis-aligned) —
/// замість композиції трансформу Flame тут навмисно рахує повернуті
/// позиції вручну через [rotateScale], щоб хендли лишались у стабільній,
/// не самореференційній системі координат для drag-математики (див.
/// [RotationHandleComponent]/[ScaleHandleComponent]).
class TransformGizmoComponent extends PositionComponent with HasGameReference<MainEditor> {
  TransformGizmoComponent(this.target, {required this.onDragStarted, required this.onCommitted})
    : super(anchor: Anchor.center);

  final TransformTarget target;
  final void Function() onDragStarted;
  final void Function() onCommitted;

  static const double _handleScreenSize = 10.0;
  static const double _rotationHandleOffset = 24.0;

  late final RotationHandleComponent _rotationHandle;
  late final List<ScaleHandleComponent> _scaleHandles;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    _rotationHandle = RotationHandleComponent(
      rotationOf: () => target.rotation,
      onRotationChanged: (value) => target.rotation = value,
      onDragStarted: onDragStarted,
      onCommitted: onCommitted,
    );
    _scaleHandles = GizmoCorner.values
        .map(
          (corner) => ScaleHandleComponent(
            corner: corner,
            scaleOf: () => target.scale,
            halfLocalSizeOf: () => target.localSize / 2,
            rotationOf: () => target.rotation,
            onScaleChanged: (value) => target.scale = value,
            onDragStarted: onDragStarted,
            onCommitted: onCommitted,
          ),
        )
        .toList();

    await addAll([_rotationHandle, ..._scaleHandles]);
  }

  @override
  void update(double dt) {
    super.update(dt);

    position.setFrom(target.pivotWorldPosition);

    final halfSize = target.localSize / 2;
    final scale = target.scale;
    final rotation = target.rotation;
    final handleSize = Vector2.all(_handleScreenSize / game.zoom);

    _rotationHandle
      ..position.setFrom(
        rotateScale(
          Vector2(0, -halfSize.y * scale.y - _rotationHandleOffset),
          rotation,
          Vector2.all(1),
        ),
      )
      ..size = handleSize;

    for (final handle in _scaleHandles) {
      handle
        ..position.setFrom(
          rotateScale(
            Vector2(handle.corner.dx * halfSize.x * scale.x, handle.corner.dy * halfSize.y * scale.y),
            rotation,
            Vector2.all(1),
          ),
        )
        ..size = handleSize;
    }
  }

  @override
  void render(Canvas canvas) {
    final halfSize = target.localSize / 2;
    final scale = target.scale;
    final rotation = target.rotation;

    Vector2 corner(GizmoCorner c) => rotateScale(
      Vector2(c.dx * halfSize.x * scale.x, c.dy * halfSize.y * scale.y),
      rotation,
      Vector2.all(1),
    );

    final topLeft = corner(GizmoCorner.topLeft);
    final topRight = corner(GizmoCorner.topRight);
    final bottomLeft = corner(GizmoCorner.bottomLeft);
    final bottomRight = corner(GizmoCorner.bottomRight);

    final path = Path()
      ..moveTo(topLeft.x, topLeft.y)
      ..lineTo(topRight.x, topRight.y)
      ..lineTo(bottomRight.x, bottomRight.y)
      ..lineTo(bottomLeft.x, bottomLeft.y)
      ..close();

    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF4A9EFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }
}
