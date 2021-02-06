extern mediump vec3 samples[SAMPLE_COUNT];

vec4 effect(vec4 color, Image texture, vec2 tc, vec2 sc) {
	float sum = 0.0;
	
	float depth = Texel(texture, tc).r;
	float iDepth = 1.0 / depth;
	for (int i = 0; i < SAMPLE_COUNT; i++) {
		float sampleDepth = Texel(texture, tc + samples[i].xy * iDepth).r;
		
		float diff = depth - sampleDepth;
		sum += clamp(diff * 32.0 * iDepth, -1.0, 1.0) * samples[i].z;
	}
	
	sum = clamp(1.0 - sum * 2.0, 0.0, 1.0);
	return vec4(sum, sum, sum, 1.0);
}