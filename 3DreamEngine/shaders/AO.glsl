extern mediump vec2 size;
extern mediump vec3 samples[sampleCount];

vec4 effect(vec4 color, Image texture, vec2 tc, vec2 sc) {
	float sum = 0.0;
	
	float z = Texel(texture, tc).r;
	if (z >= 250.0) {
		return vec4(1.0);
	}
	
	for (int i = 0; i < sampleCount; i++) {
		float r = Texel(texture, tc + samples[i].xy / (z*0.1)).r;
		
		//samples differences (but clamps it)
		if (r < 250.0) {
			//sharpness / size
			sum += clamp((z-r) * 8.0, -1.0, 1.0) * samples[i].z;
		}
	}
	
	//strength
	sum = min(1.0, 1.0 - max(0.0, sum) * 4.0);
	return vec4(sum, sum, sum, 1.0);
}