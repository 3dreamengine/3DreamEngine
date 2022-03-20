extern samplerCube backgroundTexture;
extern float reflectionsLevels;

extern bool reflectionsBoxed;
extern vec3 reflectionsPos;
extern vec3 reflectionsFirst;
extern vec3 reflectionsSecond;

vec3 reflection(vec3 ref, float roughness) {
	vec3 r;
	if (reflectionsBoxed) {
		vec3 maxIntersect = (reflectionsSecond - vertexPos) / ref;
		vec3 minIntersect = (reflectionsFirst - vertexPos) / ref;
		vec3 largestRayParams = max(maxIntersect, minIntersect);
		float dist = min(min(largestRayParams.x, largestRayParams.y), largestRayParams.z);
		r = vertexPos + ref * dist - reflectionsPos;
	} else {
		r = ref;
	}
	return gammaCorrectedTexel(backgroundTexture, r * vec3(1.0, -1.0, 1.0), roughness * reflectionsLevels).rgb;
}