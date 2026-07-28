import 'package:flutter/material.dart';

class VisualData {
  String? spritePath;
  String? shaderId;

  /// Шлях до відеофайлу для шейдерів, що потребують текстури — див.
  /// [EntityPart.videoPath].
  String? videoPath;
  Color color;

  VisualData({this.spritePath, this.shaderId, this.videoPath, this.color = Colors.grey});
}
