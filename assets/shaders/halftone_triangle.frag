#include <flutter/runtime_effect.glsl>

// Halftone-ефект трикутниками: яскравість кожної клітинки джерела (фото/
// відео-кадру через uTexture) визначає розмір трикутника в цій клітинці.
// Аналог друкарського растру. uSize — розмір поверхні в пікселях.
#define DOT_DENSITY 25.0
#define MAX_RADIUS 0.75

uniform vec2 uSize;
uniform sampler2D uTexture;

out vec4 fragColor;

float getBrightness(vec3 color) {
    return dot(color, vec3(0.2126, 0.7152, 0.0722));
}

float sdEquilateralTriangle(vec2 p, float r) {
    if (r <= 0.0) return 1.0;

    const float k = sqrt(3.0);
    p.x = abs(p.x) - r;
    p.y = p.y + r / k;

    if (p.x + k * p.y > 0.0) p = vec2(p.x - k * p.y, -k * p.x - p.y) / 2.0;
    p.x -= clamp(p.x, -2.0 * r, 0.0);
    return -length(p) * sign(p.y);
}

void main() {
    vec2 fragCoord = FlutterFragCoord().xy;
    vec2 uv = fragCoord / uSize;
    vec2 scaledUV = uv * DOT_DENSITY;
    vec2 cellID = floor(scaledUV);
    vec2 localUV = fract(scaledUV);

    vec2 cellCenterUV = (cellID + 0.5) / DOT_DENSITY;
    vec4 texColor = texture(uTexture, cellCenterUV);

    float brightness = getBrightness(texColor.rgb);

    vec2 p = localUV - vec2(0.5);
    float r = brightness * MAX_RADIUS;
    float dist = sdEquilateralTriangle(p, r);
    // fwidth() (screen-space derivatives) недоступний у SkSL-бекенді Flutter
    // — фіксована ширина згладжування замість адаптивної до fwidth().
    const float aa = 0.02;
    float tri = smoothstep(aa, -aa, dist);

    // Premultiplied alpha: прозоро там, де немає трикутника, замість
    // суцільного непрозорого фону — це накладення поверх об'єкта, а не
    // заміна його кольору.
    fragColor = vec4(texColor.rgb * tri, tri);
}
