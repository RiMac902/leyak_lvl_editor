import 'package:flutter/material.dart';
import 'package:leyak_lvl_editor/editor/models/entity_part.dart';
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
  bool isVisible;

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
    this.isVisible = true,
    this.isLocked = false,
  }) : transform = transform ?? TransformData(),
       visual = visual ?? VisualData(),
       customProperties = customProperties ?? {};

  LevelEntity.create({Map<String, dynamic>? customProperties, Color? color})
    : this(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        transform: TransformData(),
        visual: VisualData(color: color ?? Colors.grey),
        customProperties: customProperties == null
            ? {}
            : Map<String, dynamic>.from(customProperties),
      );
}
