import 'package:flame/components.dart';

class TransformData {
  Vector2 position;
  double rotation;
  Vector2 scale;
  Vector2 size;
  Vector2 translateOffset;

  TransformData({
    Vector2? position,
    this.rotation = 0.0,
    Vector2? scale,
    Vector2? size,
    Vector2? translateOffset,
  }) : position = position ?? Vector2.zero(),
       scale = scale ?? Vector2.all(1.0),
       size = size ?? Vector2.all(1.0),
       translateOffset = translateOffset ?? Vector2.zero();
}
