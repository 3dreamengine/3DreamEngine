vec4 effect(vec4 c, Image tex, vec2 tc, vec2 sc) {
	return vec4(Texel(tex, tc).rgb * 0.5 + 0.5, 1.0);
}