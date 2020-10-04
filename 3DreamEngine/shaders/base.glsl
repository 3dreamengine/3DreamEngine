#pragma language glsl3

//camera uniforms
extern highp mat4 transformProj;   //projective transformation
extern highp mat4 transform;       //model transformation
extern highp vec3 viewPos;         //camera position

//varyings
varying highp vec3 vertexPos;      //vertex position for pixel shader
varying float depth;               //depth

//shader settings
extern bool ditherAlpha;

//setting specific defines
#import globalDefines

//shader specific defines
#import vertexDefines
#import modulesDefines
#import mainDefines

#ifdef PIXEL

//reflection engine
#import reflections

//light function
#import lightFunction

//uniforms required by the lighting
#import lightingSystemInit

//material
extern float ior;

void effect() {
#import mainPixelPre
	
	//dither alpha
	if (ditherAlpha) {
		if (albedo.a < fract(love_PixelCoord.x * 0.37 + love_PixelCoord.y * 73.73 + depth * 3.73)) {
			discard;
		} else {
			albedo.a = 1.0;
		}
	}
	
	vec3 viewVec = normalize(viewPos - vertexPos);
	
#import vertexPixel
#import mainPixel
#import modulesPixel

#import mainPixelPost
	
#ifndef DEFERRED
	//forward lighting
	vec3 light = vec3(0.0);
#import lightingSystem
	col += light * albedo.a;
	
#import modulesPixelPost
#endif
	
	//returns color
	love_Canvases[0] = vec4(col, albedo.a);
	love_Canvases[1] = vec4(depth, 1.0, 1.0, albedo.a);
	
#ifdef DEFERRED
	love_Canvases[2] = vec4(vertexPos, albedo.a);
	love_Canvases[3] = vec4(normal, albedo.a);
	love_Canvases[4] = vec4(material, albedo.a);
	love_Canvases[5] = albedo;
#else
#endif
}
#endif


#ifdef VERTEX
vec4 position(mat4 transform_projection, vec4 vertex_position) {
	vertexPos = vertex_position.xyz;
	
#import vertexVertex
#import modulesVertex
#import mainVertex
	
	//apply final vertex transform
	vertexPos = (transform * vec4(vertexPos, 1.0)).xyz;
	
	//projection transform for the vertex
	highp vec4 vPos = transformProj * vec4(vertexPos, 1.0);
	
	//extract and pass depth
	depth = vPos.z;
	
	return vPos;
}
#endif