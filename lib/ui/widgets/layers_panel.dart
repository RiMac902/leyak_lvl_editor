import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:leyak_lvl_editor/editor/models/level_entity.dart';
import 'package:leyak_lvl_editor/editor/state/scene_cubit.dart';
import 'package:leyak_lvl_editor/editor/state/scene_state.dart';

/// Список усіх намальованих сутностей сцени (аналог панелі "Layers").
/// Клік по рядку виділяє сутність, перетягування за іконку зліва (drag
/// handle) міняє z-порядок ([SceneCubit.reorderLayers]). Дані читає з
/// [SceneCubit] через [BlocBuilder] — про [MainEditor]/Flame нічого не знає.
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(12, 10, 12, 4),
              child: Text(
                'Layers',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(height: 1, color: Colors.white24),
            Flexible(
              child: BlocBuilder<SceneCubit, SceneState>(
                builder: (context, state) {
                  // state.entities — sortedByLayer (зростання); reversed:
                  // індекс 0 — найвищий шар, тобто те, що малюється зверху
                  // й показується на початку списку.
                  final entities = state.entities.reversed.toList();
                  if (entities.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('No shapes yet', style: TextStyle(color: Colors.white38)),
                    );
                  }
                  return ReorderableListView.builder(
                    shrinkWrap: true,
                    buildDefaultDragHandles: false,
                    itemCount: entities.length,
                    onReorderItem: (oldIndex, newIndex) {
                      final reordered = List<LevelEntity>.of(entities);
                      final moved = reordered.removeAt(oldIndex);
                      reordered.insert(newIndex, moved);
                      context.read<SceneCubit>().reorderLayers(reordered);
                    },
                    itemBuilder: (context, index) {
                      final entity = entities[index];
                      return _LayerRow(
                        key: ValueKey(entity.id),
                        entity: entity,
                        index: index,
                        isSelected: state.selected.contains(entity),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LayerRow extends StatelessWidget {
  const _LayerRow({
    required super.key,
    required this.entity,
    required this.index,
    required this.isSelected,
  });

  final LevelEntity entity;
  final int index;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: entity.isLocked ? 0.5 : 1.0,
      child: InkWell(
        onTap: entity.isLocked ? null : () => context.read<SceneCubit>().selectEntity(entity),
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
