import 'package:flame/components.dart';
import 'package:leyak_lvl_editor/editor/animation/position_smoothing.dart';
import 'package:leyak_lvl_editor/editor/main_editor.dart';
import 'package:leyak_lvl_editor/editor/models/level_group.dart';

/// Єдина відповідальність — візуальне представлення [LevelGroup] у дереві
/// Flame. Нічого не малює сам — просто позиціонує/обертає/масштабує себе,
/// а дочірні [EntityComponent] успадковують це через штатну композицію
/// трансформів [PositionComponent] (Flame множить матрицю батька на
/// матрицю дитини при рендері), тому обертання/масштаб групи
/// застосовуються до членів "безкоштовно", без ручної матричної математики.
class GroupComponent extends PositionComponent with HasGameReference<MainEditor> {
  GroupComponent(this.group) : super(anchor: Anchor.topLeft);

  final LevelGroup group;

  static const PositionSmoothing _smoothing = PositionSmoothing();

  @override
  void onLoad() {
    super.onLoad();
    position.setFrom(group.position * game.tileSize);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _smoothing.step(position, group.position * game.tileSize, dt);
    angle = group.rotation;
    scale.setFrom(group.scale);
  }
}
