import 'dart:math' as math;

import 'package:flame/components.dart' show Vector2;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:leyak_lvl_editor/code/di/injection.dart';
import 'package:leyak_lvl_editor/editor/audio/audio_asset_catalog.dart';
import 'package:leyak_lvl_editor/editor/audio/audio_texture_manager.dart';
import 'package:leyak_lvl_editor/editor/models/level_entity.dart';
import 'package:leyak_lvl_editor/editor/models/level_group.dart';
import 'package:leyak_lvl_editor/editor/models/shape_type.dart';
import 'package:leyak_lvl_editor/editor/rendering/shader_catalog.dart';
import 'package:leyak_lvl_editor/editor/state/scene_cubit.dart';
import 'package:leyak_lvl_editor/editor/state/scene_state.dart';
import 'package:leyak_lvl_editor/editor/video/video_asset_catalog.dart';

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
                builder: (context, state) => _buildContent(context, state.selected),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, List<LevelEntity> selected) {
    if (selected.isEmpty) {
      return const Text('No selection', style: TextStyle(color: Colors.white38));
    }

    final group = context.read<SceneCubit>().fullGroupSelectionOf(selected);
    if (group != null) {
      return _GroupEditor(group: group, memberCount: selected.length);
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
        _TransformFields(
          rotationRadians: transform.rotation,
          scale: transform.scale,
          onRotationChanged: (radians) =>
              context.read<SceneCubit>().setEntityRotation(entity, radians),
          onScaleChanged: (scale) => context.read<SceneCubit>().setEntityScale(entity, scale),
        ),
        _ShapeStyleFields(
          shapeType: entity.shapeType,
          cornerRadius: entity.shapeStyle.cornerRadius,
          lineThickness: entity.shapeStyle.lineThickness,
          onCornerRadiusChanged: (v) =>
              context.read<SceneCubit>().setEntityCornerRadius(entity, v),
          onLineThicknessChanged: (v) =>
              context.read<SceneCubit>().setEntityLineThickness(entity, v),
        ),
        const SizedBox(height: 12),
        if (entity.parts != null && entity.parts!.isNotEmpty)
          _PartsEditor(entity: entity)
        else ...[
          const Text('Color', style: TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 4),
          _ColorPickerButton(
            color: entity.visual.color,
            onColorPicked: (color) => context.read<SceneCubit>().setEntityColor(entity, color),
          ),
          const SizedBox(height: 4),
          _OpacitySlider(
            color: entity.visual.color,
            onChanged: (color) => context.read<SceneCubit>().setEntityColor(entity, color),
          ),
          const SizedBox(height: 8),
          const Text('Shader', style: TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 4),
          _ShaderPickerDropdown(
            shaderId: entity.visual.shaderId,
            onChanged: (id) => context.read<SceneCubit>().setEntityShader(entity, id),
          ),
          if (getIt<ShaderCatalog>().textureKindFor(entity.visual.shaderId) ==
              ShaderTextureKind.video) ...[
            const SizedBox(height: 4),
            _VideoAssetDropdown(
              videoPath: entity.visual.videoPath,
              onChanged: (path) => context.read<SceneCubit>().setEntityVideo(entity, path),
            ),
          ],
          if (getIt<ShaderCatalog>().textureKindFor(entity.visual.shaderId) ==
              ShaderTextureKind.audio) ...[
            const SizedBox(height: 4),
            const _AudioTrackDropdown(),
          ],
        ],
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
/// діалозі й застосовує вибір лише після підтвердження. Не прив'язаний до
/// конкретної сутності — використовується і для кольору цілої сутності
/// ([_EntityEditor]), і для кольору окремого [EntityPart] ([_PartsEditor]).
class _ColorPickerButton extends StatelessWidget {
  const _ColorPickerButton({required this.color, required this.onColorPicked, this.label = 'Change color'});

  final Color color;
  final ValueChanged<Color> onColorPicked;
  final String label;

  Future<void> _openPicker(BuildContext context) async {
    var pickedColor = color;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2A2A2A),
          title: const Text('Pick a color', style: TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: pickedColor,
              onColorChanged: (c) => pickedColor = c,
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
                onColorPicked(pickedColor);
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
              color: color,
              border: Border.all(color: Colors.white54),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }
}

/// Слайдер прозорості кольору — окремо від повного [ColorPicker], бо
/// прозорість об'єкта хочеться крутити швидко/пробно, не відкриваючи щоразу
/// повний діалог. Змінює лише альфа-канал, RGB лишає незмінним.
class _OpacitySlider extends StatelessWidget {
  const _OpacitySlider({required this.color, required this.onChanged});

  final Color color;
  final ValueChanged<Color> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(
          width: 46,
          child: Text('Opacity', style: TextStyle(color: Colors.white54, fontSize: 11)),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 2,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            ),
            child: Slider(
              value: color.a,
              onChanged: (v) => onChanged(color.withValues(alpha: v)),
            ),
          ),
        ),
        SizedBox(
          width: 32,
          child: Text(
            '${(color.a * 100).round()}%',
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ),
      ],
    );
  }
}

