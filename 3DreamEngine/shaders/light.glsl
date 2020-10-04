#pragma language glsl3

#ifdef PIXEL
extern highp vec3 viewPos;

//light function
#import lightFunction

//uniforms required by the lighting
#import lightingSystemInit

//G-buffer
extern Image tex_position;
extern Image tex_normal;
extern Image tex_material;

vec4 effect(vec4 color, Image tex_albedo, vec2 tc, vec2 sc) {
	vec3 vertexPos = Texel(tex_position, tc).xyz;
	vec3 normal = normalize(Texel(tex_normal, tc).xyz);
	vec3 material = Texel(tex_material, tc).xyz;
	vec4 albedo = Texel(tex_albedo, tc);
	
	vec3 viewVec = normalize(viewPos - vertexPos);
	
	//forward lighting
	vec3 light = vec3(0.0);
#import lightingSystem
	
	//returns color
	return vec4(light, albedo.a);
}
#endif