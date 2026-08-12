import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leyak_lvl_editor/editor/components/entity_component.dart';
import 'package:leyak_lvl_editor/editor/main_editor.dart';
import 'package:leyak_lvl_editor/editor/models/level_entity.dart';
import 'package:leyak_lvl_editor/editor/models/transform_data.dart';

LevelEntity _entity({Vector2? position, Vector2? size, int layer = 0}) {
  return LevelEntity(
    id: 'e',
    transform: TransformData(position: position ?? Vector2(1, 1), size: size ?? Vector2(2, 2)),
    layer: layer,
  );
}

void main() {
  testWithGame<MainEditor>('onLoad snaps position to the entity target instantly', MainEditor.new, (
    game,
  ) async {
    final entity = _entity(position: Vector2(1, 1), size: Vector2(2, 2));
    final component = EntityComponent(entity);

    await game.ensureAdd(component);

    // target = (position + size/2) * tileSize = (2, 2) * 64
    expect(component.position, Vector2(128, 128));
  });

  testWithGame<MainEditor>('update smooths position towards a moved target rather than snapping', MainEditor.new, (
    game,
  ) async {
    final entity = _entity(position: Vector2(0, 0), size: Vector2(2, 2));
    final component = EntityComponent(entity);
    await game.ensureAdd(component);
    final before = component.position.clone();

    entity.transform.position = Vector2(10, 10);
    component.update(0.001); // tiny dt -> only a small step towards the new target

    expect(component.position, isNot(before));
    expect(component.position.x, lessThan(700)); // far from the new target's x (~704)
  });

  testWithGame<MainEditor>('repeated updates converge onto the moved target', MainEditor.new, (game) async {
    final entity = _entity(position: Vector2(0, 0), size: Vector2(2, 2));
    final component = EntityComponent(entity);
    await game.ensureAdd(component);

    entity.transform.position = Vector2(10, 10);
    for (var i = 0; i < 500; i++) {
      component.update(1 / 60);
    }

    final target = Vector2(11, 11) * game.tileSize;
    expect(component.position.x, closeTo(target.x, 0.5));
    expect(component.position.y, closeTo(target.y, 0.5));
  });

  testWithGame<MainEditor>('update syncs angle, scale, size, and visibility from the entity', MainEditor.new, (
    game,
  ) async {
    final entity = _entity();
    final component = EntityComponent(entity);
    await game.ensureAdd(component);

    entity.transform.rotation = 0.5;
    entity.transform.scale = Vector2(2, 3);
    entity.transform.size = Vector2(4, 5);
    entity.isVisible = false;
    component.update(1 / 60);

    expect(component.angle, 0.5);
    expect(component.scale, Vector2(2, 3));
    expect(component.size, Vector2(4, 5) * game.tileSize);
    expect(component.isVisible, isFalse);
  });

  testWithGame<MainEditor>('priority mirrors the entity layer on load and after reorder', MainEditor.new, (
    game,
  ) async {
    final entity = _entity(layer: 3);
    final component = EntityComponent(entity);
    await game.ensureAdd(component);
    expect(component.priority, 3);

    entity.layer = 7;
    component.update(1 / 60);

    expect(component.priority, 7);
  });

  testWithGame<MainEditor>('snapToTarget jumps instantly, bypassing smoothing', MainEditor.new, (game) async {
    final entity = _entity(position: Vector2(0, 0), size: Vector2(2, 2));
    final component = EntityComponent(entity);
    await game.ensureAdd(component);

    entity.transform.position = Vector2(20, 20);
    component.snapToTarget();

    final target = Vector2(21, 21) * game.tileSize;
    expect(component.position, target);
  });
}
