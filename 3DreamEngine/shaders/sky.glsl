#ifdef PIXEL
extern vec4 color;
vec4 effect(vec4 c, Image day, vec2 tc, vec2 sc) {
	return Texel(day, tc) * color * c;
}
#endif

#ifdef VERTEX
extern mat4 cam;
vec4 position(mat4 transform_projection, vec4 vertex_position) {
	return cam * vertex_position;
}
#endif