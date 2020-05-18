varying float height;

#ifdef PIXEL
extern float time;

vec4 effect(vec4 ambient, Image sky, vec2 tc, vec2 sc) {
	return Texel(sky, vec2(time, 0.5-height*0.5)) * ambient;
}
#endif

#ifdef VERTEX
extern highp mat4 transformProj;

vec4 position(mat4 transform_projection, vec4 vertex_position) {
	height = normalize(vertex_position).y;
	return transformProj * vec4(vertex_position.xyz, 1.0);
}
#endif