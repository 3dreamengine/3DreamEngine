vec4 effect(vec4 c, Image tex, vec2 tc, vec2 sc) {
	return vec4(Texel(tex, tc).rgb, 1.0);
}