import 'dart:ui';

/// Джерело текстури-семплера для шейдера, що її потребує: [video] — кадр з
/// [VideoTextureManager] (за шляхом з [EntityPart.videoPath]/
/// [VisualData.videoPath]), [audio] — спектр поточного треку з
/// [AudioTextureManager] (єдиний спільний на всю сцену, не per-entity).
enum ShaderTextureKind { none, video, audio }

/// Опис одного зареєстрованого шейдера: де лежить asset, яку текстуру йому
/// подавати (якщо взагалі), і чи потрібен йому час (uTime) для анімації.
class ShaderDefinition {
  const ShaderDefinition({
    required this.assetPath,
    this.textureKind = ShaderTextureKind.none,
    this.needsTime = false,
  });

  final String assetPath;
  final ShaderTextureKind textureKind;
  final bool needsTime;
}

/// Єдина відповідальність — завантажити всі доступні `.frag`-шейдери один
/// раз при старті застосунку і роздавати готові [FragmentShader] за їхнім
/// id (те саме [EntityPart.shaderId]/[VisualData.shaderId], яке раніше
/// нічого не робило). Дає [availableShaderIds] для UI-піка в Inspector.
class ShaderCatalog {
  static const Map<String, ShaderDefinition> _definitions = {
    'blurry_glass': ShaderDefinition(assetPath: 'assets/shaders/blurry_glass.frag'),
    'halftone_triangle': ShaderDefinition(
      assetPath: 'assets/shaders/halftone_triangle.frag',
      textureKind: ShaderTextureKind.video,
    ),
    'warp_fbm': ShaderDefinition(
      assetPath: 'assets/shaders/warp_fbm.frag',
      needsTime: true,
    ),
    'galaxy': ShaderDefinition(
      assetPath: 'assets/shaders/galaxy.frag',
      textureKind: ShaderTextureKind.audio,
      needsTime: true,
    ),
  };

  final Map<String, FragmentProgram> _programs = {};

  List<String> get availableShaderIds => _definitions.keys.toList(growable: false);

  ShaderTextureKind textureKindFor(String? shaderId) =>
      _definitions[shaderId]?.textureKind ?? ShaderTextureKind.none;

  bool needsTime(String? shaderId) => _definitions[shaderId]?.needsTime ?? false;

  Future<void> load() async {
    for (final entry in _definitions.entries) {
      _programs[entry.key] = await FragmentProgram.fromAsset(entry.value.assetPath);
    }
  }

  /// Створює свіжий [FragmentShader] для [shaderId], або `null`, якщо id
  /// не заданий чи невідомий. Створення інстансу з уже завантаженої
  /// [FragmentProgram] дешеве — новий інстанс на кожен виклик, щоб кілька
  /// об'єктів з однаковим шейдером не ділили один і той самий стан uniform.
  FragmentShader? shaderFor(String? shaderId) {
    if (shaderId == null) return null;
    return _programs[shaderId]?.fragmentShader();
  }
}
