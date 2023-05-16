#ifdef PIXEL
uniform samplerCube backgroundTexture;
uniform float reflectionsLevels;

uniform bool reflectionsBoxed;
uniform vec3 reflectionsCenter;
uniform vec3 reflectionsFirst;
uniform vec3 reflectionsSecond;

vec3 reflection(vec3 ref, float roughness) {
	vec3 r;
	if (reflectionsBoxed) {
		vec3 maxIntersect = (reflectionsSecond - vertexPos) / ref;
		vec3 minIntersect = (reflectionsFirst - vertexPos) / ref;
		vec3 largestRayParams = max(maxIntersect, minIntersect);
		float dist = min(min(largestRayParams.x, largestRayParams.y), largestRayParams.z);
		r = vertexPos + ref * dist - reflectionsCenter;
	} else {
		r = ref;
	}
	return gammaCorrectedTexel(backgroundTexture, r * vec3(1.0, 1.0, -1.0), roughness * reflectionsLevels).rgb;
}
#endif