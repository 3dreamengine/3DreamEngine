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
extern bool second_pass;
extern int lightCount;

varying vec3 normalVec;
 
//material 
varying float specular;
varying float glossiness;
varying float emission;


#ifdef PIXEL
#import reflections
#import lightEngine

//lighting
#import lightingSystemInit

extern float ior;

void effect() {
	vec4 albedo = VaryingColor;
	
	//dither alpha
	if (!second_pass && albedo.a < 1.0 && albedo.a < fract(vertexPos.x * 111.1 + vertexPos.y * 777.7 + vertexPos.z * 333.3)) {
		discard;
	}
	
	vec3 normal = normalize(normalVec);
	
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
attribute vec3 VertexMaterial;

#import animations

vec4 position(mat4 transform_projection, vec4 vertex_position) {
	highp vec4 pos = transform * animations(vertex_position);
	
	//pass raw vertex position to fragment shader
	vertexPos = pos.xyz;
	
	//projective transform for the vertex
	highp vec4 vPos = transformProj * pos;
	
	//extract normal vector
	normalVec = (transform * vec4(VertexTexCoord.xyz, 0.0)).xyz;
	
	//extract and pass depth
	depth = vPos.z;
	
	//extract material
	specular = VertexMaterial.r;
	glossiness = VertexMaterial.g;
	emission = VertexMaterial.b;
	
	return vPos;
}
#endif