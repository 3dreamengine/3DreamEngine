#pragma language glsl3

//camera uniforms
extern highp mat4 transformProj;   //projective transformation
extern highp mat4 transform;       //model transformation
extern highp vec3 viewPos;         //camera position

//varyings
varying highp vec3 vertexPos;      //vertex position for pixel shader
varying float depth;               //depth

//shader settings
extern bool average_alpha;
extern bool useAlphaDither;
extern float pass;

//setting specific defines
#import globalDefines

//shader specific defines
#import vertexDefines
#import mainDefines
#import modulesDefines

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
	if (useAlphaDither) {
		alpha = step(fract(love_PixelCoord.x * 0.37 + love_PixelCoord.y * 73.73 + depth * 3.73), alpha);
	} else if (alpha < 0.99 && pass < 0.0 || alpha >= 0.99 && pass > 0.0) {
		discard;
	}
	
	//hidden
	if (alpha <= 0.0) {
		discard;
	}
	
	//alpha disabled
	if (pass == 0.0) {
		alpha = 1.0;
	}
	
#import vertexPixel
#import mainPixel
#import modulesPixel
	
	//forward lighting
	vec3 light = vec3(0.0);
#import lightingSystem
	col += light * albedo.a;
	
#import modulesPixelPost
	
	//returns color
	//requires alpha, col and normal
	if (average_alpha) {
		love_Canvases[0] = vec4(col * alpha, 1.0);
		love_Canvases[1] = vec4(1.0, alpha, ior, 1.0);
		#ifdef REFRACTION_ENABLED
			love_Canvases[2] = vec4(normal, 1.0);
		#endif
	} else {
		love_Canvases[0] = vec4(col, alpha);
		love_Canvases[1] = vec4(depth, 1.0, 1.0, 1.0);
	}
}
#endif


#ifdef VERTEX
vec4 position(mat4 transform_projection, vec4 vertex_position) {
#import vertexVertex
#import mainVertex
#import modulesVertex
	
	vertexPos = pos.xyz;
	
	//projection transform for the vertex
	highp vec4 vPos = transformProj * pos;
	
	//extract and pass depth
	depth = vPos.z;
	
	return vPos;
}
#endif