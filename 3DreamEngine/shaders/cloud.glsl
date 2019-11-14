varying float dist;

#ifdef PIXEL
extern float density;
extern float time;

vec4 effect(vec4 color, Image texture, vec2 tc, vec2 sc) {
	float v = (Texel(texture, VaryingTexCoord.xy * 0.5 + vec2(time + dist*0.01, dist*0.01)).r + Texel(texture, VaryingTexCoord.xy * 0.5 + vec2(dist*0.01, time + dist*0.01)).r) * 0.5;
	float threshold = 1.0 - (density - abs(dist)*density);
	return vec4(1.0, 1.0, 1.0, min(1.0, 1.0 * max(0.0, v - threshold) / threshold)) * color;
}
#endif

#ifdef VERTEX
extern mat4 cam;

vec4 position(mat4 transform_projection, vec4 vertex_position) {
	dist = vertex_position.y;
	return cam * vertex_position;
}
#endif