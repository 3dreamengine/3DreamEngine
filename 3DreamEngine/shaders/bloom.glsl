extern float strength;
vec4 effect(vec4 color, Image texture, vec2 tc, vec2 sc) {
	return Texel(texture, tc) * vec4(strength, strength, strength, 1.0);
}