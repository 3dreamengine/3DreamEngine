#ifdef PIXEL
extern float exposure;

extern Image MainTex;

void effect() {
	vec4 c = Texel(MainTex, VaryingTexCoord.xy);
	love_Canvases[0] = vec4(c.rgb * exposure, 1.0);
	love_Canvases[1] = vec4(65504.0, 0.0, 0.0, 1.0);
}
#endif

#ifdef VERTEX
extern highp mat4 transformProj;

vec4 position(mat4 transform_projection, vec4 VertexPosition) {
	return transformProj * vec4(VertexPosition.xyz, 1.0);
}
#endif