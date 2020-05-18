//part of the 3DreamEngine by Luke100000
//light.glsl - lighting core, point or sun source, batched

#ifdef PIXEL
//viewer
extern highp vec3 viewPos;

extern Image tex_normal;
extern Image tex_position;
extern Image tex_material;

//lighting
extern highp vec3 lightPos[MAX_LIGHTS];
extern lowp vec3 lightColor[MAX_LIGHTS];
extern float lightMeter[MAX_LIGHTS];
extern int lightCount;

#import lightEngine

vec4 effect(vec4 c, Image tex_color, vec2 tc, vec2 sc) {
	vec3 vertexPos = Texel(tex_position, tc).xyz;
	vec3 normal = normalize(Texel(tex_normal, tc).xyz);
	vec4 albedo = Texel(tex_color, tc);
	
	vec3 material = Texel(tex_material, tc).rgb;
	float roughness = material.r;
	float metallic = material.g;
	
	vec3 viewVec = normalize(viewPos - vertexPos);
	
	vec3 col = vec3(0.0);
	for (int i = 0; i < lightCount; i++) {
		if (lightMeter[i] > 0.0) {
			vec3 lightVecRaw = lightPos[i] - vertexPos;
			vec3 lightVec = normalize(lightVecRaw);
			float distance = length(lightVecRaw) * lightMeter[i];
			float power = 1.0 / (0.1 + distance * distance);
			col += getLight(lightColor[i] * power, viewVec, lightVec, normal, albedo.rgb, roughness, metallic) * albedo.a;
		} else {
			vec3 lightVec = normalize(lightPos[i]);
			col += getLight(lightColor[i], viewVec, lightVec, normal, albedo.rgb, roughness, metallic) * albedo.a;
		}
	}
	
	//pass color to canvas
	return vec4(col, 1.0);
}
#endif