/// Список частин складеної (compound) сутності — по одному кольоровому
/// свотчу на [EntityPart], аналог редагування fill окремого `<rect>` в
/// SVG-групі. Показується в [_EntityEditor] замість одного цілісного
/// "Color" редактора, коли `entity.parts` непорожній.
class _PartsEditor extends StatelessWidget {
  const _PartsEditor({required this.entity});

  final LevelEntity entity;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SceneCubit>();
    final parts = entity.parts!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Parts (${parts.length})', style: const TextStyle(color: Colors.white54, fontSize: 12)),
        const SizedBox(height: 4),
        for (var i = 0; i < parts.length; i++) ...[
          Row(
            children: [
              Expanded(
                child: _ColorPickerButton(
                  color: parts[i].color,
                  label: 'Part $i',
                  onColorPicked: (color) => cubit.setPartColor(entity, i, color),
                ),
              ),
              const SizedBox(width: 6),
              _ShaderPickerDropdown(
                shaderId: parts[i].shaderId,
                onChanged: (id) => cubit.setPartShader(entity, i, id),
              ),
            ],
          ),
          _OpacitySlider(
            color: parts[i].color,
            onChanged: (color) => cubit.setPartColor(entity, i, color),
          ),
          if (getIt<ShaderCatalog>().textureKindFor(parts[i].shaderId) ==
              ShaderTextureKind.video) ...[
            const SizedBox(height: 4),
            _VideoAssetDropdown(
              videoPath: parts[i].videoPath,
              onChanged: (path) => cubit.setPartVideo(entity, i, path),
            ),
          ],
          if (getIt<ShaderCatalog>().textureKindFor(parts[i].shaderId) ==
              ShaderTextureKind.audio) ...[
            const SizedBox(height: 4),
            const _AudioTrackDropdown(),
          ],
          _ShapeStyleFields(
            shapeType: parts[i].shapeType,
            cornerRadius: parts[i].shapeStyle.cornerRadius,
            lineThickness: parts[i].shapeStyle.lineThickness,
            onCornerRadiusChanged: (v) => cubit.setPartCornerRadius(entity, i, v),
            onLineThicknessChanged: (v) => cubit.setPartLineThickness(entity, i, v),
          ),
          if (i != parts.length - 1) const SizedBox(height: 6),
        ],
      ],
    );
  }
}

/// Поле для параметрів форми, специфічних для конкретного [ShapeType] —
/// радіус заокруглення (тільки прямокутник) чи товщина лінії (тільки
/// лінія). Для решти форм не показує нічого — не всі форми мають такі
/// параметри.
class _ShapeStyleFields extends StatelessWidget {
  const _ShapeStyleFields({
    required this.shapeType,
    required this.cornerRadius,
    required this.lineThickness,
    required this.onCornerRadiusChanged,
    required this.onLineThicknessChanged,
  });

  final ShapeType shapeType;
  final double cornerRadius;
  final double lineThickness;
  final ValueChanged<double> onCornerRadiusChanged;
  final ValueChanged<double> onLineThicknessChanged;

