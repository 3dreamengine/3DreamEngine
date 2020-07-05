//part of the 3DreamEngine by Luke100000
//sun.glsl - sun shadows

extern float factor;
extern float shadowDistance;
extern float texelSize;

float sampleShadowSun2(sampler2DShadow tex, vec3 shadowUV) {
	float ox = float(fract(love_PixelCoord.x * 0.5) > 0.25);
	float oy = float(fract(love_PixelCoord.y * 0.5) > 0.25) + ox;
	if (oy > 1.1) oy = 0.0;
	
	return (
		texture(tex, shadowUV + vec3(-1.5 + ox, 0.5 + oy, 0.0) * texelSize) +
		texture(tex, shadowUV + vec3(0.5 + ox, 0.5 + oy, 0.0) * texelSize) +
		texture(tex, shadowUV + vec3(-1.5 + ox, -1.5 + oy, 0.0) * texelSize) +
		texture(tex, shadowUV + vec3(0.5 + ox, -1.5 + oy, 0.0) * texelSize)
	) * 0.25;
}

float sampleShadowSun(vec3 vertexPos, mat4 transformProjShadow_1, mat4 transformProjShadow_2, mat4 transformProjShadow_3, sampler2DShadow tex_shadow_1, sampler2DShadow tex_shadow_2, sampler2DShadow tex_shadow_3) {
	float bias = 0.0005;
	vec4 vertexPosShadow;
	vec3 shadowUV;
	float dist = distance(vertexPos, viewPos) * shadowDistance;
	
	if (dist < 1.0) {
		vertexPosShadow = transformProjShadow_1 * vec4(vertexPos.xyz, 1.0);
		shadowUV = vertexPosShadow.xyz - vec3(0.0, 0.0, bias);
		return sampleShadowSun2(tex_shadow_1, shadowUV * 0.5 + 0.5);
	} else if (dist < factor) {
		vertexPosShadow = transformProjShadow_2 * vec4(vertexPos.xyz, 1.0);
		shadowUV = vertexPosShadow.xyz - vec3(0.0, 0.0, bias * factor);
		return sampleShadowSun2(tex_shadow_2, shadowUV * 0.5 + 0.5);
	} else {
		vertexPosShadow = transformProjShadow_3 * vec4(vertexPos.xyz, 1.0);
		shadowUV = vertexPosShadow.xyz - vec3(0.0, 0.0, bias * factor * factor);
		return sampleShadowSun2(tex_shadow_3, shadowUV * 0.5 + 0.5);
	}
}