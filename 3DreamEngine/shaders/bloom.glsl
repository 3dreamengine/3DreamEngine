float threshold = 1.0;
extern float strength;

vec4 effect(vec4 color, Image texture, vec2 tc, vec2 sc) {
	vec4 col = Texel(texture, tc);
	float brightness = 0.299*col.r + 0.587*col.g + 0.114*col.g;
	return vec4(max(vec3(0.0), col.rgb - col.rgb / brightness * threshold) * strength, col.a);
}