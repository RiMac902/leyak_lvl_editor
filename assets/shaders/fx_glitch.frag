#include <flutter/runtime_effect.glsl>

// Screen-space digital glitch — горизонтальні "смуги" кадру випадково
// зсуваються по X (per-slice random, оновлюється уTime), плюс легкий
// хроматичний розпад на зсунутій вибірці. uTime тут анімує саме тремтіння
// смуг, доки ефект активний — на відміну від uProgress у fx_shockwave.frag,
// бо глітч не має єдиного "напрямку" прогресу, лише постійне мерехтіння,
// поки тригер його тримає увімкненим.
uniform vec2 uSize;
uniform sampler2D uTexture;
uniform float uTime;
uniform float uStrength; // 0..1 — інтенсивність зсуву/розпаду

out vec4 fragColor;

float rand(float x) {
    return fract(sin(x * 12.9898) * 43758.5453);
}

void main() {
    vec2 uv = FlutterFragCoord().xy / uSize;

    const float sliceHeight = 0.06;
    float sliceIndex = floor(uv.y / sliceHeight + uTime * 6.0);
    float sliceNoise = rand(sliceIndex);
    // step(0.7, ...): лише частина смуг "стрибає" в кожен момент — суцільний
    // зсув усіх смуг одразу виглядав би як рівномірна хвиля, а не глітч.
    float offset = (sliceNoise - 0.5) * uStrength * 0.1 * step(0.7, sliceNoise);

    vec2 shiftedUv = vec2(uv.x + offset, uv.y);
    float aberration = uStrength * 0.01;

    float r = texture(uTexture, shiftedUv + vec2(aberration, 0.0)).r;
    float g = texture(uTexture, shiftedUv).g;
    float b = texture(uTexture, shiftedUv - vec2(aberration, 0.0)).b;
    float a = texture(uTexture, uv).a;

    fragColor = vec4(r, g, b, a);
}
