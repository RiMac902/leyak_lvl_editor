import 'package:flutter/material.dart';

class VisualData {
  String? spritePath;
  String? shaderId;

  /// Шлях до відеофайлу для шейдерів, що потребують текстури — див.
  /// [EntityPart.videoPath].
  String? videoPath;
  Color color;

  /// Значення налаштовуваних параметрів поточного шейдера ([shaderId]) —
  /// double для [ShaderParamType.number], [Color] для
  /// [ShaderParamType.color], за ключем [ShaderParamSpec.key]. Див.
  /// [EntityPart.shaderParams].
  Map<String, Object> shaderParams;

  VisualData({
    this.spritePath,
    this.shaderId,
    this.videoPath,
    this.color = Colors.grey,
    Map<String, Object>? shaderParams,
  }) : shaderParams = shaderParams ?? {};
}
