import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leyak_lvl_editor/editor/entities/merge_service.dart';
import 'package:leyak_lvl_editor/editor/models/level_entity.dart';
import 'package:leyak_lvl_editor/editor/models/transform_data.dart';
import 'package:leyak_lvl_editor/editor/models/visual_data.dart';

LevelEntity _entity({
  String id = 'e',
  Vector2? position,
  Vector2? size,
  double rotation = 0,
  Vector2? scale,
  String? groupId,
  int layer = 0,
  Color color = Colors.grey,
}) {
  return LevelEntity(
    id: id,
    transform: TransformData(
      position: position ?? Vector2.zero(),
      size: size ?? Vector2(1, 1),
      rotation: rotation,
      scale: scale,
    ),
    visual: VisualData(color: color),
    groupId: groupId,
    layer: layer,
  );
}

void main() {
  const service = MergeService();

  test('refuses to merge fewer than 2 entities', () {
    expect(service.merge([_entity()]), isNull);
  });

  test('refuses to merge an entity that belongs to a group', () {
    final a = _entity(id: 'a', groupId: 'g1');
    final b = _entity(id: 'b');

    expect(service.merge([a, b]), isNull);
  });

  test('refuses to merge a rotated entity', () {
    final a = _entity(id: 'a', rotation: 0.5);
    final b = _entity(id: 'b');

    expect(service.merge([a, b]), isNull);
  });

  test('refuses to merge a scaled entity', () {
    final a = _entity(id: 'a', scale: Vector2(2, 1));
    final b = _entity(id: 'b');

    expect(service.merge([a, b]), isNull);
  });

  test('merged entity spans the bounding box of all parts', () {
    final a = _entity(id: 'a', position: Vector2(0, 0), size: Vector2(2, 2));
    final b = _entity(id: 'b', position: Vector2(2, 2), size: Vector2(1, 1));

    final merged = service.merge([a, b])!;

    expect(merged.transform.position, Vector2(0, 0));
    expect(merged.transform.size, Vector2(3, 3));
  });

  test('each part keeps its own color and position relative to the merged origin', () {
    final a = _entity(id: 'a', position: Vector2(1, 1), size: Vector2(2, 2), color: Colors.red);
    final b = _entity(id: 'b', position: Vector2(3, 3), size: Vector2(1, 1), color: Colors.blue);

    final merged = service.merge([a, b])!;

    expect(merged.parts, hasLength(2));
    expect(merged.parts![0].relativePosition, Vector2(0, 0));
    expect(merged.parts![0].color, Colors.red);
    expect(merged.parts![1].relativePosition, Vector2(2, 2));
    expect(merged.parts![1].color, Colors.blue);
  });

  test('merged entity takes the highest layer among the merged entities', () {
    final a = _entity(id: 'a', layer: 2);
    final b = _entity(id: 'b', position: Vector2(1, 0), layer: 7);
    final c = _entity(id: 'c', position: Vector2(2, 0), layer: 4);

    final merged = service.merge([a, b, c])!;

    expect(merged.layer, 7);
  });

  test('merged entity visual color mirrors the first entity', () {
    final a = _entity(id: 'a', color: Colors.green);
    final b = _entity(id: 'b', position: Vector2(1, 0), color: Colors.yellow);

    final merged = service.merge([a, b])!;

    expect(merged.visual.color, Colors.green);
  });
}
