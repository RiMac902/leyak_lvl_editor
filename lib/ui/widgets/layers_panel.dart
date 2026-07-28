import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:leyak_lvl_editor/editor/models/level_entity.dart';
import 'package:leyak_lvl_editor/editor/state/scene_cubit.dart';
import 'package:leyak_lvl_editor/editor/state/scene_state.dart';

/// Список усіх намальованих сутностей сцени (аналог панелі "Layers").
/// Лише перегляд — не змінює жодних даних, підсвічує виділені сутності.
/// Дані читає з [SceneCubit] через [BlocBuilder] — про [MainEditor]/Flame
/// нічого не знає.
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
                  final entities = state.entities.reversed.toList();
                  if (entities.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('No shapes yet', style: TextStyle(color: Colors.white38)),
                    );
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: entities.length,
                    itemBuilder: (context, index) {
                      final entity = entities[index];
                      return _LayerRow(
                        entity: entity,
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
  const _LayerRow({required this.entity, required this.isSelected});

  final LevelEntity entity;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isSelected ? Colors.white24 : Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
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
            icon: const Icon(Icons.delete_outline, size: 16, color: Colors.white54),
            constraints: const BoxConstraints(),
            padding: EdgeInsets.zero,
            splashRadius: 14,
            onPressed: () => context.read<SceneCubit>().deleteEntity(entity),
          ),
        ],
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
