import 'package:flame/components.dart';
import 'package:leyak_lvl_editor/editor/entities/entity_repository.dart';
import 'package:leyak_lvl_editor/editor/entities/group_repository.dart';
import 'package:leyak_lvl_editor/editor/geometry/vector_transform.dart';
import 'package:leyak_lvl_editor/editor/models/level_entity.dart';
import 'package:leyak_lvl_editor/editor/models/level_group.dart';

/// Єдина відповідальність — створення й розпуск постійних груп, і
/// відповідь на питання "чи це виділення — рівно одна ціла група?"
/// (потрібне [SelectionTool] під час руху, гізмо трансформації та
/// Inspector — тому винесене сюди, а не продубльоване в кожному з них).
class GroupingService {
  GroupingService(this._entities, this._groups);

  final EntityRepository _entities;
  final GroupRepository _groups;

  /// Групує щонайменше 2 ще не згрупованих сутностей. Піврот — центр їхнього
  /// спільного bounding-box; позиція кожного члена стає відносною до нього,
  /// щоб композиція трансформів у дереві Flame сама застосовувала
  /// обертання/масштаб групи до членів.
  LevelGroup? groupEntities(List<LevelEntity> entities) {
    if (entities.length < 2) return null;
    if (entities.any((e) => e.groupId != null)) return null;

    var minX = double.infinity, minY = double.infinity;
    var maxX = -double.infinity, maxY = -double.infinity;
    for (final entity in entities) {
      final pos = entity.transform.position;
      final size = entity.transform.size;
      minX = minX < pos.x ? minX : pos.x;
      minY = minY < pos.y ? minY : pos.y;
      maxX = maxX > pos.x + size.x ? maxX : pos.x + size.x;
      maxY = maxY > pos.y + size.y ? maxY : pos.y + size.y;
    }
    final pivot = Vector2((minX + maxX) / 2, (minY + maxY) / 2);

    final group = LevelGroup(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      position: pivot,
    );

    for (final entity in entities) {
      entity.transform.position = entity.transform.position - pivot;
      entity.groupId = group.id;
    }

    _groups.add(group);
    return group;
  }

  /// Розпускає групу: "запікає" відносні позиції/обертання/масштаб членів
  /// назад в абсолютні координати — єдине місце в усій фічі, де потрібна
  /// реальна тригонометрія (одноразово, не щокадру).
  ///
  /// Важливий порядок: [_groups.remove] викликається, ПОКИ члени ще мають
  /// `groupId`, а не після. `onGroupRemoved`-підписник (SceneComponentRegistry)
  /// сам читає [EntityRepository.membersOf] у відповідь на цю подію, щоб
  /// повернути їхні компоненти з-під групи назад під корінь сцени — якби
  /// `groupId` вже був очищений, цей запит повернув би порожній список.
  void ungroup(String groupId) {
    final group = _groups.find(groupId);
    if (group == null) return;

    final members = _entities.membersOf(groupId);
    _groups.remove(groupId);

    for (final member in members) {
      member.transform.position =
          group.position + rotateScale(member.transform.position, group.rotation, group.scale);
      member.transform.rotation += group.rotation;
      member.transform.scale = Vector2(
        member.transform.scale.x * group.scale.x,
        member.transform.scale.y * group.scale.y,
      );
      member.groupId = null;
    }
  }

  /// Повертає групу, якщо [selected] — це рівно повний склад однієї групи
  /// (не підмножина, не суміш кількох груп), інакше `null`.
  LevelGroup? fullGroupSelectionOf(List<LevelEntity> selected) {
    if (selected.isEmpty) return null;

    final groupId = selected.first.groupId;
    if (groupId == null) return null;
    if (selected.any((e) => e.groupId != groupId)) return null;

    final group = _groups.find(groupId);
    if (group == null) return null;

    final members = _entities.membersOf(groupId);
    if (selected.length != members.length) return null;
    if (!selected.every(members.contains)) return null;

    return group;
  }
}
