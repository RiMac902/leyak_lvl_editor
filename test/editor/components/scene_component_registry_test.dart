import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leyak_lvl_editor/editor/components/entity_component.dart';
import 'package:leyak_lvl_editor/editor/components/group_component.dart';
import 'package:leyak_lvl_editor/editor/components/scene_component_registry.dart';
import 'package:leyak_lvl_editor/editor/entities/entity_repository.dart';
import 'package:leyak_lvl_editor/editor/entities/group_repository.dart';
import 'package:leyak_lvl_editor/editor/entities/grouping_service.dart';
import 'package:leyak_lvl_editor/editor/geometry/grid_coordinate_converter.dart';
import 'package:leyak_lvl_editor/editor/main_editor.dart';
import 'package:leyak_lvl_editor/editor/models/level_entity.dart';
import 'package:leyak_lvl_editor/editor/models/level_group.dart';
import 'package:leyak_lvl_editor/editor/models/transform_data.dart';
import 'package:leyak_lvl_editor/editor/tools/selection_tool.dart';

LevelEntity _entity(String id, {String? groupId}) {
  return LevelEntity(
    id: id,
    transform: TransformData(position: Vector2.zero(), size: Vector2(1, 1)),
    groupId: groupId,
  );
}

class _Fixture {
  _Fixture(this.entities, this.groups, this.selectionTool, this.registry);

  final EntityRepository entities;
  final GroupRepository groups;
  final SelectionTool selectionTool;
  final SceneComponentRegistry registry;
}

_Fixture _fixture() {
  final entities = EntityRepository();
  final groups = GroupRepository();
  final converter = GridCoordinateConverter(() => 64.0, () => true);
  final groupingService = GroupingService(entities, groups);
  final selectionTool = SelectionTool(entities, converter, groupingService);
  final registry = SceneComponentRegistry(entities, selectionTool);
  return _Fixture(entities, groups, selectionTool, registry);
}

void main() {
  testWithGame<MainEditor>('spawn adds a findable EntityComponent as a child of the registry', MainEditor.new, (
    game,
  ) async {
    final fixture = _fixture();
    await game.ensureAdd(fixture.registry);
    final entity = _entity('a');

    fixture.registry.spawn(entity);
    await game.ready();

    final component = fixture.registry.componentOf(entity);
    expect(component, isA<EntityComponent>());
    expect(component!.parent, fixture.registry);
  });

  testWithGame<MainEditor>('despawn removes the component and componentOf returns null', MainEditor.new, (
    game,
  ) async {
    final fixture = _fixture();
    await game.ensureAdd(fixture.registry);
    final entity = _entity('a');
    fixture.registry.spawn(entity);
    await game.ready();

    fixture.registry.despawn(entity);
    await game.ready();

    expect(fixture.registry.componentOf(entity), isNull);
  });

  testWithGame<MainEditor>('spawnGroup re-parents existing member components under the new GroupComponent', MainEditor.new, (
    game,
  ) async {
    final fixture = _fixture();
    await game.ensureAdd(fixture.registry);
    final group = LevelGroup(id: 'g1', position: Vector2(5, 5));
    final member = _entity('a', groupId: 'g1');
    fixture.entities.add(member);
    fixture.registry.spawn(member);
    await game.ready();
    final entityComponent = fixture.registry.componentOf(member)!;
    expect(entityComponent.parent, fixture.registry);

    fixture.registry.spawnGroup(group);
    await game.ready();

    final groupComponent = fixture.registry.groupComponentOf('g1');
    expect(groupComponent, isA<GroupComponent>());
    expect(entityComponent.parent, groupComponent);
  });

  testWithGame<MainEditor>('despawnGroup returns member components back under the registry root', MainEditor.new, (
    game,
  ) async {
    final fixture = _fixture();
    await game.ensureAdd(fixture.registry);
    final group = LevelGroup(id: 'g1', position: Vector2(5, 5));
    final member = _entity('a', groupId: 'g1');
    fixture.entities.add(member);
    fixture.registry.spawn(member);
    fixture.registry.spawnGroup(group);
    await game.ready();
    final entityComponent = fixture.registry.componentOf(member)!;

    fixture.registry.despawnGroup(group);
    await game.ready();

    expect(entityComponent.parent, fixture.registry);
    expect(fixture.registry.groupComponentOf('g1'), isNull);
  });

  testWithGame<MainEditor>('updateSelectionHighlight marks only currently-selected entity components', MainEditor.new, (
    game,
  ) async {
    final fixture = _fixture();
    await game.ensureAdd(fixture.registry);
    final a = _entity('a');
    final b = _entity('b');
    fixture.registry.spawn(a);
    fixture.registry.spawn(b);
    await game.ready();
    fixture.selectionTool.selected.add(a);

    fixture.registry.updateSelectionHighlight();

    expect(fixture.registry.componentOf(a)!.isSelected, isTrue);
    expect(fixture.registry.componentOf(b)!.isSelected, isFalse);
  });
}
