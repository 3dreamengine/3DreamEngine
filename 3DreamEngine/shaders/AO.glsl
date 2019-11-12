extern mediump vec2 size;
extern mediump vec3 samples[sampleCount];

vec4 effect(vec4 color, Image texture, vec2 tc, vec2 sc) {
	float sum = 0.0;
	
	float z = Texel(texture, tc).r;
	if (z >= 250.0) {
		return vec4(1.0);
	}
	
	for (int i = 0; i < sampleCount; i++) {
		float r = Texel(texture, tc + samples[i].xy / (0.3+z*0.05)).r;
		
		//samples differences (but clamps it)
		if (r < 250.0) {
			sum += clamp((z-r), -0.25, 0.5) * samples[i].z;
		}
	}
	
	sum = pow(1.0 - sum / float(sampleCount) * (1.0/sqrt(z+1.0)) * 16.0, 2.0);
	return vec4(sum, sum, sum, 1.0);
}