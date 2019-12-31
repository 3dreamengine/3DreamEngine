#ifdef PIXEL
extern Image depth;

extern highp mat3 camTransformInverse;

const float stepSize = 0.02;
const float bias = 0.01;

const int steps = 64;
const int precisionSteps = 8;

vec4 effect(vec4 c, Image normal, vec2 tc, vec2 sc) {
	vec4 n = Texel(normal, tc);
	
	if (n.a > 0.0) {
		float d = Texel(depth, tc).r;
		vec3 pos = vec3((tc * 2.0 - 1.0) * d, d);
		
		vec3 reflection = camTransformInverse * (n.xyz * 2.0 - 1.0);
		
//		float ox = float(fract(love_PixelCoord.x * 0.5) > 0.25);
//		float oy = float(fract(love_PixelCoord.y * 0.5) > 0.25);
		vec3 normal = reflection * vec3(-1.0, 1.0, 1.0) * stepSize;
		
		for (int i = 0; i < steps; i++) {
			pos += normal;
			normal *= 1.1;
			
			vec2 newPos = (pos.xy / pos.z) * 0.5 + 0.5;
			float nd = Texel(depth, newPos.xy).r;
			if (pos.z > nd) {
				normal *= 0.5;
				pos -= normal;
				
				//start binary seach
				for (int b = 0; b < precisionSteps; b++) {
					newPos = (pos.xy / pos.z) * 0.5 + 0.5;
					nd = Texel(depth, newPos.xy).r;
					normal *= 0.5;
					if (pos.z > nd) {
						pos -= normal;
					} else {
						pos += normal;
					}
				}
				
				float fade = max(0.0, 1.0 - pow(length(newPos-0.5)*2.0, 8.0)) * clamp(2.0 - abs(pos.z - nd) / bias, 0.0, 1.0) * min(1.0, pow(length(reflection.xy) * 8.0, 2.0));
				return vec4(newPos.xy, fade, 1.0);
			}
		}
	}
	
	return vec4(0.0, 0.0, 0.0, 1.0);
}
#endif