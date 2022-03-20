#ifdef PIXEL
extern Image normalTex;
extern vec3 sun;

extern Image MainTex;

void effect() {
	vec3 n = normalize(Texel(normalTex, VaryingTexCoord.xy).xyz * 2.0 - 1.0);
	float light = max(0.0, pow(dot(n, sun), 0.5)) * 0.9 + 0.1;
	
	love_Canvases[0] = Texel(MainTex, VaryingTexCoord.xy) * VaryingColor * vec4(light, light, light, 1.0);
	love_Canvases[1] = vec4(65504.0, 0.0, 0.0, 1.0);
}
#endif

#ifdef VERTEX
extern mat4 transformProj;

extern vec3 InstanceCenter;

extern vec3 up;
extern vec3 right;

vec4 position(mat4 transform_projection, vec4 VertexPosition) {
	vec3 vPos = InstanceCenter + (right * VertexPosition.x + up * VertexPosition.y);
	return transformProj * vec4(vPos, 1.0);
}
#endif