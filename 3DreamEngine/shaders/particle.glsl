#pragma language glsl3

varying float VaryingEmission;
varying vec3 vertexPos;
varying float depth;

//setting specific defines
#import globalDefines


#ifdef PIXEL
extern highp vec3 viewPos;

#ifdef TEX_EMISSION
extern Image tex_emission;
#endif

#import fog

#ifdef EXPOSURE_ENABLED
extern float exposure;
#endif

#ifdef GAMMA_ENABLED
extern float gamma;
#endif

//uniforms required by the lighting
#import lightingSystemInit

extern Image MainTex;
extern bool dataAlpha;

void effect() {
	vec3 viewVec = normalize(viewPos - vertexPos);
	vec2 tc = vec2(texture_coords.x, 1.0 - texture_coords.y);
	
	//fetch color
	vec4 albedo = Texel(MainTex, tc);
	
	if (albedo.a <= 0.0) {
		discard;
	}
	
	//emission
#ifdef TEX_EMISSION
	vec3 emission = Texel(tex_emission, tc).rgb;
	vec3 col = emission * VaryingEmission;
#else
	vec3 col = albedo.rgb * VaryingEmission;
#endif
	
	//forward lighting
	albedo *= VaryingColor;
	if (length(albedo.rgb) > 0.0) {
		vec3 light = vec3(0.0);
#import lightingSystem
		col += light * albedo.rgb * albedo.a;
	}
	
	//fog (moving this to vertex had negative results)
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

	love_Canvases[0] = vec4(col, albedo.a);
	if (dataAlpha) {
		love_Canvases[1] = vec4(1.0, albedo.a, depth, 1.0);
	} else {
		love_Canvases[1] = vec4(depth, 1.0, 1.0, albedo.a);
	}
}
#endif

#ifdef VERTEX
extern vec3 InstanceCenter;
extern float InstanceEmission;

extern mat4 transformProj;
extern vec3 up;
extern vec3 right;

vec4 position(mat4 transform_projection, vec4 vertex_position) {
	VaryingEmission = InstanceEmission;
	
	vertexPos = InstanceCenter + (right * vertex_position.x + up * vertex_position.y);
	
	vec4 vPos = transformProj * vec4(vertexPos, 1.0);
	
	//extract and pass depth
	depth = vPos.z;
	
	return vPos;
}
#endif