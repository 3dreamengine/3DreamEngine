//transformations
extern highp mat4 transformProj;
varying highp vec3 vertexPos;

#ifdef PIXEL
extern vec3 sunColor;
extern vec3 ambientColor;

extern float scale;
extern float scale_base;
extern float scale_roughness;
extern float base_impact;

extern vec3 sunVec;
extern float sunStrength;
extern vec2 roughnessOffset;

extern Image tex_base;

vec4 effect(vec4 c, Image tex, vec2 tc, vec2 sc) {
	vec3 dir = normalize(vertexPos);
	vec3 pos = normalize(vertexPos * vec3(1.0, 8.0, 1.0));
	if (pos.y < 0.0) {
		discard;
	}
	
	//cloud
	float cloud = Texel(tex, pos.xz * scale).r;
	float base = clamp(0.5 + (Texel(tex_base, pos.xz * scale_base - roughnessOffset * 0.01).r - 0.5) * base_impact, 0.0, 1.0);
	float roughness = Texel(tex_base, pos.xz * scale_roughness - roughnessOffset).r;
	
	//density
	float density = cloud * base * pos.y;
	
	//direct sun
	float directDot = max(dot(sunVec, dir), 0.0);
	float direct = pow(directDot, 2.0 + density * 10.0) * sunStrength * max(0.0, 1.0 - dir.y);
	
	//color
	vec3 color = mix(sunColor + direct * sunColor, ambientColor, density) * (0.6 + roughness * 0.8);
	
	return vec4(color, density);
}
#endif


#ifdef VERTEX
vec4 position(mat4 transform_projection, vec4 vertex_position) {
	vertexPos = vertex_position.xyz;
	return transformProj * vertex_position;
}
#endif