import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leyak_lvl_editor/editor/models/entity_part.dart';
import 'package:leyak_lvl_editor/editor/models/layer_folder.dart';
import 'package:leyak_lvl_editor/editor/models/level_entity.dart';
import 'package:leyak_lvl_editor/editor/models/level_group.dart';
import 'package:leyak_lvl_editor/editor/models/shape_style.dart';
import 'package:leyak_lvl_editor/editor/models/shape_type.dart';
import 'package:leyak_lvl_editor/editor/models/transform_data.dart';
import 'package:leyak_lvl_editor/editor/models/visual_data.dart';
import 'package:leyak_lvl_editor/editor/persistence/level_document.dart';

/// Мінімальний, але репрезентативний [ShapeStyle] для кожного [ShapeType] —
/// той самий шлях, яким користується [DrawTool]/[PathTool], а не порожній
/// дефолт, щоб round-trip дійсно перевіряв поля, специфічні для форми.
ShapeStyle _styleFor(ShapeType type) {
  switch (type) {
    case ShapeType.rectangle:
    case ShapeType.triangle:
      return ShapeStyle(cornerRadii: [1, 2, 3, 4]);
    case ShapeType.line:
      return ShapeStyle(lineStart: Vector2(0, 0), lineEnd: Vector2(3, 4), lineThickness: 0.4);
    case ShapeType.ellipse:
      return ShapeStyle();
    case ShapeType.path:
      return ShapeStyle(
        pathPoints: [Vector2(0, 0), Vector2(2, 0), Vector2(2, 2)],
        pathHandlesIn: [Vector2.zero(), Vector2(0.1, 0), Vector2(0.2, 0)],
        pathHandlesOut: [Vector2(0.1, 0), Vector2(0.2, 0), Vector2.zero()],
        pathClosed: true,
      );
  }
}

LevelEntity _entityOf(ShapeType type, {String id = 'e'}) {
  return LevelEntity(
    id: id,
    transform: TransformData(
      position: Vector2(1, 2),
      rotation: 0.3,
      scale: Vector2(1.5, 2.5),
      size: Vector2(3, 4),
    ),
    shapeType: type,
    shapeStyle: _styleFor(type),
  );
}

