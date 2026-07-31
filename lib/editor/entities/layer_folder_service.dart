import 'package:leyak_lvl_editor/editor/entities/entity_repository.dart';
import 'package:leyak_lvl_editor/editor/entities/layer_folder_repository.dart';
import 'package:leyak_lvl_editor/editor/models/layer_folder.dart';
import 'package:leyak_lvl_editor/editor/models/level_entity.dart';

/// Єдина відповідальність — створення/розпуск папок шарів (Layers panel).
/// На відміну від [GroupingService] — жодної трансформ-математики, бо
/// [LayerFolder] не пов'язує обертання/масштаб членів, лише їхній
/// z-порядок ([LevelEntity.layer]).
class LayerFolderService {
  LayerFolderService(this._entities, this._folders);

  final EntityRepository _entities;
  final LayerFolderRepository _folders;

  /// Створює папку з щонайменше 2 ще не згрупованих (у папку) сутностей.
  /// Перенумеровує `layer` УСІХ сутностей репозиторію так, щоб нові члени
  /// стали одним суцільним блоком на місці найвищої з них — решта
  /// лишається у своєму відносному порядку. Той самий принцип
  /// перенумерування, що й [SceneCubit.reorderLayers] (`layer =
  /// length-1-i` за явним top-to-bottom списком), лише список тут
  /// будується автоматично через [_collectAsBlock].
  LayerFolder? createFolder(List<LevelEntity> entities, String name) {
    if (entities.length < 2) return null;
    if (entities.any((e) => e.layerFolderId != null)) return null;

    final folder = LayerFolder(id: DateTime.now().microsecondsSinceEpoch.toString(), name: name);
    for (final entity in entities) {
      entity.layerFolderId = folder.id;
    }
    _folders.add(folder);

    final topToBottom = _entities.sortedByLayer.reversed.toList();
    final reordered = _collectAsBlock(topToBottom, entities.toSet());
    for (var i = 0; i < reordered.length; i++) {
      reordered[i].layer = reordered.length - 1 - i;
    }

    return folder;
  }

  /// Знімає `layerFolderId` з членів і видаляє папку. `layer` не
  /// перенумеровується — позиції сутностей не змінюються, зникає лише
  /// групування.
  void deleteFolder(String folderId) {
    for (final entity in _entities.membersOfFolder(folderId)) {
      entity.layerFolderId = null;
    }
    _folders.remove(folderId);
  }

  void renameFolder(String folderId, String name) {
    _folders.find(folderId)?.name = name;
  }

  void toggleExpanded(String folderId) {
    final folder = _folders.find(folderId);
    if (folder != null) folder.isExpanded = !folder.isExpanded;
  }

  /// Позначає/знімає папку як фон рівня — члени переносяться суцільним
  /// блоком (у своєму поточному відносному порядку) або під найнижчий
  /// наявний `layer` (background = true: назавжди позаду всього — [nextLayer]
  /// лише росте вгору, тож майбутній звичайний контент ніколи не опиниться
  /// нижче), або на верх стека через [EntityRepository.nextLayer]
  /// (background = false — те саме "повертається нагору", що й після
  /// duplicate/merge).
  void setFolderBackground(String folderId, bool value) {
    final folder = _folders.find(folderId);
    if (folder == null || folder.isBackground == value) return;

    final members = _entities.membersOfFolder(folderId).toSet();
    final ordered = _entities.sortedByLayer.reversed.where(members.contains).toList();

    if (value) {
      final all = _entities.all;
      final minLayer = all.isEmpty
          ? 0
          : all.map((e) => e.layer).reduce((a, b) => a < b ? a : b);
      final base = minLayer - ordered.length;
      for (var i = 0; i < ordered.length; i++) {
        ordered[i].layer = base + i;
      }
    } else {
      final base = _entities.nextLayer;
      for (var i = 0; i < ordered.length; i++) {
        ordered[i].layer = base + i;
      }
    }

    folder.isBackground = value;
  }

  /// Збирає розсіяні [group]-сутності в один суцільний блок (у їхньому
  /// поточному відносному порядку), вставлений на місце НАЙВИЩОЇ з них —
  /// решта [topToBottom] лишається на своїх місцях у тому самому порядку.
  List<LevelEntity> _collectAsBlock(List<LevelEntity> topToBottom, Set<LevelEntity> group) {
    final block = topToBottom.where(group.contains).toList();
    final result = <LevelEntity>[];
    var inserted = false;
    for (final entity in topToBottom) {
      if (group.contains(entity)) {
        if (!inserted) {
          result.addAll(block);
          inserted = true;
        }
        continue;
      }
      result.add(entity);
    }
    return result;
  }
}
