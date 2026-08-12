import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leyak_lvl_editor/editor/entities/entity_repository.dart';
import 'package:leyak_lvl_editor/editor/entities/group_repository.dart';
import 'package:leyak_lvl_editor/editor/entities/layer_folder_repository.dart';
import 'package:leyak_lvl_editor/editor/history/history_controller.dart';
import 'package:leyak_lvl_editor/editor/models/level_entity.dart';
import 'package:leyak_lvl_editor/editor/models/transform_data.dart';

void main() {
  late EntityRepository entities;
  late GroupRepository groups;
  late LayerFolderRepository folders;
  late HistoryController history;

  setUp(() {
    entities = EntityRepository();
    groups = GroupRepository();
    folders = LayerFolderRepository();
    history = HistoryController(entities, groups, folders);
  });

  test('canUndo/canRedo are false initially', () {
    expect(history.canUndo, isFalse);
    expect(history.canRedo, isFalse);
  });

  test('checkpoint enables undo and clears redo history', () {
    history.checkpoint();

    expect(history.canUndo, isTrue);
    expect(history.canRedo, isFalse);
  });

  test('undo restores the entities to the checkpointed state', () {
    entities.add(LevelEntity(id: 'a', transform: TransformData(position: Vector2(1, 1))));
    history.checkpoint();
    entities.add(LevelEntity(id: 'b'));

    final undone = history.undo();

    expect(undone, isTrue);
    expect(entities.all.map((e) => e.id), ['a']);
  });

  test('undo returns false and changes nothing when there is no history', () {
    entities.add(LevelEntity(id: 'a'));

    final undone = history.undo();

    expect(undone, isFalse);
    expect(entities.all, hasLength(1));
  });

  test('undo pushes the pre-undo state onto the redo stack', () {
    entities.add(LevelEntity(id: 'a'));
    history.checkpoint();
    entities.add(LevelEntity(id: 'b'));

    history.undo();

    expect(history.canRedo, isTrue);
  });

  test('redo re-applies the state that was undone', () {
    entities.add(LevelEntity(id: 'a'));
    history.checkpoint();
    entities.add(LevelEntity(id: 'b'));
    history.undo();

    final redone = history.redo();

    expect(redone, isTrue);
    expect(entities.all.map((e) => e.id), ['a', 'b']);
  });

  test('redo returns false when there is nothing to redo', () {
    expect(history.redo(), isFalse);
  });

  test('a new checkpoint after undo clears the redo stack', () {
    entities.add(LevelEntity(id: 'a'));
    history.checkpoint();
    entities.add(LevelEntity(id: 'b'));
    history.undo();
    expect(history.canRedo, isTrue);

    history.checkpoint();

    expect(history.canRedo, isFalse);
  });

  test('undo stack is capped at maxDepth, dropping the oldest snapshot', () {
    final shortHistory = HistoryController(entities, groups, folders, maxDepth: 2);

    shortHistory.checkpoint(); // snapshot: []
    entities.add(LevelEntity(id: 'a'));
    shortHistory.checkpoint(); // snapshot: [a]
    entities.add(LevelEntity(id: 'b'));
    shortHistory.checkpoint(); // snapshot: [a, b] -- pushes out the oldest ([])
    entities.add(LevelEntity(id: 'c'));

    shortHistory.undo(); // -> [a, b]
    shortHistory.undo(); // -> [a]
    final thirdUndo = shortHistory.undo(); // no more history (oldest snapshot was dropped)

    expect(thirdUndo, isFalse);
    expect(entities.all.map((e) => e.id), ['a']);
  });

}
