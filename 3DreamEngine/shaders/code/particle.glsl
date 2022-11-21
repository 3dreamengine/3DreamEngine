#pragma language glsl3

varying float VaryingEmission;
varying float VaryingDistortion;
varying vec3 vertexPos;
varying float depth;

//setting specific defines
#import defines



#ifdef PIXEL
extern highp vec3 viewPos;

#ifdef EMISSION_TEXTURE
extern Image emissionTexture;
#endif

#ifdef DISTORTION_TEXTURE
extern Image distortionTexture;
#endif

#import fog

//uniforms required by the lighting
#import lightingSystemInit

extern vec3 ambient;

extern Image MainTex;

void effect() {
	vec3 viewVec = normalize(vertexPos - viewPos);
	
	//fetch color
	vec4 albedo = gammaCorrectedTexel(MainTex, VaryingTexCoord.xy);

#ifdef DEPTH_ENABLED
	if (albedo.a <= 0.5) {
		discard;
	} else {
		albedo.a = 1.0;
	}
#endif
	
	//emission
#ifdef EMISSION_TEXTURE
	vec3 emission = gammaCorrectedTexel(emissionTexture, VaryingTexCoord.xy).rgb;
	vec3 color = emission * VaryingEmission;
#else
	vec3 color = albedo.rgb * VaryingEmission;
#endif
	
#ifdef DISTORTION_TEXTURE
	vec2 distortion = (Texel(distortionTexture, VaryingTexCoord.xy).xy * 2.0 - 1.0) * VaryingDistortion;
#else
	vec2 distortion = vec2(0.0);
#endif
	
	//forward lighting
	albedo *= VaryingColor;
	if (length(albedo.rgb) > 0.0) {
		vec3 light = vec3(0.0);
#import lightingSystem
		color += light * albedo.rgb * albedo.a;
	}
	
	//ambient lighting
	color += ambient;
	
	//fog
#ifdef FOG_ENABLED
	vec4 fogColor = getFog(depth, viewVec, viewPos);
	color = mix(color, fogColor.rgb, fogColor.a);
#endif

#ifdef GAMMA_CORRECTION
	color.rgb = pow(color.rgb, vec3(1.0 / 2.2));
#endif

#ifdef REFRACTIONS_ENABLED
	//to allow distortion blending we use premultiplied alpha blending, which required manual rgb math here
	color *= albedo.a;
	
	love_Canvases[1] = vec4(distortion, 0.0, 0.0);
#endif

	//depth
#ifdef DEPTH_ENABLED
	love_Canvases[1] = vec4(depth, 0.0, 0.0, 1.0);
#endif
	
	//color
	love_Canvases[0] = vec4(color, albedo.a);
}
#endif



#ifdef VERTEX

#ifdef SINGLE
extern vec3 InstanceCenter;
extern float InstanceEmission;
extern float InstanceDistortion;
#else
attribute vec3 InstanceCenter;
attribute float InstanceEmission;
attribute float InstanceDistortion;
attribute vec2 InstanceSize;
attribute float InstanceRotation;
attribute vec2 InstanceTexScale;
attribute vec2 InstanceTexOffset;
attribute vec4 InstanceColor;
#endif

extern mat4 transformProj;
extern vec3 up;
extern vec3 right;

vec4 position(mat4 transform_projection, vec4 VertexPosition) {
#ifdef SINGLE
	VaryingTexCoord = vec4(VertexTexCoord.x, 1.0 - VertexTexCoord.y, 0.0, 0.0);
	
	vertexPos = InstanceCenter + (right * VertexPosition.x + up * VertexPosition.y);
#else
	VaryingTexCoord = vec4(VertexTexCoord.xy * InstanceTexScale + InstanceTexOffset, 0.0, 0.0);
	VaryingColor = InstanceColor;
	
	//rotate
	float c = cos(InstanceRotation);
	float s = sin(InstanceRotation);
	vec2 p = vec2(
		VertexPosition.x * c - VertexPosition.y * s,
		VertexPosition.x * s + VertexPosition.y * c
	);
	
	vertexPos = InstanceCenter + (right * p.x * InstanceSize.x + up * p.y * InstanceSize.y);
#endif

	VaryingEmission = InstanceEmission;
	VaryingDistortion = InstanceDistortion;
	
	vec4 vPos = transformProj * vec4(vertexPos, 1.0);
	
	//extract and pass depth
	depth = vPos.z;
	
	return vPos;
}
#endif