import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leyak_lvl_editor/editor/entities/entity_repository.dart';
import 'package:leyak_lvl_editor/editor/entities/layer_folder_repository.dart';
import 'package:leyak_lvl_editor/editor/entities/layer_folder_service.dart';
import 'package:leyak_lvl_editor/editor/models/level_entity.dart';
import 'package:leyak_lvl_editor/editor/models/transform_data.dart';

LevelEntity _entity({required String id, int layer = 0, String? layerFolderId}) {
  return LevelEntity(
    id: id,
    transform: TransformData(position: Vector2.zero(), size: Vector2(1, 1)),
    layer: layer,
    layerFolderId: layerFolderId,
  );
}

void main() {
  late EntityRepository entities;
  late LayerFolderRepository folders;
  late LayerFolderService service;

  setUp(() {
    entities = EntityRepository();
    folders = LayerFolderRepository();
    service = LayerFolderService(entities, folders);
  });

  group('createFolder', () {
    test('refuses to create a folder from fewer than 2 entities', () {
      final a = _entity(id: 'a');
      entities.add(a);

      expect(service.createFolder([a], 'name'), isNull);
      expect(folders.all, isEmpty);
    });

    test('refuses when an entity is already in a folder', () {
      final a = _entity(id: 'a', layerFolderId: 'existing');
      final b = _entity(id: 'b');
      entities
        ..add(a)
        ..add(b);

      expect(service.createFolder([a, b], 'name'), isNull);
    });

    test('assigns the new folder id to every member', () {
      final a = _entity(id: 'a', layer: 0);
      final b = _entity(id: 'b', layer: 1);
      entities
        ..add(a)
        ..add(b);

      final folder = service.createFolder([a, b], 'Group A')!;

      expect(a.layerFolderId, folder.id);
      expect(b.layerFolderId, folder.id);
      expect(folder.name, 'Group A');
      expect(folders.all, [folder]);
    });

    test('collects scattered members into one contiguous block at the topmost slot', () {
      final a = _entity(id: 'a', layer: 0);
      final other = _entity(id: 'other', layer: 1);
      final b = _entity(id: 'b', layer: 2);
      entities
        ..add(a)
        ..add(other)
        ..add(b);

      service.createFolder([a, b], 'folder');

      // top-to-bottom order was [b(2), other(1), a(0)]; grouping a & b as a
      // block at b's slot gives top-to-bottom [b, a, other] -> layers 2,1,0.
      expect(b.layer, 2);
      expect(a.layer, 1);
      expect(other.layer, 0);
    });
  });

  group('deleteFolder', () {
    test('clears layerFolderId from members without touching layer order', () {
      final a = _entity(id: 'a', layer: 0);
      final b = _entity(id: 'b', layer: 1);
      entities
        ..add(a)
        ..add(b);
      final folder = service.createFolder([a, b], 'folder')!;

      service.deleteFolder(folder.id);

      expect(a.layerFolderId, isNull);
      expect(b.layerFolderId, isNull);
      expect(folders.find(folder.id), isNull);
    });
  });

  group('renameFolder / toggleExpanded', () {
    test('renameFolder updates the name of an existing folder', () {
      final a = _entity(id: 'a');
      final b = _entity(id: 'b');
      entities
        ..add(a)
        ..add(b);
      final folder = service.createFolder([a, b], 'old')!;

      service.renameFolder(folder.id, 'new');

      expect(folder.name, 'new');
    });

    test('renameFolder is a no-op for an unknown id', () {
      expect(() => service.renameFolder('missing', 'x'), returnsNormally);
    });

    test('toggleExpanded flips isExpanded', () {
      final a = _entity(id: 'a');
      final b = _entity(id: 'b');
      entities
        ..add(a)
        ..add(b);
      final folder = service.createFolder([a, b], 'folder')!;
      expect(folder.isExpanded, isTrue);

      service.toggleExpanded(folder.id);

      expect(folder.isExpanded, isFalse);
    });
  });

  group('setFolderBackground', () {
    test('true pushes every member below the current lowest layer', () {
      final other = _entity(id: 'other', layer: 0);
      final a = _entity(id: 'a', layer: 1);
      final b = _entity(id: 'b', layer: 2);
      entities
        ..add(other)
        ..add(a)
        ..add(b);
      final folder = service.createFolder([a, b], 'folder')!;

      service.setFolderBackground(folder.id, true);

      expect(folder.isBackground, isTrue);
      expect(a.layer < other.layer, isTrue);
      expect(b.layer < other.layer, isTrue);
    });

    test('false moves members back above the current highest layer', () {
      final a = _entity(id: 'a', layer: 0);
      final b = _entity(id: 'b', layer: 1);
      final other = _entity(id: 'other', layer: 2);
      entities
        ..add(a)
        ..add(b)
        ..add(other);
      final folder = service.createFolder([a, b], 'folder')!;
      service.setFolderBackground(folder.id, true);

      service.setFolderBackground(folder.id, false);

      expect(folder.isBackground, isFalse);
      expect(a.layer > other.layer, isTrue);
      expect(b.layer > other.layer, isTrue);
    });

    test('is a no-op when the value already matches', () {
      final a = _entity(id: 'a');
      final b = _entity(id: 'b');
      entities
        ..add(a)
        ..add(b);
      final folder = service.createFolder([a, b], 'folder')!;
      final layerBefore = a.layer;

      service.setFolderBackground(folder.id, false);

      expect(a.layer, layerBefore);
    });
  });
}
