import 'dart:ui';

import 'package:leyak_lvl_editor/code/di/injection.dart';
import 'package:leyak_lvl_editor/editor/audio/audio_texture_manager.dart';
import 'package:leyak_lvl_editor/editor/models/shape_style.dart';
import 'package:leyak_lvl_editor/editor/models/shape_type.dart';
import 'package:leyak_lvl_editor/editor/rendering/shader_catalog.dart';
import 'package:leyak_lvl_editor/editor/rendering/shape_path.dart';
import 'package:leyak_lvl_editor/editor/video/video_texture_manager.dart';

/// Малює форму [shapeType], вписану в [rect], суцільним кольором [color],
/// і якщо [shaderId] заданий і знайдений у [ShaderCatalog] — НАКЛАДАЄ
/// шейдер поверх неї (не замінює колір, а компонується над ним, як
/// напівпрозора плівка), кліпуючи його тим самим контуром форми, щоб
/// накладення не "вилазило" за межі не-прямокутних форм. Якщо шейдер
/// потребує текстури ([ShaderCatalog.textureKindFor]), бере поточний кадр
/// відео за [videoPath] з [VideoTextureManager] чи поточний спектр треку
/// з [AudioTextureManager] — якщо кадру ще нема (джерело не задане чи ще
/// завантажується), тихо пропускає шейдер і лишає просто базовий колір,
/// а не падає/блокується.
///
/// Єдине місце цієї логіки — і [EntityComponent] в редакторі, і
/// `LevelBlock` у playtest-рантаймі викликають САМЕ цю функцію, а не
/// дублюють її: інакше вигляд об'єкта в грі неминуче розійшовся б із тим,
/// що дизайнер бачив і налаштовував у редакторі (саме так і сталось,
/// перш ніж цю функцію винесли — `LevelBlock` малював лише суцільний
/// колір, без жодних шейдерів).
///
/// Шейдер рендериться в окреме off-screen зображення точного розміру
/// [rect], а не напряму на вже трансформований канвас — інакше координати
/// всередині шейдера ([FlutterFragCoord]) плавали б разом із позицією/
/// поворотом/зумом об'єкта замість того, щоб лишатись "прив'язаними" до
/// самої фігури. [elapsedTime] — секунди з моменту завантаження компонента,
/// що викликає цю функцію; подається як uTime шейдерам, яким потрібна
/// анімація ([ShaderCatalog.needsTime]).
void paintEntityVisual(
  Canvas canvas,
  Rect rect,
  Color color,
  String? shaderId,
  String? videoPath,
  Map<String, Object> shaderParams,
  ShapeType shapeType,
  ShapeStyle shapeStyle,
  double tileSize,
  double elapsedTime,
) {
  final path = shapePathFor(shapeType, rect, shapeStyle, tileSize);
  if (shapeType == ShapeType.path && !shapeStyle.pathClosed) {
    // Відкритий контур: суцільна заливка неявно замкнула б його прямою
    // лінією від останньої точки до першої (як завжди робить fill на
    // незамкненому Path) — замість цього обводимо сам контур, як товщину
    // лінії ([lineThickness], те саме поле, що й для ShapeType.line).
    // Замкнений контур — звичайний полігон, заливається як завжди.
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = shapeStyle.lineThickness * tileSize
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  } else {
    canvas.drawPath(path, Paint()..color = color);
  }

  final catalog = getIt<ShaderCatalog>();

  if (catalog.renderModeFor(shaderId) == ShaderRenderMode.glowOutline) {
    _drawGlowOutline(canvas, path, catalog.paramsFor(shaderId), shaderParams);
    return;
  }

  final shader = catalog.shaderFor(shaderId);
  if (shader == null) return;

  switch (catalog.textureKindFor(shaderId)) {
    case ShaderTextureKind.video:
      final frame = getIt<VideoTextureManager>().frameFor(videoPath);
      if (frame == null) return;
      shader.setImageSampler(0, frame);
    case ShaderTextureKind.audio:
      final frame = getIt<AudioTextureManager>().currentFrame;
      if (frame == null) return;
      shader.setImageSampler(0, frame);
    case ShaderTextureKind.none:
      break;
  }

  shader
    ..setFloat(0, rect.width)
    ..setFloat(1, rect.height);
  var nextFloatIndex = 2;
  if (catalog.needsTime(shaderId)) {
    shader.setFloat(nextFloatIndex++, elapsedTime);
  }
  for (final spec in catalog.paramsFor(shaderId)) {
    switch (spec.type) {
      case ShaderParamType.number:
        final value = (shaderParams[spec.key] as double?) ?? spec.defaultNumber;
        shader.setFloat(nextFloatIndex++, value);
      case ShaderParamType.color:
        final paramColor = (shaderParams[spec.key] as Color?) ?? spec.defaultColor;
        shader
          ..setFloat(nextFloatIndex++, paramColor.r)
          ..setFloat(nextFloatIndex++, paramColor.g)
          ..setFloat(nextFloatIndex++, paramColor.b);
    }
  }

  final image = _renderShaderImage(shader, rect.width, rect.height);
  if (image == null) return;

  canvas.save();
  canvas.clipPath(path);
  canvas.drawImageRect(
    image,
    Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
    rect,
    Paint(),
  );
  canvas.restore();
}

/// Малює світний контур точно вздовж [path] (той самий контур, яким
/// намальована базова заливка) — на відміну від фрагмент-шейдера, це не
/// піксельний ефект, а реальне обведення форми ([Canvas.drawPath] зі
/// [PaintingStyle.stroke] + розмиття), тож автоматично точно збігається з
/// силуетом будь-якого [ShapeType] (прямокутник з довільним cornerRadius,
/// еліпс, трикутник, лінія) без окремої геометрії на кожен тип фігури.
/// Колір/товщину бере з перших параметрів відповідного типу в [specs]
/// (для `ring_glow` — 'color'/'width'), незалежно від конкретних ключів.
void _drawGlowOutline(
  Canvas canvas,
  Path path,
  List<ShaderParamSpec> specs,
  Map<String, Object> shaderParams,
) {
  var color = const Color(0xFF18FFFF);
  var width = 5.0;
  for (final spec in specs) {
    switch (spec.type) {
      case ShaderParamType.color:
        color = (shaderParams[spec.key] as Color?) ?? spec.defaultColor;
      case ShaderParamType.number:
        width = (shaderParams[spec.key] as double?) ?? spec.defaultNumber;
    }
  }

  canvas.drawPath(
    path,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..color = color
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, width),
  );
}

Image? _renderShaderImage(FragmentShader shader, double width, double height) {
  final w = width.ceil();
  final h = height.ceil();
  if (w <= 0 || h <= 0) return null;

  final recorder = PictureRecorder();
  final recordCanvas = Canvas(recorder, Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()));
  recordCanvas.drawRect(Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()), Paint()..shader = shader);
  return recorder.endRecording().toImageSync(w, h);
}
