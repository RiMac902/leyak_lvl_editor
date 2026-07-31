import 'package:flame/components.dart';
import 'package:flutter/painting.dart';
import 'package:leyak_lvl_editor/editor/main_editor.dart';

/// Єдина відповідальність — суто візуальний орієнтир "один екран", у межах
/// якого дизайнер компонує фонові папки ([LayerFolder.isBackground]). НЕ
/// інтерактивний (на відміну від [LevelEndMarkerComponent]) — просто рамка.
///
/// Розмір бере з [MainEditor.size] (реальний розмір Flame-канви в логічних
/// пікселях) — це єдине наближення до "розміру екрана пристрою", доки не
/// існує справжньої ігрової камери/паралакс-скролу (майбутня робота, поза
/// межами цієї фічі). Прив'язана лівим краєм до старту рівня (x=0) і нижнім
/// краєм до "землі" ([MainEditor.gridLength] * [MainEditor.tileSize]), щоб
/// читалась як "перший екран рівня, від підлоги до стелі".
class BackgroundFrameComponent extends Component with HasGameReference<MainEditor> {
  final Paint _borderPaint = Paint()
    ..color = const Color(0xFFBB86FC)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.0;

  final TextPainter _labelPainter = TextPainter(
    text: const TextSpan(
      text: 'Background — 1 screen',
      style: TextStyle(color: Color(0xFFBB86FC), fontSize: 14),
    ),
    textDirection: TextDirection.ltr,
  )..layout();

  @override
  void render(Canvas canvas) {
    final bottom = game.gridLength * game.tileSize;
    final rect = Rect.fromLTWH(0, bottom - game.size.y, game.size.x, game.size.y);

    canvas.drawRect(rect, _borderPaint);
    _labelPainter.paint(canvas, Offset(rect.left + 6, rect.top + 6));
  }
}
