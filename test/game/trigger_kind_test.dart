import 'package:flutter_test/flutter_test.dart';
import 'package:leyak_lvl_editor/editor/models/level_entity.dart';
import 'package:leyak_lvl_editor/game/trigger_kind.dart';

LevelEntity _entity(Map<String, dynamic> customProperties) =>
    LevelEntity(id: 'e', customProperties: customProperties);

/// Одна репрезентативна сутність на кожен [TriggerKind] — той самий набір
/// `customProperties`, який фактично розставляють інструменти редактора.
/// Ключується Map-ом (не switch), тож [classifyEntity] лишається єдиним
/// джерелом класифікаційної логіки: цей тест перевіряє РЕЗУЛЬТАТ, а не
/// дублює саму умову.
final Map<TriggerKind, LevelEntity> _representativeEntities = {
  TriggerKind.playerSpawn: _entity({'isPlayerSpawn': true}),
  TriggerKind.cameraNode: _entity({'isCameraNode': true}),
  TriggerKind.modeTrigger: _entity({'modeTrigger': 'wave'}),
  TriggerKind.speedTrigger: _entity({'speedTrigger': 'fast20'}),
  TriggerKind.finish: _entity({'isFinish': true}),
  TriggerKind.block: _entity({'isSolid': true}),
};

void main() {
  group('classifyEntity coverage', () {
    // Iterating TriggerKind.values (rather than one hardcoded test per
    // kind) means a newly-added TriggerKind with no entry in
    // _representativeEntities fails this loop immediately and loudly,
    // instead of the gap silently going untested.
    for (final kind in TriggerKind.values) {
      test('$kind has a representative entity that classifies as itself', () {
        final entity = _representativeEntities[kind];
        expect(entity, isNotNull, reason: 'No representative entity registered for $kind');

        expect(classifyEntity(entity!), kind);
      });
    }

    test('every TriggerKind value has exactly one representative entity', () {
      expect(_representativeEntities.keys.toSet(), TriggerKind.values.toSet());
    });
  });

  group('classifyEntity precedence', () {
    test('isPlayerSpawn takes priority over every other marker', () {
      final entity = _entity({
        'isPlayerSpawn': true,
        'isCameraNode': true,
        'modeTrigger': 'wave',
        'isFinish': true,
      });

      expect(classifyEntity(entity), TriggerKind.playerSpawn);
    });

    test('an unrecognized modeTrigger/speedTrigger string falls through to block', () {
      expect(classifyEntity(_entity({'modeTrigger': 'not_a_real_mode'})), TriggerKind.block);
      expect(classifyEntity(_entity({'speedTrigger': 'not_a_real_speed'})), TriggerKind.block);
    });

    test('a plain entity with no markers classifies as block', () {
      expect(classifyEntity(_entity({})), TriggerKind.block);
    });
  });
}
