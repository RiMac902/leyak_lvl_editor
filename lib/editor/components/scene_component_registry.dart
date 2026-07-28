import 'package:flame/components.dart';
import 'package:leyak_lvl_editor/editor/components/entity_component.dart';
import 'package:leyak_lvl_editor/editor/components/group_component.dart';
import 'package:leyak_lvl_editor/editor/entities/entity_repository.dart';
import 'package:leyak_lvl_editor/editor/models/level_entity.dart';
import 'package:leyak_lvl_editor/editor/models/level_group.dart';
import 'package:leyak_lvl_editor/editor/tools/selection_tool.dart';

/// Єдина відповідальність — тримати дерево [EntityComponent]/[GroupComponent]
/// у синхроні зі станом [EntityRepository]/[GroupRepository]/[SelectionTool]:
/// створювати/прибирати компоненти точково при додаванні/видаленні/
/// групуванні, і оновлювати прапорець виділення при зміні виділення.
/// Сам нічого не малює.
///
/// Підписки на колбек-слоти репозиторіїв підключає той, хто їх конструює
/// (композиційний корінь), а не цей клас сам — слоти одноразові, і власник
/// має скласти всіх підписників.
class SceneComponentRegistry extends Component {
  SceneComponentRegistry(this._entities, this._selectionTool);

  final EntityRepository _entities;
  final SelectionTool _selectionTool;

  final Map<LevelEntity, EntityComponent> _entityComponents = {};
  final Map<String, GroupComponent> _groupComponents = {};

  void spawn(LevelEntity entity) {
    final component = EntityComponent(entity);
    _entityComponents[entity] = component;
    add(component);
  }

  void despawn(LevelEntity entity) {
    _entityComponents.remove(entity)?.removeFromParent();
  }

  /// Переносить дочірні [EntityComponent] членів групи під новий
  /// [GroupComponent], щоб Flame сам компонував їхній transform із
  /// transform-ом групи.
  void spawnGroup(LevelGroup group) {
    final groupComponent = GroupComponent(group);
    _groupComponents[group.id] = groupComponent;
    add(groupComponent);

    for (final member in _entities.membersOf(group.id)) {
      final entityComponent = _entityComponents[member];
      if (entityComponent == null) continue;
      entityComponent.removeFromParent();
      groupComponent.add(entityComponent);
      entityComponent.snapToTarget();
    }
  }

  /// Повертає дочірні [EntityComponent] назад під корінь сцени. Викликається
  /// з [GroupRepository.onGroupRemoved], яке [GroupingService.ungroup]
  /// навмисно фіксує ДО того, як очистити `groupId` членів — інакше
  /// [EntityRepository.membersOf] тут повернув би вже порожній список.
  void despawnGroup(LevelGroup group) {
    final members = _entities.membersOf(group.id);
    final groupComponent = _groupComponents.remove(group.id);

    for (final member in members) {
      final entityComponent = _entityComponents[member];
      if (entityComponent == null) continue;
      entityComponent.removeFromParent();
      add(entityComponent);
      entityComponent.snapToTarget();
    }

    groupComponent?.removeFromParent();
  }

  void updateSelectionHighlight() {
    for (final entry in _entityComponents.entries) {
      entry.value.isSelected = _selectionTool.selected.contains(entry.key);
    }
  }

  /// Потрібні [TransformGizmoController], щоб знайти живий Flame-компонент
  /// цілі трансформації (гізмо позиціонує себе через [EntityComponent.
  /// absolutePosition]/[GroupComponent.absolutePosition], а не напряму
  /// через дані).
  EntityComponent? componentOf(LevelEntity entity) => _entityComponents[entity];

  GroupComponent? groupComponentOf(String groupId) => _groupComponents[groupId];
}
