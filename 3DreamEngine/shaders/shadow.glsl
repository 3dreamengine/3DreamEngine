//transformations
extern highp mat4 transformProj;   //projective transformation
extern highp mat4 transform;       //model transformation

varying vec3 vertexPos;

#ifdef PIXEL
extern vec3 viewPos;
void effect() {
	float depth = length(viewPos - vertexPos.xyz);
	love_Canvases[0] = vec4(depth, 0.0, 0.0, 1.0);
}
#endif

#ifdef VERTEX
vec4 position(mat4 transform_projection, vec4 vertex_position) {
	//calculate vertex position
	highp vec4 pos = transform * vec4(vertex_position.xyz, 1.0);
	
	//depth required for shadows
	vertexPos = pos.xyz;
	
	//projective transform and depth extracting
	highp vec4 vPos = transformProj * pos;
	
	return vPos;
}
#endif