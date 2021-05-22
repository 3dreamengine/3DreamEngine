#pragma language glsl3

//camera uniforms
extern highp mat4 transformProj;   //projective transformation
extern highp mat4 objectTransform; //model transformation
extern highp vec3 viewPos;         //camera position

//varyings
varying highp vec3 vertexPos;      //vertex position for pixel shader
varying highp vec3 vertexNormal;   //vertex normal for pixel shader
varying float depth;               //depth

extern float translucent;

//shader specific defines
#import defines

#ifdef TANGENT
varying mat3 TBN;
#endif

#ifdef DEPTH_AVAILABLE
extern Image tex_depth;
#endif

#ifdef PIXEL
void effect() {
	vec3 viewVec = normalize(vertexPos - viewPos);
	vec2 distortion = vec2(0.0);
	vec3 color = vec3(0.0);
	vec3 light = vec3(0.0);
	
	//material
	vec3 normal;
	vec3 fragmentNormal = normalize(vertexNormal);
	vec3 albedo = vec3(0.5);
	float alpha = 1.0;
	float roughness = 0.5;
	float metallic = 0.0;
	float ao = 1.0;
	vec3 emission = vec3(0.0);
	vec3 caustics = vec3(0.0);
	
#import pixelMaterial
	
	//proper backfaces
	if (dot(vertexNormal, viewVec) > 0.0) {
		normal = normalize(reflect(normal, normalize(vertexNormal)));
		fragmentNormal = -fragmentNormal;
	}
	
#import pixel
	
	//distortion
#ifdef REFRACTIONS_ENABLED
	//to allow distortion blending we use premultiplied alpha blending, which required manual rgb math here
	color *= alpha;
	love_Canvases[1] = vec4(distortion, 0.0, 0.0);
#endif
	
	//depth
#ifdef DEPTH_ENABLED
	love_Canvases[1] = vec4(depth, 0.0, 0.0, 1.0);
#endif
	
	//returns color
#ifdef IS_SHADOW
#ifdef IS_SUN
	love_Canvases[0] = vec4(depth, depth, 0.0, 1.0);
#else
	float dd = length(viewPos - vertexPos.xyz);
	love_Canvases[0] = vec4(dd, dd, 0.0, 1.0);
#endif
#else
	love_Canvases[0] = vec4(color, alpha);
#endif
}
#endif


#ifdef VERTEX

attribute vec3 VertexNormal;
#ifdef TANGENT
attribute vec4 VertexTangent;
#endif

vec4 position(mat4 _, vec4 vertex_position) {
	mat4 transform = objectTransform;
#import vertex
	
	//apply projection matrix
	vec4 vPos = transformProj * vec4(vertexPos, 1.0);
	
	//extract and pass depth
	depth = vPos.z;
	
	//we can safely assume that the transform always exists
	mat3 normalTransform = mat3(transform);
	
	//raw normal vector without normal map;
	vertexNormal = normalTransform * (VertexNormal - 0.5);
	
#ifdef TANGENT
	vec3 T = normalize(normalTransform * (VertexTangent.xyz - 0.5));
	vec3 N = normalize(vertexNormal);
	
	//in case the UV is mirrored
	vec3 B;
	if (VertexTangent.w > 0.5) {
		B = cross(T, N);
	} else {
		B = cross(N, T);
	}
	
	//construct the tangent to world matrix
	//in case no normal map is used, opengl will remove this
	TBN = mat3(T, B, N);
#endif
	
	//return the transformed position
	return vPos;
}
#endif