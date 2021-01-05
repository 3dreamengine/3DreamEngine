#pragma language glsl3

//setting specific defines
#import globalDefines

//camera uniforms
extern highp mat4 transformProj;   //projective transformation
#ifdef INSTANCES
extern highp mat4 transforms[INSTANCES];
#else
extern highp mat4 transform;       //model transformation
#endif
extern highp vec3 viewPos;         //camera position

//varyings
varying highp vec3 vertexPos;      //vertex position for pixel shader
varying float depth;               //depth

//shader specific defines
#import vertexDefines
#import modulesDefines
#import mainDefines

#ifdef PIXEL

void effect() {
	vec3 viewVec = normalize(viewPos - vertexPos);
	
#import modulesPixel
#import modulesPixelPost
	
	float dd = length(viewPos - vertexPos.xyz);
	love_Canvases[0] = vec4(dd, dd, dd, 1.0);
}
#endif


#ifdef VERTEX
vec4 position(mat4 transform_projection, vec4 vertex_position) {
	vertexPos = vertex_position.xyz;
	
#import vertexVertex
#import modulesVertex
	
	//apply final vertex transform
#ifdef INSTANCES
	vertexPos = (transforms[love_InstanceID] * vec4(vertexPos, 1.0)).xyz;
#else
	vertexPos = (transform * vec4(vertexPos, 1.0)).xyz;
#endif
	
	//projection transform for the vertex
	vec4 vPos = transformProj * vec4(vertexPos, 1.0);
	
	//extract and pass depth
	depth = vPos.z;
	
	return vPos;
}
#endif