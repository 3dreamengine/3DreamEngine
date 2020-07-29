varying float VaryingEmission;

#ifdef PIXEL
vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords) {
	float l = 1.0 + VaryingEmission;
	return Texel(tex, VaryingTexCoord.xy) * vec4(l, l, l, 1.0) * VaryingColor;
}
#endif

#ifdef VERTEX
attribute vec3 InstanceCenter;
attribute vec2 InstanceSize;
attribute vec2 InstanceTexScale;
attribute vec2 InstanceTexOffset;
attribute float InstanceEmission;
attribute vec4 InstanceColor;

extern mat4 transform;
extern vec3 up;
extern vec3 right;

vec4 position(mat4 transform_projection, vec4 vertex_position) {
	VaryingTexCoord = vec4(VertexTexCoord.xy * InstanceTexScale + InstanceTexOffset, 0.0, 0.0);
	VaryingColor = InstanceColor;
	VaryingEmission = InstanceEmission;
	
	vec3 pos = InstanceCenter + (right * vertex_position.x * InstanceSize.x + up * vertex_position.y * InstanceSize.y);
	
	return transform * vec4(pos, 1.0);
}
#endif