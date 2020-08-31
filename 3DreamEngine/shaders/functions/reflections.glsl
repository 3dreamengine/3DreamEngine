extern samplerCube tex_background;
extern float reflections_levels;

extern bool reflections_enabled;
extern vec3 reflections_pos;
extern vec3 reflections_first;
extern vec3 reflections_second;

vec3 reflection(vec3 ref, float roughness) {
	vec3 r;
	if (reflections_enabled) {
		vec3 maxIntersect = (reflections_second - vertexPos) / ref;
		vec3 minIntersect = (reflections_first - vertexPos) / ref;
		vec3 largestRayParams = max(maxIntersect, minIntersect);
		float dist = min(min(largestRayParams.x, largestRayParams.y), largestRayParams.z);
		r = vertexPos + ref * dist - reflections_pos;
	} else {
		r = ref;
	}
	return textureLod(tex_background, r * vec3(1.0, -1.0, 1.0), roughness * reflections_levels).rgb;
}