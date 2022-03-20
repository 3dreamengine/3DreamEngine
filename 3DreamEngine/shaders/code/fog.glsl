extern float fog_density;
extern float fog_scatter;
extern vec3 fog_color;
extern vec3 fog_sun;
extern vec3 fog_sunColor;
extern float fog_max;
extern float fog_min;

vec4 getFog(float depth, vec3 viewVec, vec3 viewPos) {
	if (fog_max > fog_min) {
		vec3 vec = viewVec * depth;
		vec3 stepVec = vec / vec.y;
		
		//ray
		vec3 pos_near = viewPos;
		vec3 pos_far = viewPos + vec;
		
		//find entry/exit heights
		float height_near = clamp(pos_near.y, fog_min, fog_max);
		float height_far = clamp(pos_far.y, fog_min, fog_max);
		
		//find points
		pos_near += stepVec * (height_near - pos_near.y);
		pos_far += stepVec * (height_far - pos_far.y);
		
		//get average density
		float heightDiff = fog_max - fog_min;
		float nearDensity = 1.0 - (height_near - fog_min) / heightDiff;
		float farDensity = 1.0 - (height_far - fog_min) / heightDiff;
		depth = distance(pos_far, pos_near) * (farDensity + nearDensity) * 0.5;
	}
	
	//finish fog
	float fog = 1.0 - exp(-depth * fog_density);
	if (fog_scatter > 0.0) {
		float fog_sunStrength = max(dot(fog_sun, normalize(viewVec)), 0.0);
		vec3 fogColor = fog_color + fog_sunColor * pow(fog_sunStrength, 8.0) * fog_scatter;
		return vec4(fogColor, fog);
	} else {
		return vec4(fog_color, fog);
	}
}