import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leyak_lvl_editor/editor/entities/entity_repository.dart';
import 'package:leyak_lvl_editor/editor/entities/group_repository.dart';
import 'package:leyak_lvl_editor/editor/entities/layer_folder_repository.dart';
import 'package:leyak_lvl_editor/editor/history/scene_snapshot.dart';
import 'package:leyak_lvl_editor/editor/models/entity_part.dart';
import 'package:leyak_lvl_editor/editor/models/layer_folder.dart';
import 'package:leyak_lvl_editor/editor/models/level_entity.dart';
import 'package:leyak_lvl_editor/editor/models/level_group.dart';
import 'package:leyak_lvl_editor/editor/models/shape_style.dart';
import 'package:leyak_lvl_editor/editor/models/shape_type.dart';
import 'package:leyak_lvl_editor/editor/models/transform_data.dart';
import 'package:leyak_lvl_editor/editor/models/visual_data.dart';

void main() {
  group('EntitySnapshot', () {
    test('round-trips a plain rectangle entity field-for-field', () {
      final entity = LevelEntity(
        id: 'e1',
        transform: TransformData(
          position: Vector2(1, 2),
          rotation: 0.5,
          scale: Vector2(2, 3),
          size: Vector2(4, 5),
        ),
        visual: VisualData(color: Colors.red, shaderId: 'shader', videoPath: 'v.mov'),
        customProperties: {'solid': true},
        layer: 3,
        groupId: 'g1',
        layerFolderId: 'f1',
        isVisible: false,
        isLocked: true,
      );

      final restored = EntitySnapshot.of(entity).toEntity();

      expect(restored.id, 'e1');
      expect(restored.transform.position, Vector2(1, 2));
      expect(restored.transform.rotation, 0.5);
      expect(restored.transform.scale, Vector2(2, 3));
      expect(restored.transform.size, Vector2(4, 5));
      expect(restored.visual.color, Colors.red);
      expect(restored.visual.shaderId, 'shader');
      expect(restored.visual.videoPath, 'v.mov');
      expect(restored.customProperties, {'solid': true});
      expect(restored.layer, 3);
      expect(restored.groupId, 'g1');
      expect(restored.layerFolderId, 'f1');
      expect(restored.isVisible, isFalse);
      expect(restored.isLocked, isTrue);
    });

    test('round-trips a compound entity with parts', () {
      final entity = LevelEntity(
        id: 'e2',
        parts: [
          EntityPart(relativePosition: Vector2(0, 0), size: Vector2(1, 1), color: Colors.blue),
        ],
      );

      final restored = EntitySnapshot.of(entity).toEntity();

      expect(restored.parts, hasLength(1));
      expect(restored.parts!.single.color, Colors.blue);
    });

    test('mutating the original entity after snapshotting does not affect the snapshot', () {
      final entity = LevelEntity(id: 'e3', transform: TransformData(position: Vector2(1, 1)));

      final snapshot = EntitySnapshot.of(entity);
      entity.transform.position.setValues(99, 99);

      expect(snapshot.position, Vector2(1, 1));
    });

    test('preserves path shape style including bezier handles', () {
      final entity = LevelEntity(
        id: 'e4',
        shapeType: ShapeType.path,
        shapeStyle: ShapeStyle(
          pathPoints: [Vector2(0, 0), Vector2(1, 1)],
          pathHandlesIn: [Vector2(0.1, 0.1), Vector2(0.2, 0.2)],
          pathClosed: true,
        ),
      );

      final restored = EntitySnapshot.of(entity).toEntity();

      expect(restored.shapeType, ShapeType.path);
      expect(restored.shapeStyle.pathPoints, [Vector2(0, 0), Vector2(1, 1)]);
      expect(restored.shapeStyle.pathClosed, isTrue);
    });
  });

  group('GroupSnapshot', () {
    test('round-trips a group', () {
      final group = LevelGroup(id: 'g1', position: Vector2(3, 4), rotation: 1.2, scale: Vector2(2, 2));

      final restored = GroupSnapshot.of(group).toGroup();

      expect(restored.id, 'g1');
      expect(restored.position, Vector2(3, 4));
      expect(restored.rotation, 1.2);
      expect(restored.scale, Vector2(2, 2));
    });
  });

  group('LayerFolderSnapshot', () {
    test('round-trips a folder', () {
      final folder = LayerFolder(id: 'f1', name: 'Background', isExpanded: false, isBackground: true);

      final restored = LayerFolderSnapshot.of(folder).toFolder();

      expect(restored.id, 'f1');
      expect(restored.name, 'Background');
      expect(restored.isExpanded, isFalse);
      expect(restored.isBackground, isTrue);
    });
  });

  group('SceneSnapshot.capture', () {
    test('captures all entities, groups, and folders present in the repositories', () {
      final entities = EntityRepository()..add(LevelEntity(id: 'e1'));
      final groups = GroupRepository()..add(LevelGroup(id: 'g1', position: Vector2.zero()));
      final folders = LayerFolderRepository()..add(LayerFolder(id: 'f1', name: 'f'));

      final snapshot = SceneSnapshot.capture(entities, groups, folders);

      expect(snapshot.entities, hasLength(1));
      expect(snapshot.groups, hasLength(1));
      expect(snapshot.layerFolders, hasLength(1));
      expect(snapshot.entities.single.id, 'e1');
    });
  });
}
