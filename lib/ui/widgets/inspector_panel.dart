import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:leyak_lvl_editor/editor/models/level_entity.dart';
import 'package:leyak_lvl_editor/editor/state/scene_cubit.dart';
import 'package:leyak_lvl_editor/editor/state/scene_state.dart';

/// Панель властивостей вибраної сутності. Єдине місце, де можна змінити
/// `customProperties`/колір об'єкта — нових пресетів чи типів немає,
/// кожен об'єкт налаштовується індивідуально після створення.
/// Дані й мутації йдуть через [SceneCubit] — про [MainEditor]/Flame
/// нічого не знає.
class InspectorPanel extends StatelessWidget {
  const InspectorPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topRight,
      child: Container(
        width: 240,
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Inspector',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Divider(height: 1, color: Colors.white24),
              const SizedBox(height: 8),
              BlocBuilder<SceneCubit, SceneState>(
                builder: (context, state) => _buildContent(state.selected),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(List<LevelEntity> selected) {
    if (selected.isEmpty) {
      return const Text('No selection', style: TextStyle(color: Colors.white38));
    }
    if (selected.length > 1) {
      return Text(
        '${selected.length} shapes selected',
        style: const TextStyle(color: Colors.white70),
      );
    }
    return _EntityEditor(entity: selected.single);
  }
}

class _EntityEditor extends StatelessWidget {
  const _EntityEditor({required this.entity});

  final LevelEntity entity;

  @override
  Widget build(BuildContext context) {
    final transform = entity.transform;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PropertyRow('id', entity.id),
        _PropertyRow(
          'position',
          '${transform.position.x.toInt()}, ${transform.position.y.toInt()}',
        ),
        _PropertyRow('size', '${transform.size.x.toInt()} x ${transform.size.y.toInt()}'),
        const SizedBox(height: 12),
        const Text('Color', style: TextStyle(color: Colors.white54, fontSize: 12)),
        const SizedBox(height: 4),
        _ColorPickerButton(entity: entity),
        if (entity.customProperties.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Text('customProperties', style: TextStyle(color: Colors.white54, fontSize: 12)),
          for (final key in entity.customProperties.keys.toList())
            _buildPropertyEditor(context, key, entity.customProperties[key]),
        ],
      ],
    );
  }

  Widget _buildPropertyEditor(BuildContext context, String key, dynamic value) {
    if (value is bool) {
      return _BoolPropertyRow(
        label: key,
        value: value,
        onChanged: (newValue) =>
            context.read<SceneCubit>().setEntityProperty(entity, key, newValue),
      );
    }
    return _PropertyRow(key, '$value');
  }
}

/// Відкриває повноцінний [ColorPicker] (HSV-колесо + RGB/HEX-поля) у
/// діалозі й застосовує вибір лише після підтвердження.
class _ColorPickerButton extends StatelessWidget {
  const _ColorPickerButton({required this.entity});

  final LevelEntity entity;

  Future<void> _openPicker(BuildContext context) async {
    final cubit = context.read<SceneCubit>();
    var pickedColor = entity.visual.color;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2A2A2A),
          title: const Text('Pick a color', style: TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: pickedColor,
              onColorChanged: (color) => pickedColor = color,
              enableAlpha: true,
              displayThumbColor: true,
              labelTypes: const [ColorLabelType.rgb, ColorLabelType.hsv, ColorLabelType.hex],
              pickerAreaHeightPercent: 0.7,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                cubit.setEntityColor(entity, pickedColor);
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Select'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _openPicker(context),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: entity.visual.color,
              border: Border.all(color: Colors.white54),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          const Text('Change color', style: TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }
}

class _BoolPropertyRow extends StatelessWidget {
  const _BoolPropertyRow({required this.label, required this.value, required this.onChanged});

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Checkbox(
              value: value,
              onChanged: (v) => onChanged(v ?? false),
              side: const BorderSide(color: Colors.white54),
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _PropertyRow extends StatelessWidget {
  const _PropertyRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
