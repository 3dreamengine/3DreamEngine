//transformations
extern highp mat4 transformProj;   //projective transformation
extern highp mat4 transform;       //model transformation

varying float depth;

#ifdef PIXEL
void effect() {
	love_Canvases[0] = vec4(depth, 0.0, 0.0, 1.0);
}
#endif


#ifdef VERTEX

vec4 position(mat4 transform_projection, vec4 vertex_position) {
	//calculate vertex position
	highp vec4 pos = vec4(vertex_position.xyz, 1.0) * transform;
	
	//projective transform and depth extracting
	highp vec4 vPos = transformProj * pos;
	
	depth = vPos.z;
	
	return vPos;
}
#endif