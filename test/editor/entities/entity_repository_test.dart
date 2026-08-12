import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leyak_lvl_editor/editor/entities/entity_repository.dart';
import 'package:leyak_lvl_editor/editor/geometry/grid_rect.dart';
import 'package:leyak_lvl_editor/editor/models/level_entity.dart';
import 'package:leyak_lvl_editor/editor/models/transform_data.dart';

LevelEntity _entity({
  String id = 'e',
  Vector2? position,
  Vector2? size,
  int layer = 0,
  String? groupId,
  bool isVisible = true,
  bool isLocked = false,
}) {
  return LevelEntity(
    id: id,
    transform: TransformData(position: position ?? Vector2.zero(), size: size ?? Vector2(1, 1)),
    layer: layer,
    groupId: groupId,
    isVisible: isVisible,
    isLocked: isLocked,
  );
}

void main() {
  group('EntityRepository add/remove', () {
    test('add appends the entity and fires callbacks in order', () {
      final repo = EntityRepository();
      final calls = <String>[];
      repo.onEntityAdded = (_) => calls.add('added');
      repo.onChanged = () => calls.add('changed');

      final entity = _entity();
      repo.add(entity);

      expect(repo.all, [entity]);
      expect(calls, ['added', 'changed']);
    });

    test('remove drops the entity and fires callbacks in order', () {
      final repo = EntityRepository();
      final entity = _entity();
      repo.add(entity);
      final calls = <String>[];
      repo.onEntityRemoved = (_) => calls.add('removed');
      repo.onChanged = () => calls.add('changed');

      repo.remove(entity);

      expect(repo.all, isEmpty);
      expect(calls, ['removed', 'changed']);
    });

    test('all is unmodifiable', () {
      final repo = EntityRepository();
      repo.add(_entity());

      expect(() => repo.all.add(_entity(id: 'x')), throwsUnsupportedError);
    });
  });

  group('EntityRepository.replaceAll', () {
    test('removes every old entity and adds every new one via per-entity callbacks', () {
      final repo = EntityRepository();
      final oldEntity = _entity(id: 'old');
      repo.add(oldEntity);

      final addedIds = <String>[];
      final removedIds = <String>[];
      repo.onEntityAdded = (e) => addedIds.add(e.id);
      repo.onEntityRemoved = (e) => removedIds.add(e.id);

      final newEntities = [_entity(id: 'a'), _entity(id: 'b')];
      repo.replaceAll(newEntities);

      expect(removedIds, ['old']);
      expect(addedIds, ['a', 'b']);
      expect(repo.all, newEntities);
    });
  });

  group('EntityRepository.absolutePositionOf', () {
    test('returns local position when entity is not grouped', () {
      final repo = EntityRepository();
      final entity = _entity(position: Vector2(3, 4));

      expect(repo.absolutePositionOf(entity), Vector2(3, 4));
    });

    test('adds group offset resolved lazily when entity is grouped', () {
      final repo = EntityRepository(resolveGroupOffset: (groupId) => Vector2(10, 20));
      final entity = _entity(position: Vector2(1, 1), groupId: 'g1');

      expect(repo.absolutePositionOf(entity), Vector2(11, 21));
    });
  });

  group('EntityRepository.membersOf / membersOfFolder', () {
    test('membersOf returns only entities with matching groupId', () {
      final repo = EntityRepository();
      final a = _entity(id: 'a', groupId: 'g1');
      final b = _entity(id: 'b', groupId: 'g2');
      final c = _entity(id: 'c', groupId: 'g1');
      repo
        ..add(a)
        ..add(b)
        ..add(c);

      expect(repo.membersOf('g1'), [a, c]);
    });
  });

  group('EntityRepository.nextLayer', () {
    test('is 0 for an empty repository', () {
      expect(EntityRepository().nextLayer, 0);
    });

    test('is one above the current highest layer', () {
      final repo = EntityRepository();
      repo.add(_entity(id: 'a', layer: 3));
      repo.add(_entity(id: 'b', layer: 7));

      expect(repo.nextLayer, 8);
    });
  });

  group('EntityRepository.findAt', () {
    test('finds the entity whose bounds contain the point', () {
      final repo = EntityRepository();
      final entity = _entity(position: Vector2(0, 0), size: Vector2(2, 2));
      repo.add(entity);

      expect(repo.findAt(Vector2(1, 1)), entity);
    });

    test('returns null when point is outside every entity', () {
      final repo = EntityRepository();
      repo.add(_entity(position: Vector2(0, 0), size: Vector2(2, 2)));

      expect(repo.findAt(Vector2(5, 5)), isNull);
    });

    test('prefers the topmost layer when entities overlap', () {
      final repo = EntityRepository();
      final bottom = _entity(id: 'bottom', position: Vector2(0, 0), size: Vector2(2, 2), layer: 0);
      final top = _entity(id: 'top', position: Vector2(0, 0), size: Vector2(2, 2), layer: 1);
      repo
        ..add(bottom)
        ..add(top);

      expect(repo.findAt(Vector2(1, 1)), top);
    });

    test('skips invisible entities', () {
      final repo = EntityRepository();
      final entity = _entity(position: Vector2(0, 0), size: Vector2(2, 2), isVisible: false);
      repo.add(entity);

      expect(repo.findAt(Vector2(1, 1)), isNull);
    });

    test('skips locked entities', () {
      final repo = EntityRepository();
      final entity = _entity(position: Vector2(0, 0), size: Vector2(2, 2), isLocked: true);
      repo.add(entity);

      expect(repo.findAt(Vector2(1, 1)), isNull);
    });
  });

  group('EntityRepository.findWithin', () {
    test('returns entities intersecting the region, excluding locked/invisible', () {
      final repo = EntityRepository();
      final inside = _entity(id: 'inside', position: Vector2(1, 1), size: Vector2(1, 1));
      final outside = _entity(id: 'outside', position: Vector2(20, 20), size: Vector2(1, 1));
      final locked = _entity(
        id: 'locked',
        position: Vector2(1, 1),
        size: Vector2(1, 1),
        isLocked: true,
      );
      repo
        ..add(inside)
        ..add(outside)
        ..add(locked);

      final region = GridRect(Vector2(0, 0), Vector2(5, 5));
      expect(repo.findWithin(region), [inside]);
    });
  });

  group('EntityRepository.sortedByLayer', () {
    test('sorts ascending by layer', () {
      final repo = EntityRepository();
      final high = _entity(id: 'high', layer: 5);
      final low = _entity(id: 'low', layer: 1);
      repo
        ..add(high)
        ..add(low);

      expect(repo.sortedByLayer, [low, high]);
    });
  });
}
