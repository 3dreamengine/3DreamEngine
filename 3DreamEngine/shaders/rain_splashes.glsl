extern float time;

vec4 effect(vec4 color, Image tex, vec2 tc, vec2 sc) {
	vec4 c = Texel(tex, tc);
	float power = max(0.0, 1.0 - 1.5 * abs(time - c.a));
	return vec4(c.rgb - vec3(0.5), 1.0) * power;
}