#ifdef PIXEL
extern Image tex_depth;
extern Image tex_position;
extern Image tex_reflectiness;
extern Image tex_normal;

extern highp mat4 transformProj;

extern vec3 viewPos;

const float stepSize = 0.01;
const float bias = 0.001;

const int steps = 128;
const int precisionSteps = 8;

extern Image background_day;
extern Image background_night;

extern float background_time;
extern vec3 background_color;

vec4 effect(vec4 c, Image tex_diffuse, vec2 tc, vec2 sc) {
	float reflectiness = Texel(tex_reflectiness, tc).r;
	
	if (reflectiness > 0.0) {
		vec4 n = Texel(tex_normal, tc);
		vec4 newPos;
		float nd;
		vec3 pos = Texel(tex_position, tc).xyz;
		
		float d = Texel(tex_depth, tc).r;
		
		highp vec3 viewVec = normalize(pos - viewPos);
		vec3 reflection = reflect(viewVec, normalize(n.xyz));
		
		vec3 normal = reflection * stepSize;
		
		//get UV coord for sky sphere
		float u = atan(-reflection.x, -reflection.z) * 0.1591549430919 - 0.25;
		float v = -reflection.y * 0.5 + 0.5;
		mediump vec2 uv = vec2(u, v);
		
		//blend
		mediump vec3 fallback_reflection = mix(Texel(background_day, uv), Texel(background_night, uv), background_time).rgb * background_color;
		
		for (int i = 0; i < steps; i++) {
			pos += normal;
			normal *= 1.1;
			
			newPos = transformProj * vec4(pos, 1.0);
			newPos /= newPos.w;
			newPos.xy = newPos.xy * 0.5 + 0.5;
			nd = Texel(tex_depth, newPos.xy).r;
			
			//early cancel
			if (newPos.x > 1.0 || newPos.y > 1.0 || newPos.x < 0.0 || newPos.y < 0.0) {
				return vec4(fallback_reflection, reflectiness);
			}
			
			if (newPos.z > nd) {
				normal *= 0.5;
				pos -= normal;
				
				//start binary seach
				for (int b = 0; b < precisionSteps; b++) {
					newPos = transformProj * vec4(pos, 1.0);
					newPos /= newPos.w;
					newPos.xy = newPos.xy * 0.5 + 0.5;
					
					nd = Texel(tex_depth, newPos.xy).r;
					
					normal *= 0.5;
					if (newPos.z > nd) {
						pos -= normal;
					} else {
						pos += normal;
					}
				}
				
				//avoid strange glitches
				pos += reflection * distance(pos, viewPos) * 0.01;
				newPos = transformProj * vec4(pos, 1.0);
				newPos /= newPos.w;
				newPos.xy = newPos.xy * 0.5 + 0.5;
				nd = Texel(tex_depth, newPos.xy).r;
				
				//mix
				float fade = 1.0;
				if (newPos.z > nd + bias || nd >= 1.0) {
					fade = 0.0;
				} else {
					fade = 1.0;
				}
				return vec4(mix(fallback_reflection, Texel(tex_diffuse, newPos.xy).rgb, fade), reflectiness);
			}
		}
	}
	
	return vec4(0.0, 0.0, 0.0, 0.0);
}
#endif