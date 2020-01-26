extern Image tex_depth;

extern vec2 samples[SAMPLE_COUNT];

float bias = 0.025;
float maxDistance = 64.0;

extern mat4 projection;

vec4 effect(vec4 c, Image tex_normal, vec2 tc, vec2 sc) {
	vec3 normal = normalize(Texel(tex_normal, tc).xyz);
	float depth = Texel(tex_depth, tc).r;
	
	if (depth >= 1.0) {
		return vec4(1.0);
	}
	
	float occlusion = 0.0;
	for (int i = 0; i < SAMPLE_COUNT; ++i) {
		vec2 tc2 = tc + samples[i].xy;
		
		float sampleDepth = Texel(tex_depth, tc2).r;
		vec3 sampleNormal = normalize(Texel(tex_normal, tc2).xyz);
		
		float rangeCheck = clamp(1.0 + bias - abs(depth - sampleDepth) * maxDistance, 0.0, 1.0);
		float angle = clamp(pow(1.0 - abs(dot(sampleNormal, normal)), 2.0), 0.0, 1.0);
		
		occlusion += angle * rangeCheck;
	}
	
	occlusion = 1.0 - (occlusion / float(SAMPLE_COUNT));
	
	return vec4(occlusion, 0.0, 0.0, 1.0);
}