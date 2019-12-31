#ifdef PIXEL
extern Image normal;
extern Image reflectiness;
extern Image diffuse;

extern Image background_day;
extern Image background_night;

extern float background_time;
extern vec3 background_color;

vec4 effect(vec4 c, Image SSR, vec2 tc, vec2 sc) {
	//get reflected normal
	highp vec3 n = Texel(normal, tc).xyz * 2.0 + 1.0;
	
	//get UV coord
	float u = atan(n.x, n.z) * 0.1591549430919 + 0.5;
	float v = n.y * 0.5 + 0.5;
	mediump vec2 uv = 1.0 - vec2(u, v);
	
	//blend
	mediump vec3 reflection = mix(Texel(background_day, uv), Texel(background_night, uv), background_time).rgb * background_color;
	
	float ref = Texel(reflectiness, tc).r;
	
	vec2 reflectedPixel = Texel(SSR, tc).xy;
	
	vec2 sz = 1.0 / love_ScreenSize.xy;
	
	float fade = clamp((
		Texel(SSR, tc + vec2(1.2659626133539, 1.5483341569539) * sz).z + 
		Texel(SSR, tc + vec2(-0.099833416646828, 0.99500416527803) * sz).z + 
		Texel(SSR, tc + vec2(-1.5483341569539, 1.2659626133539) * sz).z + 
		Texel(SSR, tc + vec2(-0.99500416527803, -0.099833416646828) * sz).z + 
		Texel(SSR, tc + vec2(-1.2659626133539, -1.5483341569539) * sz).z + 
		Texel(SSR, tc + vec2(0.099833416646828, -0.99500416527803) * sz).z + 
		Texel(SSR, tc + vec2(1.5483341569539, -1.2659626133539) * sz).z + 
		Texel(SSR, tc + vec2(0.99500416527803, 0.099833416646828) * sz).z
	) * 0.5 - 2.0, 0.0, 1.0);
	
	return Texel(diffuse, tc) + vec4(mix(reflection, Texel(diffuse, reflectedPixel).rgb, fade) * ref, 0.0);;
}
#endif