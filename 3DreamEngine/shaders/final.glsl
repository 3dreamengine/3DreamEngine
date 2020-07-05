extern Image canvas_color_pass2;
extern Image canvas_albedo;
extern Image canvas_normal;
extern Image canvas_normal_pass2;
extern Image canvas_position;
extern Image canvas_depth;
extern Image canvas_data_pass2;
extern Image canvas_material;

extern Image canvas_bloom;
extern Image canvas_ao;
extern Image canvas_SSR;

extern Image canvas_exposure;

extern CubeImage canvas_sky;
extern vec3 ambient;

extern mat4 transformInverse;
extern mat3 transformInverseSubM;
extern mat4 transform;
extern vec3 lookNormal;
extern vec3 viewPos;

extern float gamma;
extern float exposure;

extern float time;

extern float fog_baseline;
extern float fog_height;
extern float fog_density;
extern vec3 fog_color;

#ifdef AUTOEXPOSURE_ENABLED
varying float expo;
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
	vec2 tc_final = tc;
	
	//pass 2 data
#ifdef AVERAGE_ALPHA
	vec3 dat = Texel(canvas_data_pass2, tc).xyz;
	float ior, alpha;
	vec4 c2;
	if (dat.r < 0.5) {
		ior = 0.0;
		alpha = 1.0;
		c2 = vec4(0.0);
	} else {
		float f = 1.0 / dat.r;
		ior = dat.b * f;
		alpha = pow(1.0 - dat.g * f, dat.r);
#ifdef FXAA_ENABLED
		c2 = fxaa(canvas_color_pass2, tc) / dat.g;
#else
		c2 = Texel(canvas_color_pass2, tc) / dat.g;
#endif
		
		//refraction
#ifdef REFRACTION_ENABLED
		vec3 normal_pass2 = Texel(canvas_normal_pass2, tc).xyz;
		tc_final += (transform * vec4(viewPos + lookNormal + normal_pass2 * (ior - 1.0) * 0.25, 1.0)).xy;
#endif
	}
#endif
	
	
	//color
#ifdef FXAA_ENABLED
	vec4 c = fxaa(canvas_color, tc_final);
#else
	vec4 c = Texel(canvas_color, tc_final);
#endif
	
	//data
#ifdef DEFERRED_LIGHTING
	vec3 albedo = Texel(canvas_albedo, tc_final).xyz;
	vec3 position = Texel(canvas_position, tc_final).xyz;
	vec3 normal = Texel(canvas_normal, tc_final).xyz;
	vec3 material = Texel(canvas_material, tc_final).xyz;
	float depth = material.z;
#else
	float depth = Texel(canvas_depth, tc_final).r;
#endif

	//merge passes
#ifdef AVERAGE_ALPHA
	c.rgb = mix(c2.rgb, c.rgb, alpha);
	c.a = min(1.0, c.a + c2.a);
#endif
	
	//sky reflection
#ifdef SKY_ENABLED
	vec3 sky = textureLod(canvas_sky, mat3(transformInverseSubM) * vec3(tc_final*2.0-1.0, 1.0) * vec3(1.0, -1.0, 1.0), 0.0).rgb;
#endif
	
	//ao
#ifdef AO_ENABLED
	float ao = Texel(canvas_ao, tc_final).r;
	c.rgb *= ao;
#endif
	
	//bloom
#ifdef BLOOM_ENABLED
	vec3 bloom = Texel(canvas_bloom, tc_final).rgb;
	c.rgb += bloom;
#endif
	
	//screen space reflections merge
#ifdef SSR_ENABLED
	vec3 ref = Texel(canvas_SSR, tc_final).rgb;
	c.rgb += ref;
#endif

	//fog
#ifdef FOG_ENABLED
	float actualDepth = depth * mix(1.0, 2.0, length(tc - vec2(0.5)));
	float heightDensity_1 = 1.0 - clamp((viewPos.y - fog_baseline) * fog_height, 0.0, 1.0);
#ifdef DEFERRED_LIGHTING
	float heightDensity_2 = 1.0 - clamp((position.y - fog_baseline) * fog_height, 0.0, 1.0);
#else
	float heightDensity_2 = 1.0 - clamp((viewPos.y + lookNormal.y * actualDepth - fog_baseline) * fog_height, 0.0, 1.0);
#endif
	c.rgb = mix(c.rgb, fog_color, min(1.0, (heightDensity_1 + heightDensity_2) * 0.5 * fog_density * actualDepth));
#ifdef SKY_ENABLED
	sky.rgb = fog_color;
#endif
#endif
	
	//backgound
#ifdef SKY_ENABLED
	c.rgb = mix(sky.rgb, c.rgb, c.a);
	c.a = 1.0;
#endif
	
	//exposure
#ifdef POSTEFFECTS_ENABLED
#ifdef AUTOEXPOSURE_ENABLED
	c.rgb = vec3(1.0) - exp(-c.rgb * expo);
#else
#ifdef EXPOSURE_ENABLED
	c.rgb = vec3(1.0) - exp(-c.rgb * exposure);
#endif
#endif
	
	//gamma correction
	c.rgb = pow(c.rgb, vec3(1.0 / gamma));
#endif
	
	return vec4(c.rgb, c.a);
}
#endif

#ifdef VERTEX
	vec4 position(mat4 transform_projection, vec4 vertex_position) {
#ifdef AUTOEXPOSURE_ENABLED
		expo = max(0.0, Texel(canvas_exposure, VaryingTexCoord.xy).r * exposure);
#endif
		return transform_projection * vertex_position;
	}
#endif