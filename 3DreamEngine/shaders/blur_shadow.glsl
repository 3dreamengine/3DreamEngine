//11-tap 1.6 Sigma, distance weighted

extern vec2 dir;
extern float size;
extern Image tex_depth;

vec4 effect(vec4 color, Image texture, vec2 tc, vec2 sc) {
	vec4 sum = Texel(texture, tc) * 0.245484;
	
	float depth = Texel(tex_depth, tc).a;
	vec2 d = dir * size / depth;
	
	sum += Texel(texture, tc - d * 5.0) * 0.002166;
	sum += Texel(texture, tc - d * 4.0) * 0.011902;
	sum += Texel(texture, tc - d * 3.0) * 0.044758;
	sum += Texel(texture, tc - d * 2.0) * 0.115233;
	sum += Texel(texture, tc - d) * 0.203199;
	
	sum += Texel(texture, tc + d) * 0.203199;
	sum += Texel(texture, tc + d * 2.0) * 0.115233;
	sum += Texel(texture, tc + d * 3.0) * 0.044758;
	sum += Texel(texture, tc + d * 4.0) * 0.011902;
	sum += Texel(texture, tc + d * 5.0) * 0.002166;
	
	return sum;
}