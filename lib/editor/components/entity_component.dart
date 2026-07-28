import 'dart:ui';

import 'package:flame/components.dart';
import 'package:leyak_lvl_editor/editor/animation/position_smoothing.dart';
import 'package:leyak_lvl_editor/editor/main_editor.dart';
import 'package:leyak_lvl_editor/editor/models/level_entity.dart';

/// Єдина відповідальність — візуальне представлення однієї [LevelEntity]
/// у дереві компонентів Flame. Щокадру "витягує" свіжі position/rotation/
/// scale/size із сутності (дані лишаються єдиним джерелом правди — цей
/// компонент нічого туди не пише), тож будь-яка зміна ззовні (інструмент
/// перетягування, Inspector) підхоплюється автоматично на наступному кадрі.
/// Позицію згладжує через [PositionSmoothing], щоб рух по сітці не виглядав
/// стрибками між клітинками — так само, як робив колишній
/// EntityMotionAnimator, тільки тепер прив'язано до конкретного компонента.
class EntityComponent extends PositionComponent
    with HasVisibility, HasGameReference<MainEditor> {
  // Anchor.center, а не topLeft: [position] має бути центром фігури, щоб
  // обертання/масштаб (від гізмо чи Inspector) відбувались навколо центру,
  // а не кута — так, як очікує користувач від хендлів трансформації.
  EntityComponent(this.entity) : super(anchor: Anchor.center);

  final LevelEntity entity;

  static const PositionSmoothing _smoothing = PositionSmoothing();

  bool isSelected = false;

  Vector2 _targetPixelPosition() =>
      (entity.transform.position + entity.transform.size / 2) * game.tileSize;

  /// Миттєво (без згладжування) ставить позицію в поточну ціль. Потрібно
  /// при першому кадрі, і коли [SceneComponentRegistry] переносить цей
  /// компонент під нового батька (напр. у [GroupComponent] при групуванні) —
  /// інакше стара абсолютна позиція один кадр читалась би як відносна до
  /// нового батька, і сутність візуально смикнулась би.
  void snapToTarget() => position.setFrom(_targetPixelPosition());

  @override
  void onLoad() {
    super.onLoad();
    snapToTarget();
  }

  @override
  void update(double dt) {
    super.update(dt);

    _smoothing.step(position, _targetPixelPosition(), dt);
    angle = entity.transform.rotation;
    scale.setFrom(entity.transform.scale);
    size.setFrom(entity.transform.size * game.tileSize);
    isVisible = entity.isVisible;
  }

  @override
  void render(Canvas canvas) {
    final parts = entity.parts;
    if (parts != null && parts.isNotEmpty) {
      final tileSize = game.tileSize;
      for (final part in parts) {
        final partRect = Rect.fromLTWH(
          part.relativePosition.x * tileSize,
          part.relativePosition.y * tileSize,
          part.size.x * tileSize,
          part.size.y * tileSize,
        );
        canvas.drawRect(partRect, Paint()..color = part.color);
      }
    } else {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.x, size.y),
        Paint()..color = entity.visual.color,
      );
    }

    if (isSelected) {
      final rect = Rect.fromLTWH(0, 0, size.x, size.y);
      final borderPaint = Paint()
        ..color = const Color(0xFFFFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawRect(rect, borderPaint);
    }
  }
}
