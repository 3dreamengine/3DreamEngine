float threshold = 1.0;
extern float strength;

extern Image canvas_alpha;
extern Image canvas_alphaData;

vec4 effect(vec4 color, Image texture, vec2 tc, vec2 sc) {
	vec4 col = Texel(texture, tc);
	
	//average alpha
	vec3 dat = Texel(canvas_alphaData, tc).xyz;
	if (dat.x > 0.0) {
		vec4 ca = Texel(canvas_alpha, tc);
		ca.rgb = ca.rgb / dat.y;
		ca.a = dat.y / dat.x;
		col = mix(col, ca, ca.a);
	}
	
	float brightness = 0.299*col.r + 0.587*col.g + 0.114*col.g;
	return vec4(max(vec3(0.0), col.rgb - col.rgb / brightness * threshold) * strength, col.a);
}