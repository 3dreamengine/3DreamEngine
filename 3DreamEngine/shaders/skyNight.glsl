#ifdef PIXEL
extern float time;
extern Image night;
extern vec4 color;
vec4 effect(vec4 c, Image day, vec2 tc, vec2 sc) {
	return mix(Texel(day, tc), Texel(night, tc), time) * color;
}
#endif

#ifdef VERTEX
extern mat4 cam;
vec4 position(mat4 transform_projection, vec4 vertex_position) {
	return cam * vertex_position;
}
#endif