  @override
  Widget build(BuildContext context) {
    if (shapeType == ShapeType.rectangle) {
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Corner radius', style: TextStyle(color: Colors.white54, fontSize: 12)),
            const SizedBox(height: 4),
            _NumberField(value: cornerRadius, onChanged: onCornerRadiusChanged),
          ],
        ),
      );
    }
    if (shapeType == ShapeType.line) {
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Line thickness', style: TextStyle(color: Colors.white54, fontSize: 12)),
            const SizedBox(height: 4),
            _NumberField(value: lineThickness, onChanged: onLineThicknessChanged),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }
}

/// Дропдаун вибору кастомного шейдера з [ShaderCatalog] — `None` знімає
/// шейдер і повертає звичайну заливку суцільним кольором.
class _ShaderPickerDropdown extends StatelessWidget {
  const _ShaderPickerDropdown({required this.shaderId, required this.onChanged});

  final String? shaderId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final options = getIt<ShaderCatalog>().availableShaderIds;
    return DropdownButton<String?>(
      value: shaderId,
      isDense: true,
      dropdownColor: const Color(0xFF2A2A2A),
      style: const TextStyle(color: Colors.white, fontSize: 12),
      underline: const SizedBox.shrink(),
      items: [
        const DropdownMenuItem<String?>(value: null, child: Text('None')),
        for (final id in options) DropdownMenuItem<String?>(value: id, child: Text(id)),
      ],
      onChanged: onChanged,
    );
  }
}

/// Дропдаун вибору відео для шейдера, що потребує відео-текстури (див.
/// [ShaderCatalog.textureKindFor]) — показується умовно, поруч із
/// [_ShaderPickerDropdown]. Навмисно НЕ дає обирати довільний файл з диску
/// (system file picker під macOS App Sandbox — зайвий головний біль з
/// entitlements) — лише те, що реально вкладено в застосунок як asset,
/// див. [VideoAssetCatalog]. Кадри поточного вибору подаються в шейдер
/// через [VideoTextureManager]/[VideoTextureHost].
class _VideoAssetDropdown extends StatelessWidget {
  const _VideoAssetDropdown({required this.videoPath, required this.onChanged});

  final String? videoPath;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final options = getIt<VideoAssetCatalog>().availablePaths;

    if (options.isEmpty) {
      return const Text(
        'No videos in assets/videos/',
        style: TextStyle(color: Colors.white38, fontSize: 11),
      );
    }

