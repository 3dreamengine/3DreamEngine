extern float alpha;

vec4 effect(vec4 col, Image tex, vec2 tc, vec2 sc) {
	vec3 c = Texel(tex, tc).xyz * alpha;
	return vec4(c, 1.0);
}