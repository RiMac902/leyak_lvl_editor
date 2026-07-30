import 'package:leyak_lvl_editor/editor/models/layer_folder.dart';
import 'package:leyak_lvl_editor/editor/models/level_entity.dart';

/// Незалежний від Flame знімок сцени для Flutter UI (Layers/Inspector).
/// Списки — immutable-копії на момент емісії; самі [LevelEntity] лишаються
/// "живими" мутабельними об'єктами, як їх очікує рендер-цикл Flame.
class SceneState {
  const SceneState({this.entities = const [], this.selected = const [], this.folders = const []});

  final List<LevelEntity> entities;
  final List<LevelEntity> selected;
  final List<LayerFolder> folders;
}
