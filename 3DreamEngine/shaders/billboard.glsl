#ifdef PIXEL
vec4 effect(vec4 color, Image tex, vec2 tc, vec2 sc) {
	return Texel(tex, tc) * color;
}
#endif

#ifdef VERTEX
extern mat4 transformProj;
extern mat4 transform;

vec4 position(mat4 transform_projection, vec4 vertex_position) {
	vec4 vPos = transform * vertex_position;
	return transformProj * vPos;
}
#endif