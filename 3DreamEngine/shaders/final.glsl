extern Image canvas_depth;

extern Image canvas_bloom;
extern Image canvas_ao;

extern Image canvas_alpha;
extern Image canvas_distortion;
extern Image canvas_alphaData;

extern Image canvas_exposure;

extern vec3 viewPos;

extern float gamma;
extern float exposure;

#ifdef FOG_ENABLED
varying vec3 viewVec;
extern mat4 transformInverse;
#endif

#ifdef AUTOEXPOSURE_ENABLED
varying float eyeAdaption;
#endif

#ifdef FXAA_ENABLED
#define FXAA_REDUCE_MIN (1.0 / 128.0)
#define FXAA_REDUCE_MUL (1.0 / 8.0)
#define FXAA_SPAN_MAX (8.0)

//combined and modified code from https://github.com/mattdesl/glsl-fxaa
vec4 fxaa(Image tex, vec2 tc) {
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
#endif



#ifdef PIXEL
vec4 effect(vec4 color, Image canvas_color, vec2 tc, vec2 sc) {
	//distortion
	vec2 tcd = tc;
#ifdef REFRACTIONS_ENABLED
	vec2 distortion = Texel(canvas_distortion, tc).xy;
	tcd = tc + distortion;
#endif
	
	//color
#ifdef FXAA_ENABLED
	vec4 col = fxaa(canvas_color, tcd);
#else
	vec4 col = Texel(canvas_color, tcd);
#endif
	
	//ao
#ifdef AO_ENABLED
	float ao = Texel(canvas_ao, tcd).r;
	col.rgb *= ao;
#endif
	
	//fetch depth for fog
#ifdef FOG_ENABLED
	float depth = Texel(canvas_depth, tcd).r;
#endif

	//average alpha
#ifdef AVERAGE_ALPHA
	vec2 dat = Texel(canvas_alphaData, tc).xy;
	if (dat.y > 0.0) {
#ifdef FXAA_ENABLED
		vec4 ca = fxaa(canvas_alpha, tc);
#else
		vec4 ca = Texel(canvas_alpha, tc);
#endif
		ca.rgb = ca.rgb / dat.y;
		ca.a = dat.y / dat.x;
		col.rgb = mix(col.rgb, ca.rgb, ca.a);
		col.a = col.a * (1.0 - ca.a) + ca.a;
	}
#endif
	
	//simple alpha
#ifdef REFRACTIONS_ENABLED
#ifdef FXAA_ENABLED
	vec4 ca = fxaa(canvas_alpha, tc);
#else
	vec4 ca = Texel(canvas_alpha, tc);
#endif
	col.rgb = mix(col.rgb, ca.rgb, ca.a);
	col.a = col.a * (1.0 - ca.a) + ca.a;
#endif
	
	//bloom
#ifdef BLOOM_ENABLED
	vec3 bloom = Texel(canvas_bloom, tcd).rgb;
	col.rgb += bloom;
#endif

	//fog
#ifdef FOG_ENABLED
	vec4 fogColor = getFog(depth, viewVec, viewPos);
	col.rgb = mix(col.rgb, fogColor.rgb, fogColor.a);
#endif
	
	//additional post effects
#ifdef POSTEFFECTS_ENABLED
	
	//eye adaption
#ifdef AUTOEXPOSURE_ENABLED
	col.rgb *= eyeAdaption;
#endif
	
	//exposure
#ifdef EXPOSURE_ENABLED
	col.rgb = vec3(1.0) - exp(-col.rgb * exposure);
#endif
	
	//gamma correction
#ifdef GAMMA_ENABLED
	col.rgb = pow(col.rgb, vec3(1.0 / gamma));
#endif
#endif
	
	return col * color;
}
#endif

#ifdef VERTEX
	vec4 position(mat4 transform_projection, vec4 vertex_position) {
#ifdef AUTOEXPOSURE_ENABLED
		eyeAdaption = Texel(canvas_exposure, vec2(0.5, 0.5)).r;
#endif
		vec4 pos = transform_projection * vertex_position;
#ifdef FOG_ENABLED
		viewVec = (transformInverse * vec4(pos.x, - pos.y, 1.0, 1.0)).xyz;
#endif
		return pos;
	}
#endif