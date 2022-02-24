varying vec3 vertexPos;

varying vec3 cloudsVec;

extern vec3 sunColor;
extern vec3 ambientColor;
extern vec3 sunVec;
extern float sunStrength;

extern CubeImage clouds;

extern mat3 cloudsTransform;

#ifdef PIXEL
extern float time;

void effect() {
	vec3 dir = normalize(vertexPos);
	
	float density = Texel(clouds, cloudsVec.xzy).r;
	
	float direct = 1.0 + max(dot(sunVec, dir), 0.0) * (1.0 - abs(sunVec.y) * 0.5) * 1.0;
	
	vec3 col = sunColor * direct;
	
	love_Canvases[0] = vec4(col, density);
	love_Canvases[1] = vec4(0.0);
}
#endif

#ifdef VERTEX
extern highp mat4 transformProj;

vec4 position(mat4 transform_projection, vec4 VertexPosition) {
	vertexPos = VertexPosition.xyz;
	cloudsVec = cloudsTransform * VertexPosition.xyz;
	return transformProj * vec4(VertexPosition.xyz, 1.0);
}
#endif