//part of the 3DreamEngine by Luke100000
//light_shadow_sun.glsl - lighting core, sun source, shadows

extern highp mat4 transformProjShadow_1;
extern highp mat4 transformProjShadow_2;
extern highp mat4 transformProjShadow_3;
extern sampler2DShadow tex_shadow_1;
extern sampler2DShadow tex_shadow_2;
extern sampler2DShadow tex_shadow_3;

#ifdef PIXEL
//viewer
extern highp vec3 viewPos;

extern Image tex_normal;
extern Image tex_position;
extern Image tex_material;

//lighting
extern highp vec3 lightPos;
extern lowp vec3 lightColor;

#import lightEngine
#import shadowEngine

vec4 effect(vec4 c, Image tex_color, vec2 tc, vec2 sc) {
	vec3 vertexPos = Texel(tex_position, tc).xyz;
	highp vec3 viewVec = normalize(viewPos - vertexPos);

	//sample shadow
	float shadow = sampleShadowSun(vertexPos, transformProjShadow_1, transformProjShadow_2, transformProjShadow_3, tex_shadow_1, tex_shadow_2, tex_shadow_3);
	
	if (shadow == 0.0) {
		return vec4(0.0, 0.0, 0.0, 1.0);
	} else {
		vec3 normal = normalize(Texel(tex_normal, tc).xyz);
		vec4 albedo = Texel(tex_color, tc);
		
		vec3 material = Texel(tex_material, tc).rgb;
		float roughness = material.r;
		float metallic = material.g;
		
		highp vec3 lightVec = normalize(lightPos);
		
		vec3 col = getLight(lightColor * shadow, viewVec, lightVec, normal, albedo.rgb, roughness, metallic) * albedo.a;
		return vec4(col, 1.0);
	}
}
#endif