    return DropdownButton<String?>(
      value: options.contains(videoPath) ? videoPath : null,
      isDense: true,
      isExpanded: true,
      dropdownColor: const Color(0xFF2A2A2A),
      style: const TextStyle(color: Colors.white, fontSize: 12),
      underline: const SizedBox.shrink(),
      hint: const Text('Choose video…', style: TextStyle(color: Colors.white38, fontSize: 11)),
      items: [
        const DropdownMenuItem<String?>(value: null, child: Text('None')),
        for (final path in options)
          DropdownMenuItem<String?>(
            value: path,
            child: Text(path.split('/').last, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: onChanged,
    );
  }
}

/// Дропдаун вибору музичного треку для шейдера, що потребує аудіо-текстури
/// (див. [ShaderCatalog.textureKindFor]) — показується умовно, поруч із
/// [_ShaderPickerDropdown], тим самим способом, що й [_VideoAssetDropdown].
/// На відміну від відео (окремий файл на кожну частину/сутність), трек тут
/// один спільний на всю сцену — тож дропдаун керує напряму
/// [AudioTextureManager] через [getIt], а не через [SceneCubit]: який саме
/// об'єкт/частина зараз показує цей дропдаун, впливає лише на те, чи він
/// видимий, не на те, який трек грає.
class _AudioTrackDropdown extends StatelessWidget {
  const _AudioTrackDropdown();

  @override
  Widget build(BuildContext context) {
    final manager = getIt<AudioTextureManager>();
    final options = getIt<AudioAssetCatalog>().availablePaths;

    if (options.isEmpty) {
      return const Text(
        'No tracks in assets/audio/',
        style: TextStyle(color: Colors.white38, fontSize: 11),
      );
    }

    return ValueListenableBuilder<String?>(
      valueListenable: manager.currentPath,
      builder: (context, currentPath, _) {
        return DropdownButton<String?>(
          value: options.contains(currentPath) ? currentPath : null,
          isDense: true,
          isExpanded: true,
          dropdownColor: const Color(0xFF2A2A2A),
          style: const TextStyle(color: Colors.white, fontSize: 12),
          underline: const SizedBox.shrink(),
          hint: const Text('Choose track…', style: TextStyle(color: Colors.white38, fontSize: 11)),
          items: [
            const DropdownMenuItem<String?>(value: null, child: Text('None')),
            for (final path in options)
              DropdownMenuItem<String?>(
                value: path,
                child: Text(path.split('/').last, overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: (path) => path == null ? manager.stop() : manager.play(path),
        );
      },
    );
  }
}

/// Редактор постійної групи — та сама пара обертання/масштаб, що й для
/// однієї сутності, але прив'язана до [LevelGroup]. Показується в
/// Inspector замість "N shapes selected", коли виділення — рівно повний
/// склад однієї групи (див. [SceneCubit.fullGroupSelectionOf]).
class _GroupEditor extends StatelessWidget {
  const _GroupEditor({required this.group, required this.memberCount});

  final LevelGroup group;
  final int memberCount;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SceneCubit>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PropertyRow('group', '$memberCount shapes'),
        const SizedBox(height: 12),
        _TransformFields(
          rotationRadians: group.rotation,
          scale: group.scale,
          onRotationChanged: (radians) => cubit.setGroupRotation(group, radians),
          onScaleChanged: (scale) => cubit.setGroupScale(group, scale),
        ),
      ],
    );
  }
}

/// Пара полів "обертання (у градусах) + масштаб X/Y", спільна для
/// [_EntityEditor] і [_GroupEditor]. Значення можуть змінюватись ззовні
/// (перетягуванням гізмо-хендлів на канвасі), тому поля введення —
/// [_NumberField], а не звичайний [TextField].
class _TransformFields extends StatelessWidget {
  const _TransformFields({
    required this.rotationRadians,
    required this.scale,
    required this.onRotationChanged,
    required this.onScaleChanged,
  });

  final double rotationRadians;
  final Vector2 scale;
  final ValueChanged<double> onRotationChanged;
  final ValueChanged<Vector2> onScaleChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Rotation (°)', style: TextStyle(color: Colors.white54, fontSize: 12)),
        const SizedBox(height: 4),
        _NumberField(
          value: rotationRadians * 180 / math.pi,
          onChanged: (degrees) => onRotationChanged(degrees * math.pi / 180),
        ),
        const SizedBox(height: 8),
        const Text('Scale', style: TextStyle(color: Colors.white54, fontSize: 12)),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: _NumberField(
                value: scale.x,
                onChanged: (v) => onScaleChanged(Vector2(v, scale.y)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _NumberField(
                value: scale.y,
                onChanged: (v) => onScaleChanged(Vector2(scale.x, v)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Текстове поле для числового значення, яке може мінятись і ззовні
/// (drag гізмо). Показане значення оновлюється з [value] лише коли поле
/// не в фокусі — інакше введення користувача перезаписувалось би щокадру.
class _NumberField extends StatefulWidget {
  const _NumberField({required this.value, required this.onChanged});

  final double value;
  final ValueChanged<double> onChanged;

  @override
  State<_NumberField> createState() => _NumberFieldState();
}

class _NumberFieldState extends State<_NumberField> {
  late final TextEditingController _controller = TextEditingController(
    text: _format(widget.value),
  );
  final FocusNode _focusNode = FocusNode();

  String _format(double value) => value.toStringAsFixed(1);

  @override
  void didUpdateWidget(covariant _NumberField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_focusNode.hasFocus && oldWidget.value != widget.value) {
      _controller.text = _format(widget.value);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit() {
    final parsed = double.tryParse(_controller.text);
    if (parsed != null) widget.onChanged(parsed);
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      style: const TextStyle(color: Colors.white, fontSize: 12),
      decoration: const InputDecoration(
        isDense: true,
        contentPadding: EdgeInsets.symmetric(vertical: 4, horizontal: 6),
        border: OutlineInputBorder(),
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
      onSubmitted: (_) => _submit(),
      onEditingComplete: _submit,
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
