extern mediump vec2 size;
extern float hstep;
extern float vstep;

vec4 effect(vec4 color, Image texture, vec2 tc, vec2 sc) {
	float o = Texel(texture, tc).r;
	float sum = o * 0.383103;
	
	sum += Texel(texture, tc - vec2(3.0*hstep, 3.0*vstep) * size).r * 0.00598;
	sum += Texel(texture, tc - vec2(2.0*hstep, 2.0*vstep) * size).r * 0.060626;
	sum += Texel(texture, tc - vec2(1.0*hstep, 1.0*vstep) * size).r * 0.241843;
	
	sum += Texel(texture, tc + vec2(1.0*hstep, tc.y + 1.0*vstep) * size).r * 0.241843;
	sum += Texel(texture, tc + vec2(2.0*hstep, tc.y + 2.0*vstep) * size).r * 0.060626;
	sum += Texel(texture, tc + vec2(3.0*hstep, tc.y + 3.0*vstep) * size).r * 0.00598;
	
	return vec4(sum);
}