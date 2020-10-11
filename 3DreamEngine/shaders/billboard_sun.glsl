varying float height;

#ifdef PIXEL
vec4 effect(vec4 color, Image tex, vec2 tc, vec2 sc) {
	float brightness = 4.0 * clamp(height * 10.0, 0.0, 1.0);
	return Texel(tex, tc) * color * vec4(brightness, brightness, brightness, 1.0);
}
#endif

#ifdef VERTEX
extern mat4 transformProj;

extern vec3 InstanceCenter;

extern vec3 up;
extern vec3 right;

vec4 position(mat4 transform_projection, vec4 vertex_position) {
	vec3 vPos = InstanceCenter + (right * vertex_position.x + up * vertex_position.y);
	height = vPos.y;
	return transformProj * vec4(vPos, 1.0);
}
#endif