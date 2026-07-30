#include <flutter/runtime_effect.glsl>

// Screen-space chromatic aberration — розсуває вибірку R/B каналів від
// уже готового кадру (uTexture), сильніше ближче до країв екрана
// (класичний "лінзовий" ефект). Як і fx_shockwave.frag — не per-object
// шейдер: без premultiplied alpha, альфа береться напряму з джерела.
uniform vec2 uSize;
uniform sampler2D uTexture;
uniform vec2 uCenter;    // нормалізований 0..1 центр, від якого росте зсув
uniform float uStrength; // 0..1 — максимальний зсув каналів на краю екрана

out vec4 fragColor;

void main() {
    vec2 uv = FlutterFragCoord().xy / uSize;
    vec2 dir = uv - uCenter;
    vec2 offset = dir * uStrength * 0.05;

    float r = texture(uTexture, uv - offset).r;
    float g = texture(uTexture, uv).g;
    float b = texture(uTexture, uv + offset).b;
    float a = texture(uTexture, uv).a;

    fragColor = vec4(r, g, b, a);
}
