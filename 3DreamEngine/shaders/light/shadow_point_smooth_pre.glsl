#pragma language glsl3
//part of the 3DreamEngine by Luke100000
//light_shadow_point_smooth.glsl - lighting core, point source, smooth shadows (pre)

extern float size;
extern samplerCube tex_shadow;

#ifdef PIXEL
extern Image tex_position;

//lighting
extern highp vec3 lightPos;

vec4 effect(vec4 c, Image tex_color, vec2 tc, vec2 sc) {
	vec3 vertexPos = Texel(tex_position, tc).xyz;
	vec3 lightVec = lightPos - vertexPos;
	vec3 n = -normalize(lightVec) * vec3(1.0, -1.0, 1.0);
	
	float depth = length(lightVec);	
	float bias = 0.01 + depth * 0.01;
	
	return vec4(texture(tex_shadow, n).r > (depth - bias) ? 1.0 : 0.0, 0.0, 0.0, 1.0);
}
#endif