import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leyak_lvl_editor/editor/entities/group_repository.dart';
import 'package:leyak_lvl_editor/editor/models/level_group.dart';

LevelGroup _group(String id) => LevelGroup(id: id, position: Vector2.zero());

void main() {
  test('add stores the group and fires onGroupAdded then onChanged', () {
    final repo = GroupRepository();
    final calls = <String>[];
    repo.onGroupAdded = (_) => calls.add('added');
    repo.onChanged = () => calls.add('changed');

    final group = _group('g1');
    repo.add(group);

    expect(repo.all, [group]);
    expect(calls, ['added', 'changed']);
  });

  test('find returns the matching group or null', () {
    final repo = GroupRepository();
    final group = _group('g1');
    repo.add(group);

    expect(repo.find('g1'), group);
    expect(repo.find('missing'), isNull);
  });

  test('remove drops an existing group and fires callbacks', () {
    final repo = GroupRepository();
    repo.add(_group('g1'));
    final calls = <String>[];
    repo.onGroupRemoved = (_) => calls.add('removed');
    repo.onChanged = () => calls.add('changed');

    repo.remove('g1');

    expect(repo.all, isEmpty);
    expect(calls, ['removed', 'changed']);
  });

  test('remove is a no-op for an unknown id', () {
    final repo = GroupRepository();
    var changedCalled = false;
    repo.onChanged = () => changedCalled = true;

    repo.remove('missing');

    expect(changedCalled, isFalse);
  });

  test('replaceAll removes every old group and adds every new one', () {
    final repo = GroupRepository();
    repo.add(_group('old'));

    final added = <String>[];
    final removed = <String>[];
    repo.onGroupAdded = (g) => added.add(g.id);
    repo.onGroupRemoved = (g) => removed.add(g.id);

    final newGroups = [_group('a'), _group('b')];
    repo.replaceAll(newGroups);

    expect(removed, ['old']);
    expect(added, ['a', 'b']);
    expect(repo.all, newGroups);
  });
}
