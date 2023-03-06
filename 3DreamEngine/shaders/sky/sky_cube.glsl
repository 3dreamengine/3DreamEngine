varying vec3 pos;

#ifdef PIXEL
uniform CubeImage MainTex;

void effect() {
	// todo why is Z inverted
	love_Canvases[0] = Texel(MainTex, pos * vec3(1.0, 1.0, -1.0));
	love_Canvases[1] = vec4(65504.0, 0.0, 0.0, 1.0);
}
#endif

#ifdef VERTEX
uniform mat4 transformProj;

vec4 position(mat4 transform_projection, vec4 VertexPosition) {
	pos = VertexPosition.xyz;
	return (transformProj * vec4(VertexPosition.xyz, 1.0)).xyww;
}
#endif