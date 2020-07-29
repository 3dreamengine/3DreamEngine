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
extern bool average_alpha;
extern bool useAlphaDither;
extern float pass;
extern int lightCount;

#ifdef TEX_NORMAL
	varying mat3 objToWorldSpace;
#else
	varying vec3 normalV;
#endif


#ifdef PIXEL
#import reflections
#import lightEngine
#import lightingSystemInit

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
	if (useAlphaDither) {
		albedo.a = step(fract(love_PixelCoord.x * 0.37 + love_PixelCoord.y * 73.73 + depth * 3.73), albedo.a);
	} else if (albedo.a < 0.99 && pass < 0.0 || albedo.a >= 0.99 && pass > 0.0) {
		discard;
	}
	
	//hidden
	if (albedo.a <= 0.0) {
		discard;
	}
	
	if (pass == 0.0) {
		albedo.a = 1.0;
	}
	
	//transform normal to world space
	#ifdef TEX_NORMAL
		vec3 normal = normalize(objToWorldSpace * normalize(Texel(tex_normal, VaryingTexCoord.xy).rgb - 0.5));
	#else
		vec3 normal = normalize(normalV);
	#endif
	
	//fetch material data
	vec3 rma = Texel(tex_combined, VaryingTexCoord.xy).rgb * color_combined;
	float glossiness = rma.r;
	float specular = rma.g;
	float ao = rma.b;
	
	//emission
	#ifdef TEX_EMISSION
		vec3 emission = Texel(tex_emission, VaryingTexCoord.xy).rgb * color_emission;
	#else
		vec3 emission = color_emission;
	#endif
	
	vec3 viewVec = normalize(viewPos - vertexPos);
	vec3 reflectVec = reflect(-viewVec, normal); 
	
	//ambient component
	vec3 diffuse = reflection(normal, 1.0);
	
	//final ambient color, screen space reflection disables reflections
	#ifdef SSR_ENABLED
		vec3 col = diffuse * albedo.rgb * ao;
	#else
		vec3 ref = reflection(reflectVec, 1.0 - glossiness);
		vec3 col = (diffuse + ref * specular) * albedo.rgb * ao;
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
		glossiness = mix(glossiness, 1.0, rain * 0.75);
		specular = mix(specular, 1.0, rain * 0.75);
		
		#ifndef SSR_ENABLED
			col = mix(col, col * 0.5 + reflection(reflect(-viewVec, rainNormal), 0.0), rain * 0.5);
		#endif
	#endif
	
	//forward lighting
	#import lightingSystem
	
	//render
	if (average_alpha) {
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
		normalV = normalTransform * (VertexNormal*2.0-1.0);
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