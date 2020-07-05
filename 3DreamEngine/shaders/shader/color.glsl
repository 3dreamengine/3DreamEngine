//part of the 3DreamEngine by Luke100000
//flat base shader

//required for secondary depth buffer and AO
varying float depth;

//transformations
extern highp mat4 transformProj;          //projective transformation
extern highp mat4 transform;              //model transformation

extern highp vec3 viewPos;
extern highp vec3 lookNormal;             //camera normal

//viewer
varying highp vec3 vertexPos;             //vertex position for pixel shader

//shader settings
extern bool deferred_lighting;
extern bool average_alpha;
extern int lightCount;

varying vec3 normalVec;


#ifdef PIXEL
#import reflections
#import lightEngine

//lighting
#import lightingSystemInit

extern float emission;
extern float glossiness;

extern float ior;

void effect() {
	vec4 albedo = VaryingColor;
	
	//dither alpha
	if (!average_alpha) {
		albedo.a = step(fract(love_PixelCoord.x * 0.65 + love_PixelCoord.y * 73.73), albedo.a);
	}
	
	vec3 normal = normalize(normalVec);
	float specular = VaryingTexCoord.a;
	
	highp vec3 viewVec = normalize(viewPos - vertexPos);
	vec3 reflectVec = reflect(-viewVec, normal);
	vec3 diffuse = reflection(normal, 1.0);
	
	#ifdef SSR_ENABLED
		vec3 col = diffuse * albedo.rgb;
	#else
		vec3 ref = reflection(reflectVec, 1.0 - glossiness);
		vec3 col = (diffuse + ref * specular) * albedo.rgb;
	#endif
	
	//emission
	col += emission;
	
	//forward lighting
	#import lightingSystem
	
	//render
	if (deferred_lighting) {
		love_Canvases[0] = vec4(col, albedo.a);
		love_Canvases[1] = vec4(albedo.rgb, 1.0);
		love_Canvases[2] = vec4(normal, 1.0);
		love_Canvases[3] = vec4(vertexPos, 1.0);
		love_Canvases[4] = vec4(glossiness, specular, depth, 1.0);
	} else {
		if (average_alpha) {
			love_Canvases[0] = vec4(col * albedo.a + emission * 8.0, 1.0);
			love_Canvases[1] = vec4(1.0, albedo.a, ior, 1.0);
			#ifdef REFRACTION_ENABLED
				love_Canvases[2] = vec4(normal, 1.0);
			#endif
		} else {
			love_Canvases[0] = vec4(col + emission * 8.0, albedo.a);
			love_Canvases[1] = vec4(depth, 1.0, 1.0, 1.0);
		}
	}
}
#endif


#ifdef VERTEX

#import animations

vec4 position(mat4 transform_projection, vec4 vertex_position) {
	highp vec4 pos = transform * animations(vertex_position);
	
	//pass raw vertex position to fragment shader
	vertexPos = pos.xyz;
	
	//projective transform for the vertex
	highp vec4 vPos = transformProj * pos;
	
	//extract normal vector
	normalVec = mat3(transform) * (VertexTexCoord.xyz*2.0-1.0);
	
	//extract and pass depth
	depth = vPos.z;
	
	return vPos;
}
#endif