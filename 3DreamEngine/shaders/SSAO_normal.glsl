extern mediump vec3 samples[SAMPLE_COUNT];

const float maxDistanceInverse = 10.0;

vec4 effect(vec4 color, Image texture, vec2 tc, vec2 sc) {
	float sum = 0.0;
	
	float depth = Texel(texture, tc).z;
	if (depth >= 250.0) {
		return vec4(1.0);
	}
	
	for (int i = 0; i < SAMPLE_COUNT; i++) {
		float sampleDepth = Texel(texture, tc + samples[i].xy / (0.25+depth)).z;
		
		//samples differences (but clamps it)
		if (sampleDepth < 250.0) {
			float f = clamp(5.0 - abs(sampleDepth - depth) * maxDistanceInverse * (0.25 + depth * 0.25), 0.0, 1.0);
			sum += clamp((depth-sampleDepth) * 8.0, -1.0, 1.0) * samples[i].z * f;
		}
	}
	
	//strength
	sum = min(1.0, 1.0 - max(0.0, sum) * 4.0);
	return vec4(sum, sum, sum, 1.0);
}