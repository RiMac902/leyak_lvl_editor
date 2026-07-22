import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/services.dart';
import 'package:leyak_lvl_editor/editor/components/grid_component.dart';
import 'package:leyak_lvl_editor/editor/components/object_manager.dart';
import 'package:leyak_lvl_editor/editor/controllers/editor_mode_controller.dart';
import 'package:leyak_lvl_editor/editor/controllers/grid_snap_controller.dart';
import 'package:leyak_lvl_editor/editor/input/editor_keyboard_shortcuts.dart';
import 'package:leyak_lvl_editor/editor/input/grid_snap_shortcut.dart';
import 'package:leyak_lvl_editor/editor/main_editor.dart';
import 'package:leyak_lvl_editor/editor/models/editor_mode.dart';
import 'package:leyak_lvl_editor/editor/overlays/notification_controller.dart';

/// Композиційний корінь сцени редактора: тримає дочірні компоненти
/// і делегує drag/keyboard події відповідним відповідальним класам.
class EditorWorld extends World
    with DragCallbacks, KeyboardHandler, HasGameReference<MainEditor> {
  final GridComponent grid = GridComponent();
  final ObjectManager objectManager = ObjectManager();
  late final NotificationController _notification;

  final EditorModeController modeController = EditorModeController();
  final GridSnapController snapController = GridSnapController();

  final EditorKeyboardShortcuts _modeShortcuts = const EditorKeyboardShortcuts();
  final GridSnapShortcut _snapShortcut = const GridSnapShortcut();

  Vector2? currentPointerPos;

  EditorMode get currentMode => modeController.currentMode;
  String get notificationText => _notification.message;

  @override
  Future<void> onLoad() async {
    add(grid);
    add(objectManager);

    _notification = NotificationController(game);
    modeController.onModeChanged = (mode) => _notification.show(mode.label);
    snapController.onSnapChanged = (enabled) =>
        _notification.show(enabled ? 'SNAP: ON' : 'SNAP: OFF');
  }

  @override
  void onRemove() {
    _notification.dispose();
    super.onRemove();
  }

  @override
  void onDragStart(DragStartEvent event) {
    currentPointerPos = event.localPosition.clone();
    objectManager.handleDragStart(currentPointerPos!);
    super.onDragStart(event);
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    currentPointerPos?.add(event.localDelta);
    if (currentPointerPos != null) {
      objectManager.handleDragUpdate(currentPointerPos!);
    }
    super.onDragUpdate(event);
  }

  @override
  void onDragEnd(DragEndEvent event) {
    objectManager.handleDragEnd();
    currentPointerPos = null;
    super.onDragEnd(event);
  }

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    final mode = _modeShortcuts.resolve(event);
    if (mode != null) {
      modeController.setMode(mode);
      return true;
    }

    if (_snapShortcut.isToggle(event)) {
      snapController.toggle();
      return true;
    }

    return false;
  }
}
