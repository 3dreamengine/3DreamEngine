#pragma language glsl3

//camera uniforms
extern highp mat4 transformProj;   //projective transformation
extern highp mat4 transform;       //model transformation
extern highp vec3 viewPos;         //camera position

//varyings
varying highp vec3 VertexPos;      //vertex position for pixel shader
varying highp vec3 VaryingNormal;  //vertex normal for pixel shader
varying float depth;               //depth

extern float translucent;

extern float shadowDistanceFactor;

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
	vec3 viewVec = normalize(VertexPos - viewPos);
	vec2 distortion = vec2(0.0);
	vec3 color = vec3(0.0);
	vec3 light = vec3(0.0);
	
	//material
	vec3 normal;
	vec3 fragmentNormal = normalize(VaryingNormal);
	vec3 albedo = vec3(0.5);
	float alpha = 1.0;
	float roughness = 0.5;
	float metallic = 0.0;
	float ao = 1.0;
	vec3 emission = vec3(0.0);
	
#import pixelMaterial
	
	//proper backfaces
	if (dot(normal, viewVec) > 0.0) {
		//normal = normalize(reflect(normal, normalize(VaryingNormal)));
		//fragmentNormal = -fragmentNormal;
	}
	
#import pixel
	
	//fog
#ifdef FOG_ENABLED
	vec4 fogColor = getFog(depth, viewVec, viewPos);
	color = mix(color, fogcolor, fogColor.a);
#endif
	
	//exposure
#ifdef EXPOSURE_ENABLED
	color = vec3(1.0) - exp(-color * exposure);
#endif
	
	//gamma correction
#ifdef GAMMA_ENABLED
	color = pow(color, vec3(1.0 / gamma));
#endif
	
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
	love_Canvases[0] = vec4(depth * shadowDistanceFactor, depth * shadowDistanceFactor, 0.0, 1.0);
#else
	float dd = length(viewPos - VertexPos.xyz) * shadowDistanceFactor;
	love_Canvases[0] = vec4(dd, dd, 0.0, 1.0);
#endif
#else
	love_Canvases[0] = vec4(color, alpha);
#endif
}
#endif


#ifdef VERTEX


#ifdef INSTANCING
attribute vec3 InstanceRotation0;
attribute vec3 InstanceRotation1;
attribute vec3 InstanceRotation2;
attribute vec3 InstancePosition;
#endif

attribute vec3 VertexNormal;
#ifdef TANGENT
attribute vec4 VertexTangent;
#endif

vec4 position(mat4 _t, vec4 _v) {
	//normal vec transformation
	mat3 normalTransform = mat3(transform);
	
#ifdef INSTANCING
	mat3 instanceRotation = mat3(
		InstanceRotation0.xyz,
		InstanceRotation1.xyz,
		InstanceRotation2.xyz
	);
	
	VertexPos = instanceRotation * VertexPosition.xyz + InstancePosition;
	
	normalTransform = instanceRotation * normalTransform;
#else
	VertexPos = VertexPosition.xyz;
#endif
	
#import vertex
	
	//apply projection matrix
	vec4 vPos = transformProj * vec4(VertexPos, 1.0);
	
	//extract and pass depth
	depth = vPos.z;
	
	//raw normal vector without normal map;
	VaryingNormal = normalTransform * (VertexNormal - vec3(0.5));
	
#ifdef TANGENT
	vec3 T = normalize(normalTransform * (VertexTangent.xyz - vec3(0.5)));
	vec3 N = normalize(VaryingNormal);
	
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