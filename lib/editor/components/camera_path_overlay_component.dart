import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:leyak_lvl_editor/editor/main_editor.dart';
import 'package:leyak_lvl_editor/editor/models/level_entity.dart';

/// Єдина відповідальність — з'єднати вузли камери ([CameraNodeTool])
/// лінією, щоб дизайнер бачив шлях камери як єдине ціле. Самі вузли
/// нічого спеціального не потребують — вони вже рендеряться як звичайні
/// кольорові фігури через [EntityComponent]; цей компонент домальовує
/// ЛИШЕ з'єднувальні лінії поверх.
///
/// [entitiesOf] — лінивий колбек (той самий ідіом, що й
/// [GridCoordinateConverter]), а не пряме посилання на [EntityRepository] —
/// цей компонент суто для рендеру й не має причин знати про решту
/// композиційного кореня.
class CameraPathOverlayComponent extends Component with HasGameReference<MainEditor> {
  CameraPathOverlayComponent({required this.entitiesOf});

  final List<LevelEntity> Function() entitiesOf;

  final Paint _linePaint = Paint()
    ..color = const Color(0xFFFFC107)
    ..strokeWidth = 2.0;

  @override
  void render(Canvas canvas) {
    final tileSize = game.tileSize;
    final nodes = entitiesOf().where((e) => e.customProperties['isCameraNode'] == true).toList()
      ..sort((a, b) {
        final orderA = a.customProperties['cameraNodeOrder'] as int? ?? 0;
        final orderB = b.customProperties['cameraNodeOrder'] as int? ?? 0;
        return orderA.compareTo(orderB);
      });

    if (nodes.length < 2) return;

    for (var i = 0; i < nodes.length - 1; i++) {
      final a = (nodes[i].transform.position + nodes[i].transform.size / 2) * tileSize;
      final b = (nodes[i + 1].transform.position + nodes[i + 1].transform.size / 2) * tileSize;
      canvas.drawLine(Offset(a.x, a.y), Offset(b.x, b.y), _linePaint);
    }
  }
}
