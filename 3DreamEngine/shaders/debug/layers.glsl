vec4 effect(vec4 c, Image tex, vec2 tc, vec2 sc) {
	float r = length(Texel(tex, tc) * c);
	return vec4(r, r, r, 1.0);
}