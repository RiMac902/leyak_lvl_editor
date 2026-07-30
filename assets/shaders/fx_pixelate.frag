#include <flutter/runtime_effect.glsl>

// Screen-space pixelate — квантує координату вибірки до сітки блоків
// розміром uPixelSize (у пікселях) перед семплуванням уже готового кадру
// (uTexture). Найпростіший з чотирьох fx_*-шейдерів — жодних додаткових
// параметрів, окрім розміру блоку.
uniform vec2 uSize;
uniform sampler2D uTexture;
uniform float uPixelSize; // розмір блоку в пікселях; 1 (чи менше) = без ефекту

out vec4 fragColor;

void main() {
    vec2 fragCoord = FlutterFragCoord().xy;
    float blockSize = max(uPixelSize, 1.0);
    vec2 blockCenter = (floor(fragCoord / blockSize) + 0.5) * blockSize;

    fragColor = texture(uTexture, blockCenter / uSize);
}
