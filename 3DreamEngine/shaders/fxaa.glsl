//combined and modified code from https://github.com/mattdesl/glsl-fxaa

#define FXAA_REDUCE_MIN (1.0 / 128.0)
#define FXAA_REDUCE_MUL (1.0 / 8.0)
#define FXAA_SPAN_MAX (8.0)

vec4 effect(vec4 c, Image tex, vec2 tc, vec2 sc) {
	vec2 inverseVP = 1.0 / love_ScreenSize.xy;
	vec2 v_rgbNW = (tc + vec2(-1.0, -1.0) * inverseVP);
	vec2 v_rgbNE = (tc + vec2(1.0, -1.0) * inverseVP);
	vec2 v_rgbSW = (tc + vec2(-1.0, 1.0) * inverseVP);
	vec2 v_rgbSE = (tc + vec2(1.0, 1.0) * inverseVP);
	
	vec4 texColor = Texel(tex, tc);
	
	vec3 rgbNW = Texel(tex, v_rgbNW).xyz;
	vec3 rgbNE = Texel(tex, v_rgbNE).xyz;
	vec3 rgbSW = Texel(tex, v_rgbSW).xyz;
	vec3 rgbSE = Texel(tex, v_rgbSE).xyz;
	vec3 rgbM = texColor.xyz;
	
	vec3 luma = vec3(0.299, 0.587, 0.114);
	float lumaNW = dot(rgbNW, luma);
	float lumaNE = dot(rgbNE, luma);
	float lumaSW = dot(rgbSW, luma);
	float lumaSE = dot(rgbSE, luma);
	float lumaM  = dot(rgbM,  luma);
	
	float lumaMin = min(lumaM, min(min(lumaNW, lumaNE), min(lumaSW, lumaSE)));
	float lumaMax = max(lumaM, max(max(lumaNW, lumaNE), max(lumaSW, lumaSE)));
	
	mediump vec2 dir;
	dir.x = -((lumaNW + lumaNE) - (lumaSW + lumaSE));
	dir.y =  ((lumaNW + lumaSW) - (lumaNE + lumaSE));
	
	float dirReduce = max((lumaNW + lumaNE + lumaSW + lumaSE) * (0.25 * FXAA_REDUCE_MUL), FXAA_REDUCE_MIN);
	
	float rcpDirMin = 1.0 / (min(abs(dir.x), abs(dir.y)) + dirReduce);
	dir = min(vec2(FXAA_SPAN_MAX, FXAA_SPAN_MAX), max(vec2(-FXAA_SPAN_MAX, -FXAA_SPAN_MAX), dir * rcpDirMin)) * inverseVP;
	
	vec3 rgbA = 0.5 * (
		Texel(tex, tc + dir * (1.0 / 3.0 - 0.5)).xyz +
		Texel(tex, tc + dir * (2.0 / 3.0 - 0.5)).xyz);
	
	vec3 rgbB = rgbA * 0.5 + 0.25 * (
		Texel(tex, tc + dir * -0.5).xyz +
		Texel(tex, tc + dir * 0.5).xyz);
	
	float lumaB = dot(rgbB, luma);
	if ((lumaB < lumaMin) || (lumaB > lumaMax)) {
		return vec4(rgbA, texColor.a);
	} else {
		return vec4(rgbB, texColor.a);
	}
}