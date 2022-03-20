#pragma language glsl3

#define MAX_SOURCES 8

extern vec2 sizes[MAX_SOURCES];
extern vec3 positions[MAX_SOURCES];
extern vec3 colors[MAX_SOURCES];
extern int sourceCount;
extern int sampleCount;

extern Image noise;

extern float density;
extern float noiseStrength;
extern float decay;
extern vec2 scale;

#ifdef PIXEL
vec4 effect(vec4 color, Image depth_tex, vec2 tco, vec2 sc) {
	vec3 light = vec3(0.0, 0.0, 0.0);
	
	for (int i = 0; i < sourceCount; i++) {
		vec2 diff = (tco - positions[i].xy) * scale;
		float len = length(diff);
		float radius = sizes[i].x;
		
		if (len < sizes[i].y) {
			vec2 delta = normalize(diff);
			delta /= float(sampleCount);
			delta *= min(radius, len);
			
			//start at center
			vec2 tc = positions[i].xy;
			
			//sample light source
			float strength = 0.0;
			for (int s = 0; s < sampleCount; s++) {
				tc += delta;
				float depth = Texel(depth_tex, tc).x;
				if (depth > positions[i].z) {
					strength += 1.0;
				}
			}
			strength /= float(sampleCount);
			
			//enhance
			strength = (1.0 - abs(strength - 0.33)) * strength;
			
			//noise
			float a = atan(diff.y, diff.x) * 0.159154943091895 + 0.5;
			float n = Texel(noise, vec2(a, 0.0)).x * noiseStrength;
			
			//add to final light
			float d = density * strength * pow(max(0.0, 1.0 - len / sizes[i].y - n), decay);
			light += colors[i] * d;
		}
	}
	
	return vec4(light, 0.0);
}
#endif