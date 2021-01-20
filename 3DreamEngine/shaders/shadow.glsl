#pragma language glsl3

//setting specific defines
#import globalDefines

//camera uniforms
extern highp mat4 transformProj;   //projective transformation
extern highp mat4 transform;       //model transformation
extern highp vec3 viewPos;         //camera position

//varyings
varying highp vec3 vertexPos;      //vertex position for pixel shader
varying float depth;               //depth
extern bool mode;

//shader specific defines
#import vertexDefines
#import modulesDefines
#import mainDefines

#ifdef PIXEL

void effect() {
#import modulesPixelPre
	vec3 viewVec = normalize(viewPos - vertexPos);
	
#import modulesPixel
#import modulesPixelPost
	
	if (mode) {
		love_Canvases[0] = vec4(depth, depth, 0.0, 1.0);
	} else {
		float dd = length(viewPos - vertexPos.xyz);
		love_Canvases[0] = vec4(dd, dd, 0.0, 1.0);
	}
}
#endif


#ifdef VERTEX
vec4 position(mat4 transform_projection, vec4 vertex_position) {
	vertexPos = vertex_position.xyz;
	
#import vertexVertex
#import modulesVertex
	
	//apply final vertex transform
	vertexPos = (transform * vec4(vertexPos, 1.0)).xyz;
	
	//projection transform for the vertex
	vec4 vPos = transformProj * vec4(vertexPos, 1.0);
	
	//extract and pass depth
	depth = vPos.z;
	
#import modulesVertexPost
	
	return vPos;
}
#endif