import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leyak_lvl_editor/editor/components/group_component.dart';
import 'package:leyak_lvl_editor/editor/main_editor.dart';
import 'package:leyak_lvl_editor/editor/models/level_group.dart';

void main() {
  testWithGame<MainEditor>('onLoad sets position to group.position scaled by tileSize', MainEditor.new, (
    game,
  ) async {
    final group = LevelGroup(id: 'g', position: Vector2(2, 3));
    final component = GroupComponent(group);

    await game.ensureAdd(component);

    expect(component.position, Vector2(2, 3) * game.tileSize);
  });

  testWithGame<MainEditor>('update smooths position towards a moved group position', MainEditor.new, (
    game,
  ) async {
    final group = LevelGroup(id: 'g', position: Vector2.zero());
    final component = GroupComponent(group);
    await game.ensureAdd(component);

    group.position = Vector2(10, 10);
    for (var i = 0; i < 500; i++) {
      component.update(1 / 60);
    }

    final target = Vector2(10, 10) * game.tileSize;
    expect(component.position.x, closeTo(target.x, 0.5));
    expect(component.position.y, closeTo(target.y, 0.5));
  });

  testWithGame<MainEditor>('update syncs angle and scale from the group', MainEditor.new, (game) async {
    final group = LevelGroup(id: 'g', position: Vector2.zero());
    final component = GroupComponent(group);
    await game.ensureAdd(component);

    group.rotation = 0.7;
    group.scale = Vector2(2, 4);
    component.update(1 / 60);

    expect(component.angle, 0.7);
    expect(component.scale, Vector2(2, 4));
  });
}
