//part of the 3DreamEngine by Luke100000
//point.glsl - point shadows

float sampleShadowPoint(vec3 lightVec, float size, samplerCube tex) {
	vec3 n = -normalize(lightVec) * vec3(1.0, -1.0, 1.0);
	vec3 t = normalize(vec3(-n.x, -n.y, (-n.x*n.x - n.y*n.y) / n.z));
	vec3 b = cross(n, t);
	
	float depth = length(lightVec);
	float sz = depth * size;
	float power = 0.0;
	
	float bias = 0.01 + depth * 0.01;
	depth -= bias;
	
#ifdef quality_low
	power += (texture(tex, n).r > depth ? 1.0 : 0.0);
#endif

#ifdef quality_medium
	power += (texture(tex, n + (t * 0.62348980 + b * 0.78183148) * sz).r > depth ? 0.14285714 : 0.0);
	power += (texture(tex, n + (t * -0.22252093 + b * 0.97492791) * sz).r > depth ? 0.14285714 : 0.0);
	power += (texture(tex, n + (t * -0.90096887 + b * 0.43388374) * sz).r > depth ? 0.14285714 : 0.0);
	power += (texture(tex, n + (t * -0.90096887 + b * -0.43388374) * sz).r > depth ? 0.14285714 : 0.0);
	power += (texture(tex, n + (t * -0.22252093 + b * -0.97492791) * sz).r > depth ? 0.14285714 : 0.0);
	power += (texture(tex, n + (t * 0.62348980 + b * -0.78183148) * sz).r > depth ? 0.14285714 : 0.0);
	power += (texture(tex, n + (t * 1.00000000 + b * -0.00000000) * sz).r > depth ? 0.14285714 : 0.0);
#endif
	
#ifdef quality_high
	power += (texture(tex, n + (t * 0.31174490 + b * 0.39091574) * sz).r > depth ? 0.10714286 : 0.0);
	power += (texture(tex, n + (t * 0.93523470 + b * 1.17274722) * sz).r > depth ? 0.03571429 : 0.0);
	power += (texture(tex, n + (t * -0.11126047 + b * 0.48746396) * sz).r > depth ? 0.10714286 : 0.0);
	power += (texture(tex, n + (t * -0.33378140 + b * 1.46239187) * sz).r > depth ? 0.03571429 : 0.0);
	power += (texture(tex, n + (t * -0.45048443 + b * 0.21694187) * sz).r > depth ? 0.10714286 : 0.0);
	power += (texture(tex, n + (t * -1.35145330 + b * 0.65082561) * sz).r > depth ? 0.03571429 : 0.0);
	power += (texture(tex, n + (t * -0.45048443 + b * -0.21694187) * sz).r > depth ? 0.10714286 : 0.0);
	power += (texture(tex, n + (t * -1.35145330 + b * -0.65082561) * sz).r > depth ? 0.03571429 : 0.0);
	power += (texture(tex, n + (t * -0.11126047 + b * -0.48746396) * sz).r > depth ? 0.10714286 : 0.0);
	power += (texture(tex, n + (t * -0.33378140 + b * -1.46239187) * sz).r > depth ? 0.03571429 : 0.0);
	power += (texture(tex, n + (t * 0.31174490 + b * -0.39091574) * sz).r > depth ? 0.10714286 : 0.0);
	power += (texture(tex, n + (t * 0.93523470 + b * -1.17274722) * sz).r > depth ? 0.03571429 : 0.0);
	power += (texture(tex, n + (t * 0.50000000 + b * -0.00000000) * sz).r > depth ? 0.10714286 : 0.0);
	power += (texture(tex, n + (t * 1.50000000 + b * -0.00000000) * sz).r > depth ? 0.03571429 : 0.0);
#endif
	
#ifdef quality_extreme
	power += (texture(tex, n + (t * 0.28041784 + b * 0.18021361) * sz).r > depth ? 0.05050505 : 0.0);
	power += (texture(tex, n + (t * 0.84125353 + b * 0.54064082) * sz).r > depth ? 0.03030303 : 0.0);
	power += (texture(tex, n + (t * 1.40208922 + b * 0.90106803) * sz).r > depth ? 0.01010101 : 0.0);
	power += (texture(tex, n + (t * 0.13847167 + b * 0.30321067) * sz).r > depth ? 0.05050505 : 0.0);
	power += (texture(tex, n + (t * 0.41541501 + b * 0.90963200) * sz).r > depth ? 0.03030303 : 0.0);
	power += (texture(tex, n + (t * 0.69235836 + b * 1.51605333) * sz).r > depth ? 0.01010101 : 0.0);
	power += (texture(tex, n + (t * -0.04743828 + b * 0.32994048) * sz).r > depth ? 0.05050505 : 0.0);
	power += (texture(tex, n + (t * -0.14231484 + b * 0.98982144) * sz).r > depth ? 0.03030303 : 0.0);
	power += (texture(tex, n + (t * -0.23719140 + b * 1.64970240) * sz).r > depth ? 0.01010101 : 0.0);
	power += (texture(tex, n + (t * -0.21828691 + b * 0.25191652) * sz).r > depth ? 0.05050505 : 0.0);
	power += (texture(tex, n + (t * -0.65486073 + b * 0.75574957) * sz).r > depth ? 0.03030303 : 0.0);
	power += (texture(tex, n + (t * -1.09143456 + b * 1.25958262) * sz).r > depth ? 0.01010101 : 0.0);
	power += (texture(tex, n + (t * -0.31983099 + b * 0.09391085) * sz).r > depth ? 0.05050505 : 0.0);
	power += (texture(tex, n + (t * -0.95949297 + b * 0.28173256) * sz).r > depth ? 0.03030303 : 0.0);
	power += (texture(tex, n + (t * -1.59915496 + b * 0.46955426) * sz).r > depth ? 0.01010101 : 0.0);
	power += (texture(tex, n + (t * -0.31983099 + b * -0.09391085) * sz).r > depth ? 0.05050505 : 0.0);
	power += (texture(tex, n + (t * -0.95949297 + b * -0.28173256) * sz).r > depth ? 0.03030303 : 0.0);
	power += (texture(tex, n + (t * -1.59915496 + b * -0.46955426) * sz).r > depth ? 0.01010101 : 0.0);
	power += (texture(tex, n + (t * -0.21828691 + b * -0.25191652) * sz).r > depth ? 0.05050505 : 0.0);
	power += (texture(tex, n + (t * -0.65486073 + b * -0.75574957) * sz).r > depth ? 0.03030303 : 0.0);
	power += (texture(tex, n + (t * -1.09143456 + b * -1.25958262) * sz).r > depth ? 0.01010101 : 0.0);
	power += (texture(tex, n + (t * -0.04743828 + b * -0.32994048) * sz).r > depth ? 0.05050505 : 0.0);
	power += (texture(tex, n + (t * -0.14231484 + b * -0.98982144) * sz).r > depth ? 0.03030303 : 0.0);
	power += (texture(tex, n + (t * -0.23719140 + b * -1.64970240) * sz).r > depth ? 0.01010101 : 0.0);
	power += (texture(tex, n + (t * 0.13847167 + b * -0.30321067) * sz).r > depth ? 0.05050505 : 0.0);
	power += (texture(tex, n + (t * 0.41541501 + b * -0.90963200) * sz).r > depth ? 0.03030303 : 0.0);
	power += (texture(tex, n + (t * 0.69235836 + b * -1.51605333) * sz).r > depth ? 0.01010101 : 0.0);
	power += (texture(tex, n + (t * 0.28041784 + b * -0.18021361) * sz).r > depth ? 0.05050505 : 0.0);
	power += (texture(tex, n + (t * 0.84125353 + b * -0.54064082) * sz).r > depth ? 0.03030303 : 0.0);
	power += (texture(tex, n + (t * 1.40208922 + b * -0.90106803) * sz).r > depth ? 0.01010101 : 0.0);
	power += (texture(tex, n + (t * 0.33333333 + b * -0.00000000) * sz).r > depth ? 0.05050505 : 0.0);
	power += (texture(tex, n + (t * 1.00000000 + b * -0.00000000) * sz).r > depth ? 0.03030303 : 0.0);
	power += (texture(tex, n + (t * 1.66666667 + b * -0.00000000) * sz).r > depth ? 0.01010101 : 0.0);
#endif
	
	return power;
}