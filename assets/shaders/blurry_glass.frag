#version 460 core

#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;         // Розмір об'єкта
uniform float uTime;        // Час (якщо захочеш анімацію)
uniform vec3 uColor;        // Тінт скла
uniform float uOpacity;     // Прозорість

out vec4 fragColor;

// Палітра кольорів із твого коду (поділена на 256.0)
vec3 col1 = vec3(52.31940174, 57.13993023, 25.14114425) / 256.0;
float cdf1 = 0.356611508274;
vec3 col2 = vec3(90.01018469, 92.45607704, 48.6809284) / 256.0;
float cdf2 = 0.567189921512;
vec3 col3 = vec3(24.30486255, 28.39621824, 9.87158792) / 256.0;
float cdf3 = 0.85288706694;
vec3 col4 = vec3(7.20113504, 9.30435668, 2.79459992) / 256.0;
float cdf4 = 0.982995050742;
vec3 col5 = vec3(151.77977687, 144.51838133, 78.88918287) / 256.0;
float cdf5 = 1.0;

vec3 color_of(in float val) {
    float v = mod(2.0 * val, 1.0);
    vec3 result = col1;
    result = mix(result, col5, step(v, cdf5));
    result = mix(result, col4, step(v, cdf4));
    result = mix(result, col3, step(v, cdf3));
    result = mix(result, col2, step(v, cdf2));
    result = mix(result, col1, step(v, cdf1));
    return result;
}

void main() {
    vec2 uv = FlutterFragCoord().xy / uSize;
    
    // Простий процедурний патерн замість відсутньої функції noise з Shadertoy
    float noiseVal = sin(uv.x * 10.0 + uTime) * cos(uv.y * 10.0 + uTime) * 0.5 + 0.5;
    
    // Отримуємо колір із твоєї палітри
    vec3 paletteColor = color_of(noiseVal);
    
    // Змішуємо з базовим кольором скла
    vec3 finalColor = mix(uColor, paletteColor, 0.4);
    
    // Розрахунок акуратних країв (фаски) для скла
    vec2 edgeDist = min(uv, 1.0 - uv);
    float edge = min(edgeDist.x, edgeDist.y);
    float edgeFactor = 1.0 - smoothstep(0.0, 0.08, edge);
    
    finalColor = mix(finalColor, vec3(1.0), edgeFactor * 0.3);
    float alpha = clamp(uOpacity + (edgeFactor * 0.2), 0.0, 1.0);
    
    fragColor = vec4(finalColor, alpha);
}