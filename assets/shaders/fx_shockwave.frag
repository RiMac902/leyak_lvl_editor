#include <flutter/runtime_effect.glsl>

// Screen-space shockwave — НЕ per-object шейдер (на відміну від решти
// .frag у цьому проєкті): uTexture тут — знімок уже відрендереного кадру
// (майбутній FBO/SnapshotComponent), а не текстура одного об'єкта, тож
// ефект просто спотворює вибірку з готового зображення, а не накладається
// на базовий колір форми. Тому й без premultiplied alpha — це прямий
// image-transform, альфа береться як є з джерела.
//
// uCenter/uProgress/uStrength навмисно НЕ анімуються самим шейдером —
// їх обчислює й "eases" зовнішній тригер-менеджер (Dart), шейдер лише
// рендерить один конкретний момент ефекту. uProgress — 0..1 за весь час
// дії ефекту (кільце розширюється від центру назовні), uStrength —
// поточна інтенсивність спотворення (менеджер може плавно її гасити
// наприкінці ефекту).
uniform vec2 uSize;
uniform sampler2D uTexture;
uniform vec2 uCenter;    // нормалізована 0..1 позиція епіцентру на екрані
uniform float uProgress; // 0..1 — як далеко кільце пройшло від центру
uniform float uStrength; // 0..1 — сила спотворення

out vec4 fragColor;

void main() {
    vec2 uv = FlutterFragCoord().xy / uSize;
    vec2 toCenter = uv - uCenter;
    float dist = length(toCenter);

    const float ringWidth = 0.15;
    float ring = 1.0 - smoothstep(0.0, ringWidth, abs(dist - uProgress));
    float displacement = ring * uStrength * 0.1;

    vec2 direction = toCenter / max(dist, 1e-5);
    vec2 distortedUv = uv + direction * displacement;

    fragColor = texture(uTexture, distortedUv);
}