void main() {
  group('ShapeType coverage: every shape round-trips through JSON', () {
    // Iterating ShapeType.values (rather than one test per literal case)
    // means a newly-added ShapeType is automatically exercised here — if
    // nobody taught `_styleFor` above about it, this loop fails loudly
    // instead of silently skipping the new case.
    for (final type in ShapeType.values) {
      test('$type', () {
        final entity = _entityOf(type);

        final document = LevelDocument(
          tileSize: 64,
          gridWidth: 50,
          gridLength: 50,
          entities: [entity],
          groups: const [],
          folders: const [],
        );
        final restored = LevelDocument.decode(document.encode()).entities.single;

        expect(restored.shapeType, type);
        expect(restored.shapeStyle.cornerRadii, entity.shapeStyle.cornerRadii);
        expect(restored.shapeStyle.lineThickness, entity.shapeStyle.lineThickness);
        expect(restored.shapeStyle.lineStart, entity.shapeStyle.lineStart);
        expect(restored.shapeStyle.lineEnd, entity.shapeStyle.lineEnd);
        expect(restored.shapeStyle.pathPoints, entity.shapeStyle.pathPoints);
        expect(restored.shapeStyle.pathHandlesIn, entity.shapeStyle.pathHandlesIn);
        expect(restored.shapeStyle.pathHandlesOut, entity.shapeStyle.pathHandlesOut);
        expect(restored.shapeStyle.pathClosed, entity.shapeStyle.pathClosed);
      });
    }
  });

  group('LevelEntity round-trip', () {
    test('preserves transform, visual, custom properties, layer, and flags', () {
      final entity = LevelEntity(
        id: 'e1',
        transform: TransformData(
          position: Vector2(5, 6),
          rotation: 1.1,
          scale: Vector2(2, 3),
          size: Vector2(4, 5),
        ),
        visual: VisualData(
          color: Colors.red,
          spritePath: 'assets/sprite.png',
          shaderId: 'ring_glow',
          videoPath: 'assets/videos/sample.mov',
          shaderParams: {'width': 5.0, 'color': Colors.blue},
        ),
        customProperties: {'isSolid': true, 'isDeadly': false, 'label': 'spike'},
        layer: 7,
        groupId: 'g1',
        layerFolderId: 'f1',
        isVisible: false,
        isLocked: true,
      );

      final document = LevelDocument(
        tileSize: 64,
        gridWidth: 50,
        gridLength: 50,
        entities: [entity],
        groups: const [],
        folders: const [],
      );
      final restored = LevelDocument.decode(document.encode()).entities.single;

      expect(restored.id, 'e1');
      expect(restored.transform.position, Vector2(5, 6));
      expect(restored.transform.rotation, 1.1);
      expect(restored.transform.scale, Vector2(2, 3));
      expect(restored.transform.size, Vector2(4, 5));
      // Colors.red is a MaterialColor; Color.== also checks runtimeType, so
      // compare the actual ARGB value rather than object identity/type.
      expect(restored.visual.color.toARGB32(), Colors.red.toARGB32());
      expect(restored.visual.spritePath, 'assets/sprite.png');
      expect(restored.visual.shaderId, 'ring_glow');
      expect(restored.visual.videoPath, 'assets/videos/sample.mov');
      expect(restored.visual.shaderParams['width'], 5.0);
      expect((restored.visual.shaderParams['color'] as Color).toARGB32(), Colors.blue.toARGB32());
      expect(restored.customProperties, {'isSolid': true, 'isDeadly': false, 'label': 'spike'});
      expect(restored.layer, 7);
      expect(restored.groupId, 'g1');
      expect(restored.layerFolderId, 'f1');
      expect(restored.isVisible, isFalse);
      expect(restored.isLocked, isTrue);
    });

    test('preserves compound entities with parts', () {
      final entity = LevelEntity(
        id: 'e2',
        parts: [
          EntityPart(
            relativePosition: Vector2(0, 0),
            size: Vector2(1, 1),
            color: Colors.green,
            shaderParams: {'amount': 2.0},
          ),
          EntityPart(relativePosition: Vector2(1, 0), size: Vector2(1, 1), color: Colors.yellow),
        ],
      );

      final document = LevelDocument(
        tileSize: 64,
        gridWidth: 50,
        gridLength: 50,
        entities: [entity],
        groups: const [],
        folders: const [],
      );
      final restored = LevelDocument.decode(document.encode()).entities.single;

      expect(restored.parts, hasLength(2));
      expect(restored.parts![0].color.toARGB32(), Colors.green.toARGB32());
      expect(restored.parts![0].shaderParams['amount'], 2.0);
      expect(restored.parts![1].relativePosition, Vector2(1, 0));
    });

    test('null-able fields round-trip as null when absent', () {
      final entity = LevelEntity(id: 'e3');

      final document = LevelDocument(
        tileSize: 64,
        gridWidth: 50,
        gridLength: 50,
        entities: [entity],
        groups: const [],
        folders: const [],
      );
      final restored = LevelDocument.decode(document.encode()).entities.single;

      expect(restored.parts, isNull);
      expect(restored.groupId, isNull);
      expect(restored.layerFolderId, isNull);
      expect(restored.visual.shaderId, isNull);
      expect(restored.visual.videoPath, isNull);
    });
  });

  group('LevelGroup and LayerFolder round-trip', () {
    test('preserves group fields', () {
      final group = LevelGroup(id: 'g1', position: Vector2(1, 2), rotation: 0.5, scale: Vector2(2, 2));

      final document = LevelDocument(
        tileSize: 64,
        gridWidth: 50,
        gridLength: 50,
        entities: const [],
        groups: [group],
        folders: const [],
      );
      final restored = LevelDocument.decode(document.encode()).groups.single;

      expect(restored.id, 'g1');
      expect(restored.position, Vector2(1, 2));
      expect(restored.rotation, 0.5);
      expect(restored.scale, Vector2(2, 2));
    });

    test('preserves folder fields', () {
      final folder = LayerFolder(id: 'f1', name: 'Background', isExpanded: false, isBackground: true);

      final document = LevelDocument(
        tileSize: 64,
        gridWidth: 50,
        gridLength: 50,
        entities: const [],
        groups: const [],
        folders: [folder],
      );
      final restored = LevelDocument.decode(document.encode()).folders.single;

      expect(restored.id, 'f1');
      expect(restored.name, 'Background');
      expect(restored.isExpanded, isFalse);
      expect(restored.isBackground, isTrue);
    });
  });

  group('document metadata and versioning', () {
    test('round-trips tileSize/gridWidth/gridLength', () {
      final document = LevelDocument(
        tileSize: 48,
        gridWidth: 80,
        gridLength: 30,
        entities: const [],
        groups: const [],
        folders: const [],
      );

      final restored = LevelDocument.decode(document.encode());

      expect(restored.tileSize, 48);
      expect(restored.gridWidth, 80);
      expect(restored.gridLength, 30);
    });

    test('rejects a file with a missing or mismatched version', () {
      const document = LevelDocument(
        tileSize: 64,
        gridWidth: 50,
        gridLength: 50,
        entities: [],
        groups: [],
        folders: [],
      );
      final json = document.toJson();
      json['version'] = 999;

      expect(
        () => LevelDocument.fromJson(json),
        throwsA(isA<LevelDocumentFormatException>()),
      );
    });
  });
}
