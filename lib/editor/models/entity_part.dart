import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:leyak_lvl_editor/editor/models/shape_style.dart';
import 'package:leyak_lvl_editor/editor/models/shape_type.dart';

/// Один "шматок" складеної (compound) сутності — аналог одного `<rect>`
/// усередині `<g>` в SVG. [relativePosition]/[size] — у координатах сітки,
/// ВІДНОСНО [TransformData.position] батьківської [LevelEntity], а не
/// абсолютні світові координати.
class EntityPart {
  EntityPart({
    required this.relativePosition,
    required this.size,
    required this.color,
    this.shapeType = ShapeType.rectangle,
    ShapeStyle? shapeStyle,
    this.shaderId,
    this.videoPath,
    Map<String, Object>? shaderParams,
  }) : shapeStyle = shapeStyle ?? ShapeStyle(),
       shaderParams = shaderParams ?? {};

  Vector2 relativePosition;
  Vector2 size;
  Color color;
  ShapeType shapeType;
  final ShapeStyle shapeStyle;

  /// Кастомний фрагмент-шейдер для цієї частини — див. [ShaderCatalog].
  String? shaderId;

  /// Шлях до відеофайлу, кадри якого подаються як текстура шейдеру, що
  /// цього потребує ([ShaderCatalog.textureKindFor]). Ігнорується
  /// шейдерами, яким текстура не потрібна.
  String? videoPath;

  /// Значення налаштовуваних параметрів [shaderId] — див.
  /// [VisualData.shaderParams].
  Map<String, Object> shaderParams;
}
