extern float targetBrightness;
extern float adaptionSpeed;
extern float filterPrecision;

#ifdef PIXEL
vec4 effect(vec4 color, Image texture, vec2 tc, vec2 sc) {
	vec3 c = vec3(0.0);
	c += Texel(texture, vec2(0.500000, 0.611111)).rgb;
	c += Texel(texture, vec2(0.403775, 0.555556)).rgb;
	c += Texel(texture, vec2(0.403775, 0.444444)).rgb;
	c += Texel(texture, vec2(0.500000, 0.388889)).rgb;
	c += Texel(texture, vec2(0.596225, 0.444444)).rgb;
	c += Texel(texture, vec2(0.596225, 0.555556)).rgb;
	c += Texel(texture, vec2(0.388889, 0.692450)).rgb;
	c += Texel(texture, vec2(0.277778, 0.500000)).rgb;
	c += Texel(texture, vec2(0.388889, 0.307550)).rgb;
	c += Texel(texture, vec2(0.611111, 0.307550)).rgb;
	c += Texel(texture, vec2(0.722222, 0.500000)).rgb;
	c += Texel(texture, vec2(0.611111, 0.692450)).rgb;
	c += Texel(texture, vec2(0.211325, 0.666667)).rgb;
	c += Texel(texture, vec2(0.211325, 0.333333)).rgb;
	c += Texel(texture, vec2(0.500000, 0.166667)).rgb;
	c += Texel(texture, vec2(0.788675, 0.333333)).rgb;
	c += Texel(texture, vec2(0.788675, 0.666667)).rgb;
	c += Texel(texture, vec2(0.500000, 0.833333)).rgb;
	c += Texel(texture, vec2(0.055556, 0.500000)).rgb;
	c += Texel(texture, vec2(0.277778, 0.115100)).rgb;
	c += Texel(texture, vec2(0.722222, 0.115100)).rgb;
	c += Texel(texture, vec2(0.944444, 0.500000)).rgb;
	c += Texel(texture, vec2(0.722222, 0.884900)).rgb;
	c += Texel(texture, vec2(0.277778, 0.884900)).rgb;
	c += Texel(texture, vec2(0.500000, 0.500000)).rgb;
	c *= 0.04;
	
	float brightness = 0.299*c.r + 0.587*c.g + 0.114*c.b;
	float f = targetBrightness / (brightness + 0.1);
	return vec4(f, 0.0, 0.0, adaptionSpeed);
}
#endif