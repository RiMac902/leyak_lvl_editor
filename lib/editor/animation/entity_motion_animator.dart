import 'package:flame/components.dart';
import 'package:leyak_lvl_editor/editor/models/level_entity.dart';

/// Єдина відповідальність — плавно "доганяти" візуальну позицію кожної
/// сутності до її логічної (snapped-по-сітці) позиції, щоб переміщення
/// об'єкта під час перетягування не виглядало стрибками між клітинками.
/// На хіт-тест, marquee чи збережені дані не впливає — це суто ефект
/// рендеру.
class EntityMotionAnimator {
  /// Швидкість згладжування (частка відстані, яку долаємо за секунду).
  static const double _speed = 14.0;

  static const double _snapThreshold = 0.02;

  final Map<LevelEntity, Vector2> _visualPositions = {};

  Vector2 visualPositionOf(LevelEntity entity) =>
      _visualPositions[entity] ?? entity.transform.position;

  void update(double dt, Iterable<LevelEntity> entities) {
    final live = <LevelEntity>{};

    for (final entity in entities) {
      live.add(entity);
      final target = entity.transform.position;
      final current = _visualPositions[entity];

      if (current == null) {
        _visualPositions[entity] = target.clone();
        continue;
      }

      if (current == target) continue;

      final t = (dt * _speed).clamp(0.0, 1.0);
      current.setValues(
        current.x + (target.x - current.x) * t,
        current.y + (target.y - current.y) * t,
      );

      if ((current - target).length < _snapThreshold) {
        current.setFrom(target);
      }
    }

    _visualPositions.removeWhere((entity, _) => !live.contains(entity));
  }
}
