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
varying vec3 normalRawV;           //depth

//shader specific defines
#import vertexDefines
#import modulesDefines
#import mainDefines

extern Image tex_depth;

#ifdef REFRACTIONS_ENABLED
extern vec2 screenScale;
#endif

#ifdef EXPOSURE_ENABLED
extern float exposure;
#endif

#ifdef GAMMA_ENABLED
extern float gamma;
#endif

#import fog

#ifdef PIXEL

//shader settings
extern float dataAlpha;
extern float dither;

//material
extern float ior;
extern float translucent;

//reflection engine
#import reflections

//light function
#import lightFunction

//uniforms required by the lighting
#import lightingSystemInit

float whenLt(float x, float y) {
	return max(sign(y - x), 0.0);
}

void effect() {
	vec3 caustics = vec3(0.0);

#ifdef REFRACTIONS_ENABLED
	vec2 distortion = vec2(0.0);
#endif
	
#import mainPixelPre
#import modulesPixelPre
	
	//dither alpha
#ifndef ALPHA_PASS
#ifdef DISCARD_ENABLED
	if (albedo.a < mix(
		0.5,
		fract(love_PixelCoord.x * 0.37 + love_PixelCoord.y * 73.73 + depth * 3.73),
		dither
	)) {
		discard;
	}
#endif
	albedo.a = 1.0;
#endif
	
	vec3 normalRaw = normalize(normalRawV);
	vec3 viewVec = normalize(viewPos - vertexPos);
	
#import mainPixel
#import modulesPixel
vec3 col;
	
	//forward lighting
	vec3 light = vec3(0.0);
#import lightingSystem
	col += light;
	
	//apply caustics
	col += caustics / albedo.a;
	
#import mainPixelPost
#import modulesPixelPost

	//calculate refractions
#ifdef REFRACTIONS_ENABLED
	if (ior != 1.0) {
		vec2 startPixel = love_PixelCoord.xy * screenScale;
		
		//refract and transform back to pixel coord
		vec3 endPoint = vertexPos + normalize(refract(-viewVec, normal, ior)) * 0.15;
		vec4 endPixel = transformProj * vec4(endPoint, 1.0);
		endPixel /= endPixel.w;
		endPixel.xy = endPixel.xy * 0.5 + 0.5;
		
		//uv translation
		distortion = endPixel.xy - startPixel;
	}
#endif

	//fog
#ifdef FOG_ENABLED
	vec4 fogColor = getFog(depth, -viewVec, viewPos);
	col = mix(col, fogColor.rgb, fogColor.a);
#endif

	//exposure
#ifdef EXPOSURE_ENABLED
	col = vec3(1.0) - exp(-col * exposure);
#endif
	
	//gamma correction
#ifdef GAMMA_ENABLED
	col = pow(col, vec3(1.0 / gamma));
#endif
	
	//alpha data and distortion
#ifdef AVERAGE_ENABLED
#ifdef REFRACTIONS_ENABLED
		love_Canvases[1] = vec4(distortion, 0.0, 1.0);
		love_Canvases[2] = vec4(1.0, albedo.a, 0.0, 1.0);
#else
		love_Canvases[1] = vec4(1.0, albedo.a, 0.0, 1.0);
#endif
#else
#ifdef REFRACTIONS_ENABLED
		//to allow distortion blending we use premultiplied alpha blending, which required manual rgb math here
		col *= albedo.a;
		
		love_Canvases[1] = vec4(distortion, 0.0, 0.0);
#endif
#endif
	
	//returns color
	love_Canvases[0] = vec4(col, albedo.a);
	
	//def
#ifndef REFRACTIONS_ENABLED
#ifndef AVERAGE_ENABLED
	love_Canvases[1] = vec4(depth, 0.0, 0.0, albedo.a);
#endif
#endif
}
#endif


#ifdef VERTEX
vec4 position(mat4 transform_projection, vec4 vertex_position) {
	vertexPos = vertex_position.xyz;
	normalRawV = VertexNormal;
	
#import modulesVertex
#import mainVertex
	
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