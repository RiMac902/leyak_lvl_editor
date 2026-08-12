import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leyak_lvl_editor/editor/main_editor.dart';
import 'package:leyak_lvl_editor/editor/models/editor_mode.dart';
import 'package:leyak_lvl_editor/editor/overlays/notification_controller.dart';

KeyDownEvent _down(LogicalKeyboardKey key) =>
    KeyDownEvent(physicalKey: PhysicalKeyboardKey.keyA, logicalKey: key, timeStamp: Duration.zero);

/// [MainEditor.editorWorld] shows a HUD notification on every mode/snap
/// change, which asserts the overlay name is a known builder — normally
/// registered by the real `GameWidget`'s `overlayBuilderMap`. Outside of
/// that widget tree, register a no-op builder so those side effects don't
/// crash the test.
MainEditor _newEditor() {
  final game = MainEditor();
  game.overlays.addEntry(NotificationController.overlayId, (context, _) => const SizedBox.shrink());
  return game;
}

void main() {
  testWithGame<MainEditor>('S/F/P/C keys switch the editor mode', _newEditor, (game) async {
    final world = game.editorWorld;
    expect(world.currentMode, EditorMode.draw);

    world.onKeyEvent(_down(LogicalKeyboardKey.keyS), {});
    expect(world.currentMode, EditorMode.select);

    world.onKeyEvent(_down(LogicalKeyboardKey.keyP), {});
    expect(world.currentMode, EditorMode.placeSpawn);

    world.onKeyEvent(_down(LogicalKeyboardKey.keyC), {});
    expect(world.currentMode, EditorMode.cameraPath);

    world.onKeyEvent(_down(LogicalKeyboardKey.keyF), {});
    expect(world.currentMode, EditorMode.draw);
  });

  testWithGame<MainEditor>('plain G toggles grid snap', _newEditor, (game) async {
    final world = game.editorWorld;
    expect(world.snapController.snapEnabled, isTrue);

    final handled = world.onKeyEvent(_down(LogicalKeyboardKey.keyG), {});

    expect(handled, isTrue);
    expect(world.snapController.snapEnabled, isFalse);
  });

  testWithGame<MainEditor>(
    'draw -> select -> delete -> undo works end-to-end through key routing',
    _newEditor,
    (game) async {
      await game.ready();
      final world = game.editorWorld;
      final objectManager = world.objectManager;

      // Draw a 2x2-ish tile rectangle at the grid origin.
      objectManager.handleDragStart(Vector2(0, 0));
      objectManager.handleDragUpdate(Vector2(130, 130));
      objectManager.handleDragEnd();
      expect(objectManager.sceneCubit.state.entities, hasLength(1));

      // Switch to select mode and click inside the rectangle to select it.
      world.onKeyEvent(_down(LogicalKeyboardKey.keyS), {});
      objectManager.handleDragStart(Vector2(32, 32));
      objectManager.handleDragEnd();
      expect(objectManager.hasSelection, isTrue);

      // Delete the selection via the Delete shortcut.
      final deleteHandled = world.onKeyEvent(
        KeyDownEvent(
          physicalKey: PhysicalKeyboardKey.delete,
          logicalKey: LogicalKeyboardKey.delete,
          timeStamp: Duration.zero,
        ),
        {},
      );
      expect(deleteHandled, isTrue);
      expect(objectManager.sceneCubit.state.entities, isEmpty);

      // Undo restores the deleted entity.
      final undoHandled = world.onKeyEvent(_down(LogicalKeyboardKey.keyZ), {
        LogicalKeyboardKey.controlLeft,
      });
      expect(undoHandled, isTrue);
      expect(objectManager.sceneCubit.state.entities, hasLength(1));
    },
  );

  testWithGame<MainEditor>('Ctrl+D duplicates the current selection', _newEditor, (game) async {
    await game.ready();
    final world = game.editorWorld;
    final objectManager = world.objectManager;

    objectManager.handleDragStart(Vector2(0, 0));
    objectManager.handleDragUpdate(Vector2(130, 130));
    objectManager.handleDragEnd();
    world.onKeyEvent(_down(LogicalKeyboardKey.keyS), {});
    objectManager.handleDragStart(Vector2(32, 32));
    objectManager.handleDragEnd();

    world.onKeyEvent(_down(LogicalKeyboardKey.keyD), {LogicalKeyboardKey.controlLeft});

    expect(objectManager.sceneCubit.state.entities, hasLength(2));
  });

  testWithGame<MainEditor>('Ctrl+G groups two selected entities, Ctrl+Shift+G ungroups them', _newEditor, (
    game,
  ) async {
    await game.ready();
    final world = game.editorWorld;
    final objectManager = world.objectManager;

    objectManager.handleDragStart(Vector2(0, 0));
    objectManager.handleDragUpdate(Vector2(130, 130));
    objectManager.handleDragEnd();
    objectManager.handleDragStart(Vector2(200, 0));
    objectManager.handleDragUpdate(Vector2(260, 130));
    objectManager.handleDragEnd();

    world.onKeyEvent(_down(LogicalKeyboardKey.keyS), {});
    // Marquee-select both drawn rectangles.
    objectManager.handleDragStart(Vector2(-10, -10));
    objectManager.handleDragUpdate(Vector2(300, 130));
    objectManager.handleDragEnd();
    expect(objectManager.sceneCubit.state.selected, hasLength(2));

    final groupHandled = world.onKeyEvent(_down(LogicalKeyboardKey.keyG), {
      LogicalKeyboardKey.controlLeft,
    });
    expect(groupHandled, isTrue);
    final groupedEntity = objectManager.sceneCubit.state.entities.first;
    expect(groupedEntity.groupId, isNotNull);

    world.onKeyEvent(_down(LogicalKeyboardKey.keyG), {
      LogicalKeyboardKey.controlLeft,
      LogicalKeyboardKey.shiftLeft,
    });

    expect(objectManager.sceneCubit.state.entities.every((e) => e.groupId == null), isTrue);
  });

  testWithGame<MainEditor>('Ctrl+M merges two selected entities into one compound entity', _newEditor, (
    game,
  ) async {
    await game.ready();
    final world = game.editorWorld;
    final objectManager = world.objectManager;

    objectManager.handleDragStart(Vector2(0, 0));
    objectManager.handleDragUpdate(Vector2(130, 130));
    objectManager.handleDragEnd();
    objectManager.handleDragStart(Vector2(200, 0));
    objectManager.handleDragUpdate(Vector2(260, 130));
    objectManager.handleDragEnd();

    world.onKeyEvent(_down(LogicalKeyboardKey.keyS), {});
    objectManager.handleDragStart(Vector2(-10, -10));
    objectManager.handleDragUpdate(Vector2(300, 130));
    objectManager.handleDragEnd();

    final mergeHandled = world.onKeyEvent(_down(LogicalKeyboardKey.keyM), {
      LogicalKeyboardKey.controlLeft,
    });

    expect(mergeHandled, isTrue);
    expect(objectManager.sceneCubit.state.entities, hasLength(1));
    expect(objectManager.sceneCubit.state.entities.single.parts, hasLength(2));
  });
}
