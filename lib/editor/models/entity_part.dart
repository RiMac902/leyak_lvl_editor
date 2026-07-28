import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Один "шматок" складеної (compound) сутності — аналог одного `<rect>`
/// усередині `<g>` в SVG. [relativePosition]/[size] — у координатах сітки,
/// ВІДНОСНО [TransformData.position] батьківської [LevelEntity], а не
/// абсолютні світові координати.
class EntityPart {
  EntityPart({
    required this.relativePosition,
    required this.size,
    required this.color,
    this.shaderId,
  });

  Vector2 relativePosition;
  Vector2 size;
  Color color;

  /// Заготовка під майбутній рендер кастомним шейдером per-part. Це поле
  /// НЕ підключене до рендеру — так само, як [VisualData.shaderId] сьогодні.
  String? shaderId;
}
