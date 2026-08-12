import 'package:flutter_test/flutter_test.dart';
import 'package:leyak_lvl_editor/editor/rendering/shader_catalog.dart';

void main() {
  late ShaderCatalog catalog;

  setUp(() {
    catalog = ShaderCatalog();
  });

  test('availableShaderIds lists every registered shader', () {
    expect(
      catalog.availableShaderIds,
      containsAll(['blurry_glass', 'halftone_triangle', 'warp_fbm', 'galaxy', 'ring_glow']),
    );
  });

  group('textureKindFor', () {
    test('returns none for a shader that needs no texture', () {
      expect(catalog.textureKindFor('blurry_glass'), ShaderTextureKind.none);
    });

    test('returns video for a shader that samples video frames', () {
      expect(catalog.textureKindFor('halftone_triangle'), ShaderTextureKind.video);
    });

    test('returns audio for a shader that samples the audio spectrum', () {
      expect(catalog.textureKindFor('galaxy'), ShaderTextureKind.audio);
    });

    test('returns none for an unknown or null shader id', () {
      expect(catalog.textureKindFor('nonexistent'), ShaderTextureKind.none);
      expect(catalog.textureKindFor(null), ShaderTextureKind.none);
    });
  });

  group('needsTime', () {
    test('is true for time-animated shaders', () {
      expect(catalog.needsTime('warp_fbm'), isTrue);
      expect(catalog.needsTime('galaxy'), isTrue);
    });

    test('is false for static shaders', () {
      expect(catalog.needsTime('blurry_glass'), isFalse);
    });

    test('is false for an unknown or null shader id', () {
      expect(catalog.needsTime('nonexistent'), isFalse);
      expect(catalog.needsTime(null), isFalse);
    });
  });

  group('paramsFor', () {
    test('returns the configured params for ring_glow', () {
      final params = catalog.paramsFor('ring_glow');

      expect(params.map((p) => p.key), ['color', 'width']);
    });

    test('returns an empty list for a shader with no configurable params', () {
      expect(catalog.paramsFor('blurry_glass'), isEmpty);
    });

    test('returns an empty list for an unknown or null shader id', () {
      expect(catalog.paramsFor('nonexistent'), isEmpty);
      expect(catalog.paramsFor(null), isEmpty);
    });
  });

  group('renderModeFor', () {
    test('is glowOutline for ring_glow', () {
      expect(catalog.renderModeFor('ring_glow'), ShaderRenderMode.glowOutline);
    });

    test('is fragment for a normal .frag-backed shader', () {
      expect(catalog.renderModeFor('blurry_glass'), ShaderRenderMode.fragment);
    });

    test('defaults to fragment for an unknown or null shader id', () {
      expect(catalog.renderModeFor('nonexistent'), ShaderRenderMode.fragment);
      expect(catalog.renderModeFor(null), ShaderRenderMode.fragment);
    });
  });

  group('shaderFor', () {
    test('returns null when the id is null', () {
      expect(catalog.shaderFor(null), isNull);
    });

    test('returns null before load() has populated the program cache', () {
      expect(catalog.shaderFor('blurry_glass'), isNull);
    });
  });

  test('ShaderDefinition asserts an assetPath is provided in fragment mode', () {
    expect(
      () => ShaderDefinition(renderMode: ShaderRenderMode.fragment),
      throwsA(isA<AssertionError>()),
    );
  });
}
