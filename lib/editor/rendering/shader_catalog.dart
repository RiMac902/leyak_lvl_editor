import 'dart:ui';

/// Джерело текстури-семплера для шейдера, що її потребує: [video] — кадр з
/// [VideoTextureManager] (за шляхом з [EntityPart.videoPath]/
/// [VisualData.videoPath]), [audio] — спектр поточного треку з
/// [AudioTextureManager] (єдиний спільний на всю сцену, не per-entity).
enum ShaderTextureKind { none, video, audio }

/// Тип одного налаштовуваного параметра шейдера — визначає, яким
/// контролом Inspector його показує ([ColorPicker] чи числове поле) і як
/// саме [EntityComponent] кодує його значення в float-уніформи.
enum ShaderParamType { color, number }

/// Як саме [EntityComponent] рендерить ефект: [fragment] — справжній
/// `.frag`-шейдер (як усі інші зареєстровані ефекти), [glowOutline] —
/// НЕ шейдер, а обведення реального контуру фігури (той самий [Path], що
/// й базова заливка) з розмиттям, намальоване напряму на [Canvas]. Останнє
/// потрібне, бо довільний піксельний шейдер типу "кільце навколо центру"
/// не має уявлення про справжню форму об'єкта (прямокутник/еліпс/
/// трикутник/лінія з довільним cornerRadius) — обводити можна тільки те,
/// що вже намальовано як [Path].
enum ShaderRenderMode { fragment, glowOutline }

/// Опис одного параметра шейдера, який користувач може налаштувати в
/// Inspector per-object/per-part (напр. колір і товщина "контуру" для
/// `ring_glow`) — значення зберігаються в [VisualData.shaderParams]/
/// [EntityPart.shaderParams] за [key]. Порядок [ShaderDefinition.params]
/// має збігатись з порядком відповідних uniform'ів у `.frag`-файлі ПІСЛЯ
/// вбудованих (`uSize`, `uTexture`, `uTime`) — [EntityComponent] прив'язує
/// їх позиційно, той самий підхід, що вже використовується для тих трьох.
class ShaderParamSpec {
  const ShaderParamSpec({
    required this.key,
    required this.label,
    required this.type,
    this.defaultNumber = 0,
    this.defaultColor = const Color(0xFF00FFFF),
  });

  final String key;
  final String label;
  final ShaderParamType type;
  final double defaultNumber;
  final Color defaultColor;
}

/// Опис одного зареєстрованого шейдера: де лежить asset (лише для
/// [ShaderRenderMode.fragment] — ігнорується для [ShaderRenderMode.glowOutline]),
/// яку текстуру йому подавати (якщо взагалі), чи потрібен йому час (uTime)
/// для анімації, і які додаткові параметри користувач може налаштувати
/// ([params]).
class ShaderDefinition {
  const ShaderDefinition({
    this.assetPath,
    this.textureKind = ShaderTextureKind.none,
    this.needsTime = false,
    this.params = const [],
    this.renderMode = ShaderRenderMode.fragment,
  }) : assert(
         renderMode != ShaderRenderMode.fragment || assetPath != null,
         'fragment-режим потребує assetPath',
       );

  final String? assetPath;
  final ShaderTextureKind textureKind;
  final bool needsTime;
  final List<ShaderParamSpec> params;
  final ShaderRenderMode renderMode;
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
    'ring_glow': ShaderDefinition(
      renderMode: ShaderRenderMode.glowOutline,
      params: [
        ShaderParamSpec(
          key: 'color',
          label: 'Color',
          type: ShaderParamType.color,
          defaultColor: Color(0xFF18FFFF),
        ),
        ShaderParamSpec(key: 'width', label: 'Width', type: ShaderParamType.number, defaultNumber: 5.0),
      ],
    ),
  };

  final Map<String, FragmentProgram> _programs = {};

  List<String> get availableShaderIds => _definitions.keys.toList(growable: false);

  ShaderTextureKind textureKindFor(String? shaderId) =>
      _definitions[shaderId]?.textureKind ?? ShaderTextureKind.none;

  bool needsTime(String? shaderId) => _definitions[shaderId]?.needsTime ?? false;

  List<ShaderParamSpec> paramsFor(String? shaderId) => _definitions[shaderId]?.params ?? const [];

  ShaderRenderMode renderModeFor(String? shaderId) =>
      _definitions[shaderId]?.renderMode ?? ShaderRenderMode.fragment;

  Future<void> load() async {
    for (final entry in _definitions.entries) {
      final assetPath = entry.value.assetPath;
      if (entry.value.renderMode != ShaderRenderMode.fragment || assetPath == null) continue;
      _programs[entry.key] = await FragmentProgram.fromAsset(assetPath);
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
