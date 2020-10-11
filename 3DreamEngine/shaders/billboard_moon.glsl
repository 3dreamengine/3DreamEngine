#ifdef PIXEL
extern Image normalTex;
extern vec3 sun;

vec4 effect(vec4 color, Image tex, vec2 tc, vec2 sc) {
	vec3 n = normalize(Texel(normalTex, tc).xyz * 2.0 - 1.0);
	float light = max(0.0, pow(dot(n, sun), 0.5)) * 0.9 + 0.1;
	return Texel(tex, tc) * color * vec4(light, light, light, 1.0);
}
#endif

#ifdef VERTEX
extern mat4 transformProj;

extern vec3 InstanceCenter;

extern vec3 up;
extern vec3 right;

vec4 position(mat4 transform_projection, vec4 vertex_position) {
	vec3 vPos = InstanceCenter + (right * vertex_position.x + up * vertex_position.y);
	return transformProj * vec4(vPos, 1.0);
}
#endif