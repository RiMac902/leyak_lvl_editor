import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leyak_lvl_editor/editor/entities/entity_repository.dart';
import 'package:leyak_lvl_editor/editor/entities/group_repository.dart';
import 'package:leyak_lvl_editor/editor/entities/grouping_service.dart';
import 'package:leyak_lvl_editor/editor/models/level_entity.dart';
import 'package:leyak_lvl_editor/editor/models/transform_data.dart';

LevelEntity _entity({
  String id = 'e',
  Vector2? position,
  Vector2? size,
  String? groupId,
}) {
  return LevelEntity(
    id: id,
    transform: TransformData(position: position ?? Vector2.zero(), size: size ?? Vector2(1, 1)),
    groupId: groupId,
  );
}

void main() {
  late EntityRepository entities;
  late GroupRepository groups;
  late GroupingService service;

  setUp(() {
    entities = EntityRepository();
    groups = GroupRepository();
    service = GroupingService(entities, groups);
  });

  group('groupEntities', () {
    test('refuses to group fewer than 2 entities', () {
      final result = service.groupEntities([_entity()]);

      expect(result, isNull);
      expect(groups.all, isEmpty);
    });

    test('refuses to group an entity that is already in a group', () {
      final a = _entity(id: 'a', groupId: 'existing');
      final b = _entity(id: 'b');

      expect(service.groupEntities([a, b]), isNull);
    });

    test('pivot is the center of the combined bounding box', () {
      final a = _entity(id: 'a', position: Vector2(0, 0), size: Vector2(2, 2));
      final b = _entity(id: 'b', position: Vector2(2, 2), size: Vector2(2, 2));

      final group = service.groupEntities([a, b]);

      expect(group, isNotNull);
      expect(group!.position, Vector2(2, 2));
    });

    test('member positions become relative to the pivot and groupId is set', () {
      final a = _entity(id: 'a', position: Vector2(0, 0), size: Vector2(2, 2));
      final b = _entity(id: 'b', position: Vector2(2, 2), size: Vector2(2, 2));

      final group = service.groupEntities([a, b])!;

      expect(a.transform.position, Vector2(-2, -2));
      expect(b.transform.position, Vector2(0, 0));
      expect(a.groupId, group.id);
      expect(b.groupId, group.id);
    });

    test('adds the new group to the group repository', () {
      final a = _entity(id: 'a');
      final b = _entity(id: 'b', position: Vector2(1, 0));

      final group = service.groupEntities([a, b]);

      expect(groups.all, [group]);
    });
  });

  group('ungroup', () {
    test('does nothing for an unknown group id', () {
      service.ungroup('missing');

      expect(groups.all, isEmpty);
    });

    test('bakes rotation/scale into members and clears their groupId', () {
      final a = _entity(id: 'a', position: Vector2(0, 0), size: Vector2(2, 2));
      final b = _entity(id: 'b', position: Vector2(2, 2), size: Vector2(2, 2));
      entities
        ..add(a)
        ..add(b);
      final group = service.groupEntities([a, b])!;
      group.rotation = math.pi / 2;

      service.ungroup(group.id);

      expect(a.groupId, isNull);
      expect(b.groupId, isNull);
      expect(a.transform.rotation, closeTo(math.pi / 2, 1e-9));
      // a was at (-2,-2) relative to pivot; rotated 90deg -> (2,-2), plus pivot (2,2) = (4,0)
      expect(a.transform.position.x, closeTo(4, 1e-9));
      expect(a.transform.position.y, closeTo(0, 1e-9));
    });

    test('removes the group from the repository before restoring members', () {
      final a = _entity(id: 'a', position: Vector2(0, 0), size: Vector2(2, 2));
      final b = _entity(id: 'b', position: Vector2(1, 0), size: Vector2(1, 1));
      entities
        ..add(a)
        ..add(b);
      final group = service.groupEntities([a, b])!;

      service.ungroup(group.id);

      expect(groups.find(group.id), isNull);
    });
  });

  group('fullGroupSelectionOf', () {
    test('returns null for an empty selection', () {
      expect(service.fullGroupSelectionOf([]), isNull);
    });

    test('returns null when selection is not grouped', () {
      expect(service.fullGroupSelectionOf([_entity()]), isNull);
    });

    test('returns null for a partial subset of a group', () {
      final a = _entity(id: 'a', position: Vector2(0, 0), size: Vector2(2, 2));
      final b = _entity(id: 'b', position: Vector2(1, 0), size: Vector2(1, 1));
      entities
        ..add(a)
        ..add(b);
      service.groupEntities([a, b]);

      expect(service.fullGroupSelectionOf([a]), isNull);
    });

    test('returns the group when selection matches its full membership', () {
      final a = _entity(id: 'a', position: Vector2(0, 0), size: Vector2(2, 2));
      final b = _entity(id: 'b', position: Vector2(1, 0), size: Vector2(1, 1));
      entities
        ..add(a)
        ..add(b);
      final group = service.groupEntities([a, b]);

      expect(service.fullGroupSelectionOf([a, b]), group);
      expect(service.fullGroupSelectionOf([b, a]), group);
    });

    test('returns null when entities belong to different groups', () {
      final a = _entity(id: 'a', position: Vector2(0, 0), size: Vector2(1, 1));
      final b = _entity(id: 'b', position: Vector2(1, 0), size: Vector2(1, 1));
      final c = _entity(id: 'c', position: Vector2(2, 0), size: Vector2(1, 1));
      final d = _entity(id: 'd', position: Vector2(3, 0), size: Vector2(1, 1));
      entities
        ..add(a)
        ..add(b)
        ..add(c)
        ..add(d);
      service.groupEntities([a, b]);
      service.groupEntities([c, d]);

      expect(service.fullGroupSelectionOf([a, c]), isNull);
    });
  });
}
