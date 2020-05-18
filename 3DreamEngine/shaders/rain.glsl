//part of the 3DreamEngine by Luke100000
//rain shader

//transformations
extern highp mat4 transformProj;          //projective transformation
extern highp mat4 transform;              //model transformation

varying highp vec3 vertexPos;             //vertex position for pixel shader
varying highp float distance;             //distance from center

#ifdef PIXEL
extern float time;
extern float rain;

vec4 effect(vec4 color, Image tex, vec2 tc, vec2 sc) {
	float r = Texel(tex, tc - vec2(0.0, time * distance)).r;
	return vec4(0.85, 0.85, 1.0, r * rain * 0.5);
}
#endif


#ifdef VERTEX
vec4 position(mat4 transform_projection, vec4 vertex_position) {
	highp vec4 pos = transform * vertex_position;
	
	vertexPos = pos.xyz;
	
	distance = 1.0 + 0.05 * length(vertex_position);
	
	return transformProj * pos;
}
#endif