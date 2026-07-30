#include <flutter/runtime_effect.glsl>

// Parallax fractal galaxy (адаптовано з CBS, https://www.shadertoy.com/view/lslGWr).
// uTexture — спектр поточного треку з AudioTextureManager: рядок 0 (v=0.25)
// FFT-магнітуда 256 смуг, рядок 1 (v=0.75) waveform — той самий шар, що
// ShaderToy's iChannel0 для аудіо-візуалізацій. uTime анімує рух шарів.
uniform vec2 uSize;
uniform sampler2D uTexture;
uniform float uTime;

out vec4 fragColor;

float field(in vec3 p, float s) {
	float strength = 7. + .03 * log(1.e-6 + fract(sin(uTime) * 4373.11));
	float accum = s / 4.;
	float prev = 0.;
	float tw = 0.;
	for (int i = 0; i < 26; ++i) {
		float mag = dot(p, p);
		p = abs(p) / mag + vec3(-.5, -.4, -1.5);
		float w = exp(-float(i) / 7.);
		accum += w * exp(-strength * pow(abs(mag - prev), 2.2));
		tw += w;
		prev = mag;
	}
	return max(0., 5. * accum / tw - .7);
}

float field2(in vec3 p, float s) {
	float strength = 7. + .03 * log(1.e-6 + fract(sin(uTime) * 4373.11));
	float accum = s / 4.;
	float prev = 0.;
	float tw = 0.;
	for (int i = 0; i < 18; ++i) {
		float mag = dot(p, p);
		p = abs(p) / mag + vec3(-.5, -.4, -1.5);
		float w = exp(-float(i) / 7.);
		accum += w * exp(-strength * pow(abs(mag - prev), 2.2));
		tw += w;
		prev = mag;
	}
	return max(0., 5. * accum / tw - .7);
}

vec3 nrand3(vec2 co) {
	vec3 a = fract(cos(co.x * 8.3e-3 + co.y) * vec3(1.3e5, 4.7e5, 2.9e5));
	vec3 b = fract(sin(co.x * 0.3e-3 + co.y) * vec3(8.1e5, 1.0e5, 0.1e5));
	vec3 c = mix(a, b, 0.5);
	return c;
}

void main() {
	vec2 fragCoord = FlutterFragCoord().xy;
	vec2 uv = 2. * fragCoord.xy / uSize.xy - 1.;
	vec2 uvs = uv * uSize.xy / max(uSize.x, uSize.y);
	vec3 p = vec3(uvs / 4., 0) + vec3(1., -1.3, 0.);
	p += .2 * vec3(sin(uTime / 16.), sin(uTime / 12.), sin(uTime / 128.));

	float freq0 = texture(uTexture, vec2(0.01, 0.25)).x;
	float freq1 = texture(uTexture, vec2(0.07, 0.25)).x;
	float freq2 = texture(uTexture, vec2(0.15, 0.25)).x;
	float freq3 = texture(uTexture, vec2(0.30, 0.25)).x;

	float t = field(p, freq2);
	float v = (1. - exp((abs(uv.x) - 1.) * 6.)) * (1. - exp((abs(uv.y) - 1.) * 6.));

	vec3 p2 = vec3(uvs / (4. + sin(uTime * 0.11) * 0.2 + 0.2 + sin(uTime * 0.15) * 0.3 + 0.4), 1.5) +
		vec3(2., -1.3, -1.);
	p2 += 0.25 * vec3(sin(uTime / 16.), sin(uTime / 12.), sin(uTime / 128.));
	float t2 = field2(p2, freq3);
	vec4 c2 = mix(.4, 1., v) * vec4(1.3 * t2 * t2 * t2, 1.8 * t2 * t2, t2 * freq0, t2);

	vec2 seed = p.xy * 2.0;
	seed = floor(seed * uSize.x);
	vec3 rnd = nrand3(seed);
	vec4 starcolor = vec4(pow(rnd.y, 40.0));

	vec2 seed2 = p2.xy * 2.0;
	seed2 = floor(seed2 * uSize.x);
	vec3 rnd2 = nrand3(seed2);
	starcolor += vec4(pow(rnd2.y, 40.0));

	vec4 color = mix(freq3 - .3, 1., v) *
		vec4(1.5 * freq2 * t * t * t, 1.2 * freq1 * t * t, freq3 * t, 1.0) + c2 + starcolor;

	// Premultiplied alpha (як і в інших шейдерах цього проєкту): галактика
	// заповнює весь прямокутник, тож альфу беремо з найяскравішого каналу —
	// темні ділянки лишають видимим базовий колір фігури під низом.
	float alpha = clamp(max(color.r, max(color.g, color.b)), 0.0, 1.0);
	fragColor = vec4(color.rgb * alpha, alpha);
}
