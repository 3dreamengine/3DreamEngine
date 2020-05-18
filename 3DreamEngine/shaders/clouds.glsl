#pragma language glsl3
//part of the 3DreamEngine by Luke100000
//clouds shader

//transformations
extern highp mat4 transformProj;
varying highp vec3 vertexPos;

#ifdef PIXEL
extern vec3 sunColor;
extern vec3 ambientColor;

extern float threshold;
extern float thresholdInverted;

extern float thresholdPackets;
extern float thresholdInvertedPackets;

extern vec2 time;
extern float scale;
extern float weight;
extern float sharpness;
extern float detail;
extern float thickness;

extern float packets;

extern vec3 sunVec;

extern Image tex_packets;

vec4 effect(vec4 c, Image tex_rough, vec2 tc, vec2 sc) {
	vec3 pos = normalize(vertexPos * vec3(1.0, 10.0, 1.0));
	if (pos.y < 0.0) {
		discard;
	}
	
	//base 
	vec4 c0 = texture(tex_rough, (pos.xz * 0.3 + time) * scale, detail) - vec4(0.5, 0.5, 0.5, 0.0);
	vec4 c1 = texture(tex_rough, (pos.xz * 0.2 + time) * scale, detail + 1.0) - vec4(0.5, 0.5, 0.5, 0.0);
	vec4 c2 = texture(tex_rough, (pos.xz * 0.2 + time * 0.3) * scale, detail + 2.0) - vec4(0.5, 0.5, 0.5, 0.0);
	
	//packets
	vec4 p0 = texture(tex_packets, (pos.xz * 0.3 + time) * scale, 0.0) - vec4(0.5, 0.5, 0.5, 0.0);
	float p_d = (p0.a - thresholdPackets) * thresholdInvertedPackets;
	
	//final
	float c_d = max(((c0.a + c1.a) * c2.a * mix(1.0, p_d * 1.5, packets) - threshold + thickness), 0.0) * thresholdInverted;
	vec3 c_n = c0.xyz * c0.a + c1.xyz * c1.a + c2.xyz * c2.a + p0.xyz * p0.a * packets * 2.0;
	c_n = normalize(c_n.xzy * vec3(1.0, sharpness * (1.0 + abs(sunVec.y)), 1.0));
	
	//direct light
	float directLight = max(0.0, max(
		dot(-sunVec, c_n * vec3(1.0, -1.0, 1.0)) * (1.0 - thickness * 0.5),
		dot(-sunVec, c_n)
	));
	
	//color
	return vec4(sunColor * pow(directLight, 4.0) + ambientColor, min(1.0, pow(c_d * pos.y, weight)));
}
#endif


#ifdef VERTEX
vec4 position(mat4 transform_projection, vec4 vertex_position) {
	vertexPos = vertex_position.xyz;
	return transformProj * vertex_position;
}
#endif