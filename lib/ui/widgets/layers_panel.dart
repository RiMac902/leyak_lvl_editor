import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:leyak_lvl_editor/editor/models/layer_folder.dart';
import 'package:leyak_lvl_editor/editor/models/level_entity.dart';
import 'package:leyak_lvl_editor/editor/state/scene_cubit.dart';
import 'package:leyak_lvl_editor/editor/state/scene_state.dart';

/// Один верхньорівневий рядок Layers panel — або гола сутність, або папка
/// (з її поточними членами, "живо" зібраними з [LevelEntity.layerFolderId] —
/// див. [_buildEntries]). Не сама сутність/[LayerFolder] — проміжна
/// в'юмодель тільки для побудови списку рядків.
sealed class _TopLevelEntry {
  String get key;
}

class _EntityEntry extends _TopLevelEntry {
  _EntityEntry(this.entity);
  final LevelEntity entity;
  @override
  String get key => entity.id;
}

class _FolderEntry extends _TopLevelEntry {
  _FolderEntry(this.folder, this.members);
  final LayerFolder folder;
  final List<LevelEntity> members;
  @override
  String get key => 'folder_${folder.id}';
}

/// Список усіх намальованих сутностей сцени (аналог панелі "Layers"),
/// згрупованих у папки ([LayerFolder]) там, де вони призначені. Клік по
/// рядку виділяє сутність, перетягування за іконку зліва (drag handle)
/// міняє z-порядок ([SceneCubit.reorderLayers]). Дані читає з [SceneCubit]
/// через [BlocBuilder] — про [MainEditor]/Flame нічого не знає.
///
/// Папка — ОДИН рядок у зовнішньому [ReorderableListView] незалежно від
/// того, розгорнута вона чи ні: перетягування за її іконку рухає весь
/// блок членів разом. Члени розгорнутої папки мають ОКРЕМИЙ, вкладений
/// [ReorderableListView] — так перетягування дитини міняє порядок лише
/// всередині своєї папки, а перетягування заголовка папки рухає її як
/// єдине ціле серед верхньорівневих сусідів, без ручної математики
/// індексів "де в плоскому списку закінчується блок папки".
class LayersPanel extends StatelessWidget {
  const LayersPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topLeft,
      child: Container(
        width: 220,
        margin: const EdgeInsets.all(16),
        constraints: const BoxConstraints(maxHeight: 400),
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(8),
        ),
        child: BlocBuilder<SceneCubit, SceneState>(
          builder: (context, state) {
            final entries = _buildEntries(state);
            final visibleOrder = _visibleOrder(entries);
            final canGroup =
                state.selected.length >= 2 &&
                state.selected.every((e) => e.layerFolderId == null);

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 4, 4),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Layers',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.create_new_folder_outlined,
                          size: 18,
                          color: Colors.white54,
                        ),
                        tooltip: 'Group into folder',
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                        splashRadius: 14,
                        onPressed: canGroup
                            ? () =>
                                  context.read<SceneCubit>().createLayerFolder(state.selected, 'Group')
                            : null,
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Colors.white24),
                Flexible(
                  child: entries.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: Text('No shapes yet', style: TextStyle(color: Colors.white38)),
                        )
                      : ReorderableListView.builder(
                          shrinkWrap: true,
                          buildDefaultDragHandles: false,
                          itemCount: entries.length,
                          onReorderItem: (oldIndex, newIndex) {
                            final reordered = List<_TopLevelEntry>.of(entries);
                            final moved = reordered.removeAt(oldIndex);
                            reordered.insert(newIndex, moved);
                            context.read<SceneCubit>().reorderLayers(_flatten(reordered));
                          },
                          itemBuilder: (context, index) {
                            final entry = entries[index];
                            return switch (entry) {
                              _EntityEntry(:final entity) => _LayerRow(
                                key: ValueKey(entry.key),
                                entity: entity,
                                index: index,
                                isSelected: state.selected.contains(entity),
                                visibleOrder: visibleOrder,
                              ),
                              _FolderEntry(:final folder, :final members) => _FolderRow(
                                key: ValueKey(entry.key),
                                folder: folder,
                                members: members,
                                index: index,
                                selected: state.selected,
                                visibleOrder: visibleOrder,
                                onReorderMembers: (newMembers) {
                                  final newEntries = [
                                    for (final e in entries)
                                      if (e is _FolderEntry && e.folder.id == folder.id)
                                        _FolderEntry(folder, newMembers)
                                      else
                                        e,
                                  ];
                                  context.read<SceneCubit>().reorderLayers(_flatten(newEntries));
                                },
                              ),
                            };
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Будує верхньорівневі рядки з [state.entities] (sortedByLayer; reversed —
/// індекс 0 найвищий шар, як і показує список) — сутність без
/// [LevelEntity.layerFolderId] стає [_EntityEntry], перша сутність із
/// заданим `layerFolderId` збирає ВСІХ сутностей з тим самим id (де б вони
/// не були — самозагоюється, якщо суцільність колись розпалась) в один
/// [_FolderEntry], решта членів пропускається як уже враховані.
List<_TopLevelEntry> _buildEntries(SceneState state) {
  final topmostFirst = state.entities.reversed.toList();
  final consumed = <String>{};
  final entries = <_TopLevelEntry>[];

  for (final entity in topmostFirst) {
    if (consumed.contains(entity.id)) continue;

    final folderId = entity.layerFolderId;
    if (folderId == null) {
      entries.add(_EntityEntry(entity));
      consumed.add(entity.id);
      continue;
    }

    final folder = state.folders.firstWhere((f) => f.id == folderId);
    final members = topmostFirst.where((e) => e.layerFolderId == folderId).toList();
    for (final member in members) {
      consumed.add(member.id);
    }
    entries.add(_FolderEntry(folder, members));
  }

  return entries;
}

/// Розгортає рядки назад у плоский список сутностей (папка → її члени, у
/// їхньому поточному відносному порядку) — саме такий список очікує
/// [SceneCubit.reorderLayers].
List<LevelEntity> _flatten(List<_TopLevelEntry> entries) {
  final result = <LevelEntity>[];
  for (final entry in entries) {
    switch (entry) {
      case _EntityEntry(:final entity):
        result.add(entity);
      case _FolderEntry(:final members):
        result.addAll(members);
    }
  }
  return result;
}

/// Той самий плоский список, що бачить користувач, — на відміну від
/// [_flatten], члени ЗГОРНУТОЇ папки сюди не потрапляють (вони невидимі).
/// Потрібен для shift-кліку ([SceneCubit.selectRangeInLayers]) — діапазон
/// має рахуватись за видимими рядками, а не за "справжнім" z-порядком.
List<LevelEntity> _visibleOrder(List<_TopLevelEntry> entries) {
  final result = <LevelEntity>[];
  for (final entry in entries) {
    switch (entry) {
      case _EntityEntry(:final entity):
        result.add(entity);
      case _FolderEntry(:final folder, :final members):
        if (folder.isExpanded) result.addAll(members);
    }
  }
  return result;
}

class _LayerRow extends StatelessWidget {
  const _LayerRow({
    required super.key,
    required this.entity,
    required this.index,
    required this.isSelected,
    required this.visibleOrder,
  });

  final LevelEntity entity;
  final int index;
  final bool isSelected;

  /// Видимий порядок рядків панелі (папки, що згорнуті, не додають своїх
  /// членів) — потрібен лише для shift-кліку, щоб порахувати діапазон між
  /// якорем і цим рядком. Див. [SceneCubit.selectRangeInLayers].
  final List<LevelEntity> visibleOrder;

  void _handleTap(BuildContext context) {
    final cubit = context.read<SceneCubit>();
    if (HardwareKeyboard.instance.isShiftPressed) {
      cubit.selectRangeInLayers(visibleOrder, entity);
    } else {
      cubit.selectEntity(entity);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: entity.isLocked ? 0.5 : 1.0,
      child: InkWell(
        onTap: entity.isLocked ? null : () => _handleTap(context),
        child: Container(
          color: isSelected ? Colors.white24 : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            children: [
              ReorderableDragStartListener(
                index: index,
                child: const Padding(
                  padding: EdgeInsets.only(right: 6),
                  child: Icon(Icons.drag_indicator, size: 16, color: Colors.white38),
                ),
              ),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: entity.visual.color,
                  border: Border.all(color: Colors.white54),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Shape ${entity.id}',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
              if (entity.groupId != null) ...[
                _GroupBadge(groupId: entity.groupId!),
                const SizedBox(width: 6),
              ],
              IconButton(
                icon: Icon(
                  entity.isLocked ? Icons.lock : Icons.lock_open,
                  size: 16,
                  color: Colors.white54,
                ),
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
                splashRadius: 14,
                onPressed: () => context.read<SceneCubit>().toggleLock(entity),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 16, color: Colors.white54),
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
                splashRadius: 14,
                onPressed: entity.isLocked
                    ? null
                    : () => context.read<SceneCubit>().deleteEntity(entity),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Рядок папки: заголовок (drag handle, розгорнути/згорнути, назва —
/// подвійний тап перейменовує, кнопка розпустити) плюс, якщо розгорнута,
/// ОКРЕМИЙ вкладений [ReorderableListView] для [members] — перетягування
/// дитини викликає [onReorderMembers] з новим відносним порядком членів
/// ЦІЄЇ папки, а не чіпає жоден верхньорівневий рядок.
class _FolderRow extends StatelessWidget {
  const _FolderRow({
    required super.key,
    required this.folder,
    required this.members,
    required this.index,
    required this.selected,
    required this.visibleOrder,
    required this.onReorderMembers,
  });

  final LayerFolder folder;
  final List<LevelEntity> members;
  final int index;
  final List<LevelEntity> selected;
  final List<LevelEntity> visibleOrder;
  final ValueChanged<List<LevelEntity>> onReorderMembers;

  Future<void> _renameDialog(BuildContext context) async {
    final controller = TextEditingController(text: folder.name);
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2A2A2A),
          title: const Text('Rename folder', style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: const TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(controller.text),
              child: const Text('Rename'),
            ),
          ],
        );
      },
    );
    if (result != null && result.trim().isNotEmpty && context.mounted) {
      context.read<SceneCubit>().renameLayerFolder(folder.id, result.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            children: [
              ReorderableDragStartListener(
                index: index,
                child: const Padding(
                  padding: EdgeInsets.only(right: 6),
                  child: Icon(Icons.drag_indicator, size: 16, color: Colors.white38),
                ),
              ),
              InkWell(
                onTap: () => context.read<SceneCubit>().toggleFolderExpanded(folder.id),
                child: Icon(
                  folder.isExpanded ? Icons.expand_more : Icons.chevron_right,
                  size: 18,
                  color: Colors.white54,
                ),
              ),
              const SizedBox(width: 2),
              const Icon(Icons.folder, size: 14, color: Colors.amberAccent),
              const SizedBox(width: 6),
              Expanded(
                child: GestureDetector(
                  onDoubleTap: () => _renameDialog(context),
                  child: Text(
                    '${folder.name} (${members.length})',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.folder_off_outlined, size: 16, color: Colors.white54),
                tooltip: 'Ungroup',
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
                splashRadius: 14,
                onPressed: () => context.read<SceneCubit>().deleteLayerFolder(folder.id),
              ),
            ],
          ),
        ),
        if (folder.isExpanded)
          Padding(
            padding: const EdgeInsets.only(left: 20),
            child: ReorderableListView.builder(
              shrinkWrap: true,
              buildDefaultDragHandles: false,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: members.length,
              onReorderItem: (oldIndex, newIndex) {
                final reordered = List<LevelEntity>.of(members);
                final moved = reordered.removeAt(oldIndex);
                reordered.insert(newIndex, moved);
                onReorderMembers(reordered);
              },
              itemBuilder: (context, i) {
                final member = members[i];
                return _LayerRow(
                  key: ValueKey(member.id),
                  entity: member,
                  index: i,
                  isSelected: selected.contains(member),
                  visibleOrder: visibleOrder,
                );
              },
            ),
          ),
      ],
    );
  }
}

/// Значок постійної групи — колір визначається детерміновано з [groupId],
/// щоб у списку було видно, які фігури належать до однієї групи, а які —
/// до різних, без потреби показувати сам ідентифікатор.
class _GroupBadge extends StatelessWidget {
  const _GroupBadge({required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context) {
    final hue = (groupId.hashCode % 360).toDouble();
    return Tooltip(
      message: 'Group $groupId',
      child: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: HSLColor.fromAHSL(1, hue, 0.6, 0.5).toColor(),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
