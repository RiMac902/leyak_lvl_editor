import 'package:leyak_lvl_editor/editor/models/editor_mode.dart';

/// Отримує та зберігає поточний [EditorMode]. Нічого не знає про
/// клавіатуру чи UI — лише стан і сповіщення про його зміну.
class EditorModeController {
  EditorModeController({this.onModeChanged});

  EditorMode _currentMode = EditorMode.draw;
  void Function(EditorMode mode)? onModeChanged;

  EditorMode get currentMode => _currentMode;

  void setMode(EditorMode mode) {
    if (_currentMode == mode) return;
    _currentMode = mode;
    onModeChanged?.call(mode);
  }
}
