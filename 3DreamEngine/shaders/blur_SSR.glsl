//11-tap 1.6 Sigma, weighted based on roughness

extern vec2 dir;
extern Image roughness;

vec4 effect(vec4 color, Image texture, vec2 tc, vec2 sc) {
	float roughness = Texel(roughness, tc).x;
	
	vec2 d = dir * roughness;
	
	vec4 sum = Texel(texture, tc) * 0.245484;
	
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