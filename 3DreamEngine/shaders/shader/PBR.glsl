//part of the 3DreamEngine by Luke100000
//textured base shader

//transformations
extern highp mat4 transformProj;          //projective transformation
extern highp mat4 transform;              //model transformation

extern highp vec3 viewPos;
extern highp vec3 lookNormal;             //camera normal

varying highp vec3 vertexPos;             //vertex position for pixel shader
varying float depth;                      //depth

//shader settings
extern bool deferred_lighting;
extern bool second_pass;
extern int lightCount;

#ifdef TEX_NORMAL
	varying mat3 objToWorldSpace;
#else
	varying vec3 normal;
#endif


#ifdef PIXEL
#import reflections
#import lightEngine
#import lightingSystemInit

extern Image brdfLUT;

//material
extern Image tex_albedo;
extern Image tex_combined;
extern vec3 color_combined;
extern Image tex_emission;
extern vec3 color_emission;
extern Image tex_normal;
extern float ior;

//rain
extern Image rain_splashes;
extern Image rain_tex_wetness;
extern float rain_wetness;

void effect() {
	vec4 albedo = Texel(tex_albedo, VaryingTexCoord.xy) * VaryingColor;
	
	//dither alpha
	if (!second_pass) {
		albedo.a = step(fract(love_PixelCoord.x * 0.37 + love_PixelCoord.y * 73.73 + depth * 3.73), albedo.a);
	}
	
	//hidden
	if (albedo.a <= 0.0) {
		discard;
	}
	
	//transform normal to world space
	#ifdef TEX_NORMAL
		vec3 normal = normalize(objToWorldSpace * normalize(Texel(tex_normal, VaryingTexCoord.xy).rgb - 0.5));
	#endif
	
	//fetch material data
	vec3 rma = Texel(tex_combined, VaryingTexCoord.xy).rgb * color_combined;
	float roughness = rma.r;
	float metallic = rma.g;
	float ao = rma.b;
	
	//emission
	#ifdef TEX_EMISSION
		vec3 emission = Texel(tex_emission, VaryingTexCoord.xy).rgb * color_emission;
	#else
		vec3 emission = color_emission;
	#endif
	
	//PBR model data
	vec3 viewVec = normalize(viewPos - vertexPos);
	vec3 reflectVec = reflect(-viewVec, normal); 
	float cosTheta = max(dot(normal, viewVec), 0.0);
	vec3 F0 = mix(vec3(0.04), albedo.rgb, metallic);
	
	//fresnel
    vec3 F = F0 + (max(vec3(1.0 - roughness), F0) - F0) * pow(1.0 - cosTheta, 5.0);
    
	//specular and diffuse component
    vec3 kS = F;
    vec3 kD = (1.0 - kS) * (1.0 - metallic);
    
	//use the reflection texture as irradiance map approximation
    vec3 diffuse = reflection(normal, 1.0) * albedo.rgb;
	
	//final ambient color, screen space reflection disables reflections
	#ifdef SSR_ENABLED
		vec3 col = (kD * diffuse) * ao;
	#else
		//approximate the specular part with brdf lookup table
		vec3 ref = reflection(reflectVec, roughness);
		vec2 brdf = Texel(brdfLUT, vec2(cosTheta, roughness)).rg;
		vec3 specular = ref * (F * brdf.x + vec3(brdf.y));
		
		vec3 col = (kD * diffuse + specular) * ao;
	#endif
	
	//emission
	col += emission;
	
	//rain
	#ifdef RAIN_ENABLED
		vec3 rainNormal = normalize(Texel(rain_splashes, vertexPos.xz).xyz);
		float impactStrength = (1.0 - rainNormal.z);
		
		float rainNoise = Texel(rain_tex_wetness, vertexPos.xz * 0.17).r;
		float rain = clamp((normal.y * 1.1 - 0.1) * clamp(rain_wetness * 1.5 - rainNoise + impactStrength * 2.0, 0.0, 1.0), 0.0, 1.0);
		
		#ifdef TEX_NORMAL
			normal = normalize(mix(normal, rainNormal.xzy, rain));
		#endif
		roughness = mix(roughness, 0.0, rain * 0.75);
		
		#ifndef SSR_ENABLED
			col = mix(col, col * 0.5 + reflection(reflect(-viewVec, rainNormal), 0.0), rain * 0.5);
		#endif
	#endif
	
	//forward lighting
	#import lightingSystem
	
	//render
	if (deferred_lighting) {
		love_Canvases[0] = vec4(col, albedo.a);
		love_Canvases[1] = vec4(albedo.rgb, 1.0);
		love_Canvases[2] = vec4(normal, 1.0);
		love_Canvases[3] = vec4(vertexPos, 1.0);
		love_Canvases[4] = vec4(roughness, metallic, depth, 1.0);
	} else {
		if (second_pass) {
			love_Canvases[0] = vec4(col * albedo.a, 1.0);
			love_Canvases[1] = vec4(1.0, albedo.a, ior, 1.0);
			#ifdef REFRACTION_ENABLED
				love_Canvases[2] = vec4(normal, 1.0);
			#endif
		} else {
			love_Canvases[0] = vec4(col, albedo.a);
			love_Canvases[1] = vec4(depth, 1.0, 1.0, 1.0);
		}
	}
}
#endif


#ifdef VERTEX

#import animations

//additional vertex attributes
attribute highp vec3 VertexNormal;
attribute highp vec3 VertexTangent;
attribute highp vec3 VertexBiTangent;

extern vec4 color_albedo;

vec4 position(mat4 transform_projection, vec4 vertex_position) {
	highp vec4 pos = transform * animations(vertex_position);
	
	//transform from tangential space into world space
	mat3 normalTransform = mat3(transform);
	#ifdef TEX_NORMAL
		vec3 T = normalize(normalTransform * (VertexTangent*2.0-1.0));
		vec3 N = normalize(normalTransform * (VertexNormal*2.0-1.0));
		vec3 B = normalize(normalTransform * (VertexBiTangent*2.0-1.0));
		
		objToWorldSpace = mat3(T, B, N);
	#else
		normal = normalize(normalTransform * (VertexNormal*2.0-1.0));
	#endif
	
	vertexPos = pos.xyz;
	
	//projection transform for the vertex
	highp vec4 vPos = transformProj * pos;
	
	//extract and pass depth
	depth = vPos.z;
	
	//color
	VaryingColor = color_albedo * ConstantColor;
	
	return vPos;
}
#endif