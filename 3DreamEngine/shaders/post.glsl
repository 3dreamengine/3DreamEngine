extern Image depth;
extern Image AO;
extern float fog;
extern float strength;
vec4 effect(vec4 color, Image texture, vec2 tc, vec2 sc) {
	float AOv = (1.0 - strength) + Texel(AO, tc).r * strength;
	float depth = min(1.0, Texel(depth, tc).r * fog);
	return ((Texel(texture, tc) * vec4(AOv, AOv, AOv, 1.0)) + vec4(0.5) * depth) * color;
}