extern float targetBrightness;

#ifdef PIXEL
vec4 effect(vec4 color, Image texture, vec2 tc, vec2 sc) {
	vec3 c = Texel(texture, tc).rgb;
	
	float v = 1.0 - pow(length(tc - vec2(0.5)) * 0.70710678, 2.0) * 0.75;
	float brightness = 0.299*c.r + 0.587*c.g + 0.114*c.b;
	
	float f = targetBrightness / (brightness + 0.1);
	return vec4(f, 0.0, 0.0, 1.0);
}
#endif