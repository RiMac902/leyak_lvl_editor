import 'package:flutter/material.dart';
import 'package:leyak_lvl_editor/editor/models/entity_part.dart';
import 'package:leyak_lvl_editor/editor/models/shape_style.dart';
import 'package:leyak_lvl_editor/editor/models/shape_type.dart';
import 'package:leyak_lvl_editor/editor/models/transform_data.dart';
import 'package:leyak_lvl_editor/editor/models/visual_data.dart';

/// Абстрактна фігура сцени. Її поведінка (solid, deadly, декор тощо)
/// визначається виключно [customProperties] — немає жорсткого типу.
///
/// [parts] — якщо непорожній, ця сутність "складена" (compound, як `<g>`
/// в SVG): замість одного суцільного прямокутника кольору [visual.color]
/// вона малює список [EntityPart] за їхніми відносними координатами й
/// власними кольорами. Це дозволяє об'єднати кілька колишніх сутностей в
/// одну (одну в репозиторії/дереві компонентів), не втрачаючи їхнього
/// індивідуального вигляду — див. [MergeService].
class LevelEntity {
  final String id;
  final TransformData transform;
  final VisualData visual;
  final Map<String, dynamic> customProperties;
  final List<EntityPart>? parts;

  int layer;
  String? groupId;

  /// Папка в Layers panel, до якої належить ця сутність — див.
  /// [LayerFolder]. Незалежна від [groupId]: сутність може бути одночасно
  /// в Ctrl+G групі й у папці шарів, або лише в одному з них, або в
  /// жодному.
  String? layerFolderId;

  bool isVisible;

  /// Форма, якою малюється сутність (коли [parts] порожній) — вписана в
  /// той самий bounding-box [transform.position]/[transform.size], як і
  /// прямокутник раніше. Drag/hit-test/снепінг лишаються прямокутними
  /// незалежно від [shapeType] — див. [ShapeType].
  ShapeType shapeType;

  /// Додаткові параметри форми (радіус заокруглення, товщина й точки
  /// лінії) — див. [ShapeStyle].
  final ShapeStyle shapeStyle;

  /// Заблокована сутність не потрапляє в [EntityRepository.findAt]/
  /// [findWithin] — її не можна виділити кліком/marquee на канвасі, а отже
  /// й перемістити, видалити, згрупувати, дублювати чи об'єднати (усі ці
  /// дії працюють тільки з поточним виділенням). Малюється як завжди.
  bool isLocked;

  LevelEntity({
    required this.id,
    TransformData? transform,
    VisualData? visual,
    Map<String, dynamic>? customProperties,
    this.parts,
    this.layer = 0,
    this.groupId,
    this.layerFolderId,
    this.shapeType = ShapeType.rectangle,
    ShapeStyle? shapeStyle,
    this.isVisible = true,
    this.isLocked = false,
  }) : transform = transform ?? TransformData(),
       visual = visual ?? VisualData(),
       shapeStyle = shapeStyle ?? ShapeStyle(),
       customProperties = customProperties ?? {};

  LevelEntity.create({
    Map<String, dynamic>? customProperties,
    Color? color,
    ShapeType shapeType = ShapeType.rectangle,
  }) : this(
         id: DateTime.now().millisecondsSinceEpoch.toString(),
         transform: TransformData(),
         visual: VisualData(color: color ?? Colors.grey),
         shapeType: shapeType,
         customProperties: customProperties == null
             ? {}
             : Map<String, dynamic>.from(customProperties),
       );
}
