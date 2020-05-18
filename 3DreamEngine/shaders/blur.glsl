//11-tap 1.6 Sigma

extern vec2 dir;

vec4 effect(vec4 color, Image texture, vec2 tc, vec2 sc) {
	vec4 sum = Texel(texture, tc) * 0.245484;
	
	sum += Texel(texture, tc - dir * 5.0) * 0.002166;
	sum += Texel(texture, tc - dir * 4.0) * 0.011902;
	sum += Texel(texture, tc - dir * 3.0) * 0.044758;
	sum += Texel(texture, tc - dir * 2.0) * 0.115233;
	sum += Texel(texture, tc - dir) * 0.203199;
	
	sum += Texel(texture, tc + dir) * 0.203199;
	sum += Texel(texture, tc + dir * 2.0) * 0.115233;
	sum += Texel(texture, tc + dir * 3.0) * 0.044758;
	sum += Texel(texture, tc + dir * 4.0) * 0.011902;
	sum += Texel(texture, tc + dir * 5.0) * 0.002166;
	
	return sum;
}