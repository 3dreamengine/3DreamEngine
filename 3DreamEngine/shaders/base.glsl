#pragma language glsl3

//camera uniforms
extern highp mat4 transformProj;   //projective transformation
extern highp mat4 transform;       //model transformation
extern highp vec3 viewPos;         //camera position

//varyings
varying highp vec3 vertexPos;      //vertex position for pixel shader
varying float depth;               //depth
varying vec3 normalRawV;           //depth

//setting specific defines
#import globalDefines

//shader specific defines
#import vertexDefines
#import modulesDefines
#import mainDefines

#ifdef REFRACTIONS_ENABLED
extern Image tex_depth;
extern Image tex_color;
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
extern float isSemi;
extern float dither;

//reflection engine
#import reflections

//light function
#import lightFunction

//uniforms required by the lighting
#import lightingSystemInit

//material
extern float ior;
extern float translucent;

float whenLt(float x, float y) {
	return max(sign(y - x), 0.0);
}

void effect() {
#import mainPixelPre
	
	//dither alpha
#ifdef ALPHA_PASS
	if (abs(albedo.a - 0.495) * isSemi > 0.5) {
		discard;
	}
#else
#ifdef DISCARD_ENABLED
	if (albedo.a < mix(
			mix(
				0.5,
				fract(love_PixelCoord.x * 0.37 + love_PixelCoord.y * 73.73 + depth * 3.73),
				dither
			),
			0.99,
			isSemi
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
	vec3 col = vec3(0.0);
	
	//forward lighting
	vec3 light = vec3(0.0);
#import lightingSystem
	col += light;
	
#import mainPixelPost
#import modulesPixelPost

	//calculate refractions
#ifdef REFRACTIONS_ENABLED
	vec2 startPixel = love_PixelCoord.xy * screenScale;
	
	//refract and transform back to pixel coord
	vec3 endPoint = vertexPos + normalize(refract(-viewVec, normal, ior)) * 0.15;
	vec4 endPixel = transformProj * vec4(endPoint, 1.0);
	endPixel /= endPixel.w;
	endPixel.xy = endPixel.xy * 0.5 + 0.5;
	
	//uv translation
	vec2 vec = endPixel.xy - startPixel;
	
	//depth check
	float d = Texel(tex_depth, startPixel + vec).r;
	vec3 nc = Texel(tex_color, startPixel + vec * whenLt(0.0, d - depth)).xyz;
	col = mix(mix(nc, nc * albedo.rgb, albedo.a), col, albedo.a);
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
	
	//returns color
#ifdef REFRACTIONS_ENABLED
	love_Canvases[0] = vec4(col, 1.0);
#else
	love_Canvases[0] = vec4(col, albedo.a);
#endif
	
	//alpha data
#ifdef AVERAGE_ENABLED
#ifdef REFRACTIONS_ENABLED
		love_Canvases[1] = vec4(1.0, 1.0, depth, 1.0);
#else
		love_Canvases[1] = vec4(1.0, albedo.a, depth, 1.0);
#endif
#else
#ifndef REFRACTIONS_ENABLED
		love_Canvases[1] = vec4(depth, 0.0, 0.0, albedo.a);
#endif
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
	vec4 vPos = transformProj * vec4(vertexPos, 1.0);
	
	//extract and pass depth
	depth = vPos.z;
	
	return vPos;
}
#endif