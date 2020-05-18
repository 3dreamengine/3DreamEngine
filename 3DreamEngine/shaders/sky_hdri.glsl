#ifdef PIXEL
extern float exposure;

vec4 effect(vec4 ambient, Image sky, vec2 tc, vec2 sc) {
	vec4 c = Texel(sky, tc);
	return vec4(c.rgb * exposure, 1.0);
}
#endif

#ifdef VERTEX
extern highp mat4 transformProj;

vec4 position(mat4 transform_projection, vec4 vertex_position) {
	return transformProj * vec4(vertex_position.xyz, 1.0);
}
#endif