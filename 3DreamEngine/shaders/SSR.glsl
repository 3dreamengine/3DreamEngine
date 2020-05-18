extern Image canvas_albedo;
extern Image canvas_normal;
extern Image canvas_position;
extern Image canvas_material;

extern Image canvas_bloom;
extern Image canvas_ao;

extern CubeImage canvas_sky;
extern vec3 ambient;

extern mat4 transformInverse;
extern mat4 transform;
extern vec3 viewPos;

extern Image brdfLUT;

#ifdef PIXEL
vec4 effect(vec4 color, Image canvas_color, vec2 tc, vec2 sc) {
	vec4 bc = Texel(canvas_color, tc);
	if (bc.a == 0.0) {
		return vec4(0.0);
	}
	
	//data
	vec3 albedo = Texel(canvas_albedo, tc).xyz;
	vec3 position = Texel(canvas_position, tc).xyz;
	vec3 normal = Texel(canvas_normal, tc).xyz;
	vec3 material = Texel(canvas_material, tc).xyz;
	
#ifdef SHADERTYPE_PBR
	float roughness = material.x;
	float metallic = material.y;
	
	vec3 viewVec = normalize(viewPos - position);
	float cosTheta = max(dot(normal, viewVec), 0.0);
	vec3 F0 = mix(vec3(0.04), albedo.rgb, metallic);
	
	vec3 F = F0 + (max(vec3(1.0 - roughness), F0) - F0) * pow(1.0 - cosTheta, 5.0);
	
	//approximate the specular part with brdf lookup table
	vec2 brdf = Texel(brdfLUT, vec2(cosTheta, roughness)).rg;
	vec3 reflectiness = (F * brdf.x + vec3(brdf.y));
#else
	float roughness = material.x;
	vec3 reflectiness = material.yyy * albedo.rgb;
#endif
	
	vec4 c = vec4(0.0);
	
	//raytracing
	if (length(reflectiness) > 0.01) {
		float ditherStrength = 0.2 * roughness;
		float dither = 1.0 - ditherStrength*0.5 + fract(position.x * 1111.1 + position.y * 7777.7 + position.z * 3333.3) * ditherStrength;
		
		int steps = 32;
		float quality = 0.1;
		
		float closest = 0.1;
		vec3 glossy = normalize(fract(vec3(position.x * 123.4, position.y * 123.4, position.z * 123.4)) - vec3(0.5));
		vec3 dir = (normalize(reflect(position - viewPos, normal)) * dither + glossy * roughness * 0.1) * closest;
		vec3 pos = position + dir * 1.1;
		
		//reflected sky
#ifdef SKY_ENABLED
		vec3 reflection = textureLod(canvas_sky, dir * vec3(1.0, -1.0, 1.0), 0.0).rgb;
#else
		vec3 reflection = ambient;
#endif
		
		for (int i = steps; i > 0; i--) {
			vec4 t = transform * vec4(pos, 1.0);
			vec2 tc2 = (t.xy / t.w).xy * 0.5 + 0.5;
			
			vec3 pos2 = Texel(canvas_position, tc2).xyz;
			float l = length(dir);
			
			if (length(pos - pos2) < l) {
				if (i < 5 || l < quality) {
					float dist = max(abs(tc2.x-0.5), abs(tc2.y-0.5)) * 2.0;
					float a = clamp(1.0 - pow(dist, 8.0), 0.0, 1.0);
					
					vec4 reflectedColor = Texel(canvas_color, tc2);
					
#ifdef AO_ENABLED
						float ao = Texel(canvas_ao, tc2).r;
						reflectedColor.rgb *= ao;
#endif
						
#ifdef BLOOM_ENABLED
						vec3 bloom = Texel(canvas_bloom, tc2).rgb;
						reflectedColor.rgb += bloom;
#endif
					
					reflection = mix(reflection, reflectedColor.rgb, a * reflectedColor.a);
					break;
				}
				
				pos -= dir;
				dir *= 0.37;
			} else if (tc2.x < 0.0 || tc2.x > 1.0 || tc2.y < 0.0 || tc2.y > 1.0) {
				break;
			}
			
			dir *= 1.25;
			pos += dir;
		}
		
		c.rgb = reflection * reflectiness;
		c.a = 1.0;
	}
	
	return c;
}
#endif