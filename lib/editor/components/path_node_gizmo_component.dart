import 'dart:ui';

import 'package:flame/components.dart';
import 'package:leyak_lvl_editor/editor/components/entity_component.dart';
import 'package:leyak_lvl_editor/editor/components/path_point_handle_component.dart';
import 'package:leyak_lvl_editor/editor/geometry/path_bounds.dart';
import 'package:leyak_lvl_editor/editor/main_editor.dart';
import 'package:leyak_lvl_editor/editor/models/level_entity.dart';

/// Єдина відповідальність — показати й дати перетягувати якірні точки та
/// bezier-хендли ОДНІЄЇ виділеної path-сутності. Аналог
/// [TransformGizmoComponent], але без обертання/масштабу (шлях — довільний
/// набір точок, а не bounding-box з піваротом) — тому `anchor: Anchor.
/// topLeft`, і дочірні хендли позиціонуються напряму в тій самій локальній
/// системі координат, що й [EntityComponent.render] (0,0 = top-left bbox),
/// без жодної тригонометрії.
///
/// Хендл якоря при відпусканні перераховує bbox ([recomputePathBounds]) —
/// хендли bezier-кривої (in/out) НЕ впливають на bbox і його не чіпають.
class PathNodeGizmoComponent extends PositionComponent with HasGameReference<MainEditor> {
  PathNodeGizmoComponent(
    this.entity,
    this.component, {
    required this.tileSizeOf,
    required this.onDragStarted,
    required this.onCommitted,
  }) : super(anchor: Anchor.topLeft);

  final LevelEntity entity;
  final EntityComponent component;
  final double Function() tileSizeOf;

  /// Композиційний корінь підключає сюди [HistoryController.checkpoint].
  final void Function() onDragStarted;
  final void Function() onCommitted;

  static const Color _anchorColor = Color(0xFF4A9EFF);
  static const Color _handleColor = Color(0xFFFFA726);
  static const double _anchorScreenSize = 10.0;
  static const double _controlHandleScreenSize = 7.0;

  final List<PathPointHandleComponent> _anchorHandles = [];
  final List<PathPointHandleComponent> _inHandles = [];
  final List<PathPointHandleComponent> _outHandles = [];

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final style = entity.shapeStyle;
    for (var i = 0; i < style.pathPoints.length; i++) {
      _anchorHandles.add(
        PathPointHandleComponent(
          color: _anchorColor,
          gridPositionOf: () => style.pathPoints[i],
          onGridPositionChanged: (v) => style.pathPoints[i].setFrom(v),
          onDragStarted: onDragStarted,
          onCommitted: () {
            recomputePathBounds(entity);
            onCommitted();
          },
          tileSizeOf: tileSizeOf,
        ),
      );
      _inHandles.add(
        PathPointHandleComponent(
          color: _handleColor,
          gridPositionOf: () => style.pathPoints[i] + style.pathHandlesIn[i],
          onGridPositionChanged: (v) => style.pathHandlesIn[i].setFrom(v - style.pathPoints[i]),
          onDragStarted: onDragStarted,
          onCommitted: onCommitted,
          tileSizeOf: tileSizeOf,
        ),
      );
      _outHandles.add(
        PathPointHandleComponent(
          color: _handleColor,
          gridPositionOf: () => style.pathPoints[i] + style.pathHandlesOut[i],
          onGridPositionChanged: (v) => style.pathHandlesOut[i].setFrom(v - style.pathPoints[i]),
          onDragStarted: onDragStarted,
          onCommitted: onCommitted,
          tileSizeOf: tileSizeOf,
        ),
      );
    }

    // Контрольні хендли додаються ПЕРШИМИ (нижче в дереві), якорі —
    // останніми (зверху): де вони накладаються, курсор має влучати
    // насамперед у якір.
    await addAll([..._inHandles, ..._outHandles, ..._anchorHandles]);
  }

  @override
  void update(double dt) {
    super.update(dt);

    final tileSize = tileSizeOf();
    final halfSize = (entity.transform.size * tileSize) / 2;
    position.setFrom(component.absolutePosition - halfSize);

    final style = entity.shapeStyle;
    final handleSize = Vector2.all(_anchorScreenSize / game.zoom);
    final controlSize = Vector2.all(_controlHandleScreenSize / game.zoom);

    for (var i = 0; i < _anchorHandles.length; i++) {
      _anchorHandles[i]
        ..position.setFrom(style.pathPoints[i] * tileSize)
        ..size = handleSize;
      _inHandles[i]
        ..position.setFrom((style.pathPoints[i] + style.pathHandlesIn[i]) * tileSize)
        ..size = controlSize;
      _outHandles[i]
        ..position.setFrom((style.pathPoints[i] + style.pathHandlesOut[i]) * tileSize)
        ..size = controlSize;
    }
  }

  @override
  void render(Canvas canvas) {
    final tileSize = tileSizeOf();
    final style = entity.shapeStyle;
    final stickPaint = Paint()
      ..color = _handleColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (var i = 0; i < style.pathPoints.length; i++) {
      final anchorPixel = style.pathPoints[i] * tileSize;
      final inPixel = (style.pathPoints[i] + style.pathHandlesIn[i]) * tileSize;
      final outPixel = (style.pathPoints[i] + style.pathHandlesOut[i]) * tileSize;
      canvas.drawLine(Offset(anchorPixel.x, anchorPixel.y), Offset(inPixel.x, inPixel.y), stickPaint);
      canvas.drawLine(
        Offset(anchorPixel.x, anchorPixel.y),
        Offset(outPixel.x, outPixel.y),
        stickPaint,
      );
    }
  }
}
