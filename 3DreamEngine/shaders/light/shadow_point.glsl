//part of the 3DreamEngine by Luke100000
//light_shadow_point.glsl - lighting core, point source, shadows

#ifdef PIXEL
//viewer
extern highp vec3 viewPos;

extern Image tex_normal;
extern Image tex_position;
extern Image tex_material;

//lighting
extern highp vec3 lightPos;
extern lowp vec3 lightColor;
extern float lightMeter;
extern float size;
extern samplerCube tex_shadow;

#import lightEngine
#import shadowEngine

vec4 effect(vec4 c, Image tex_color, vec2 tc, vec2 sc) {
	vec3 vertexPos = Texel(tex_position, tc).xyz;
	vec3 normal = normalize(Texel(tex_normal, tc).xyz);
	vec4 albedo = Texel(tex_color, tc);
	
	vec3 material = Texel(tex_material, tc).rgb;
	float roughness = material.r;
	float metallic = material.g;
	
	highp vec3 viewVec = normalize(viewPos - vertexPos);
	vec3 lightVec = lightPos - vertexPos;
	
	//sample shadow
	float shadow = sampleShadowPoint(lightVec, size, tex_shadow);
	
	if (shadow == 0.0) {
		return vec4(0.0, 0.0, 0.0, 1.0);
	} else {
		float distance = length(lightVec) * lightMeter;
		float power = 1.0 / (0.1 + distance * distance);
		
		vec3 col = getLight(lightColor * shadow * power, viewVec, normalize(lightVec), normal, albedo.rgb, roughness, metallic) * albedo.a;
		return vec4(col, 1.0);
	}
}
#endif