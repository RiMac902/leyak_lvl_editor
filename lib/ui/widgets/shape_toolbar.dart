import 'package:flutter/material.dart';
import 'package:leyak_lvl_editor/editor/main_editor.dart';
import 'package:leyak_lvl_editor/editor/models/shape_type.dart';

/// Панель вибору форми, яку малює [DrawTool] наступного разу (F-режим).
/// Сам [ShapeSelectionController] не є [Listenable] — єдиний спосіб його
/// змінити це сама ця панель, тож локальний [State] просто дублює вибір,
/// а не підписується на щось зовнішнє.
class ShapeToolbar extends StatefulWidget {
  const ShapeToolbar({super.key, required this.game});

  final MainEditor game;

  @override
  State<ShapeToolbar> createState() => _ShapeToolbarState();
}

class _ShapeToolbarState extends State<ShapeToolbar> {
  static const _shapes = [
    (ShapeType.rectangle, Icons.crop_square_outlined, 'Rectangle'),
    (ShapeType.ellipse, Icons.circle_outlined, 'Ellipse'),
    (ShapeType.triangle, Icons.change_history_outlined, 'Triangle'),
    (ShapeType.line, Icons.horizontal_rule, 'Line'),
  ];

  late ShapeType _selected = widget.game.editorWorld.shapeController.current;

  void _select(ShapeType shape) {
    widget.game.editorWorld.shapeController.select(shape);
    setState(() => _selected = shape);
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final (shape, icon, label) in _shapes)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Tooltip(
                    message: label,
                    child: InkWell(
                      onTap: () => _select(shape),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: shape == _selected ? Colors.white24 : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          icon,
                          size: 20,
                          color: shape == _selected ? Colors.white : Colors.white54,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
