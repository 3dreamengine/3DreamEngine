#pragma language glsl3

extern sampler2DShadow tex;

float maxDepth = 1.0;
float stepSize = 1.0 / 256.0;

vec4 effect(vec4 c, Image t, vec2 tc, vec2 sc) {
	for (float i = 0.0; i < 1.0; i += stepSize) {
		float r = texture(tex, vec3(tc, i * maxDepth));
		if (r == 0.0) {
			return vec4(i, i, i, 1.0);
		}
	}
	return vec4(1.0, 1.0, 1.0, 1.0);
}