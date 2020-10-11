varying vec3 pos;

#ifdef PIXEL
extern CubeImage sky;

vec4 effect(vec4 c, Image unused, vec2 tc, vec2 sc) {
	return Texel(sky, pos * vec3(1.0, -1.0, 1.0));
}
#endif

#ifdef VERTEX
extern mat4 transformProj;

vec4 position(mat4 transform_projection, vec4 vertex_position) {
	pos = vertex_position.xyz;
	return transformProj * vec4(vertex_position.xyz, 1.0);
}
#endif