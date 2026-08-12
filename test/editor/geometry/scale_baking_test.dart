import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leyak_lvl_editor/editor/geometry/scale_baking.dart';
import 'package:leyak_lvl_editor/editor/models/level_entity.dart';
import 'package:leyak_lvl_editor/editor/models/level_group.dart';
import 'package:leyak_lvl_editor/editor/models/transform_data.dart';

LevelEntity _entity({required Vector2 position, required Vector2 size, Vector2? scale}) {
  return LevelEntity(
    id: 'e',
    transform: TransformData(position: position, size: size, scale: scale),
  );
}

void main() {
  group('bakeEntityScale', () {
    test('does nothing when scale is already (1,1)', () {
      final entity = _entity(position: Vector2(1, 1), size: Vector2(2, 2));

      bakeEntityScale(entity);

      expect(entity.transform.position, Vector2(1, 1));
      expect(entity.transform.size, Vector2(2, 2));
    });

    test('grows size around the center and resets scale to 1', () {
      final entity = _entity(
        position: Vector2(0, 0),
        size: Vector2(2, 2),
        scale: Vector2(2, 2),
      );

      bakeEntityScale(entity);

      expect(entity.transform.size, Vector2(4, 4));
      expect(entity.transform.position, Vector2(-1, -1));
      expect(entity.transform.scale, Vector2.all(1.0));
    });

    test('uses absolute value of scale so a flip does not shrink size', () {
      final entity = _entity(
        position: Vector2(0, 0),
        size: Vector2(2, 2),
        scale: Vector2(-1, 1),
      );

      bakeEntityScale(entity);

      expect(entity.transform.size, Vector2(2, 2));
      expect(entity.transform.position, Vector2(0, 0));
      expect(entity.transform.scale, Vector2.all(1.0));
    });
  });

  group('bakeGroupScale', () {
    test('does nothing when group scale is already (1,1)', () {
      final group = LevelGroup(id: 'g', position: Vector2.zero());
      final member = _entity(position: Vector2(1, 1), size: Vector2(1, 1));

      bakeGroupScale(group, [member]);

      expect(member.transform.position, Vector2(1, 1));
      expect(member.transform.size, Vector2(1, 1));
    });

    test('scales member position/size relative to group pivot and resets group scale', () {
      final group = LevelGroup(id: 'g', position: Vector2.zero(), scale: Vector2(2, 3));
      final member = _entity(position: Vector2(1, 1), size: Vector2(2, 2));

      bakeGroupScale(group, [member]);

      expect(member.transform.position, Vector2(2, 3));
      expect(member.transform.size, Vector2(4, 6));
      expect(group.scale, Vector2.all(1.0));
    });

    test('applies to every member in the list', () {
      final group = LevelGroup(id: 'g', position: Vector2.zero(), scale: Vector2(2, 2));
      final a = _entity(position: Vector2(1, 0), size: Vector2(1, 1));
      final b = _entity(position: Vector2(0, 1), size: Vector2(1, 1));

      bakeGroupScale(group, [a, b]);

      expect(a.transform.position, Vector2(2, 0));
      expect(b.transform.position, Vector2(0, 2));
    });
  });
}
