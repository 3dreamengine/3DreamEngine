//part of the 3DreamEngine by Luke100000
//Phong lighting shader, expects specular + glossiness workflow

//the PBR model is darker than the Phong shading, the use the same light intensities the Phong shading will be adapted
const float adaptToPBR = 0.25;

vec3 getLight(vec3 lightColor, vec3 viewVec, vec3 lightVec, vec3 normal, vec3 albedo, float specular, float glossiness) {
	float lambertian = max(dot(lightVec, normal), 0.0);
	float spec = 0.0;
	
	if (lambertian > 0.0) {
		vec3 halfDir = normalize(lightVec + viewVec);
		float specAngle = max(dot(halfDir, normal), 0.0);
		spec = specular * pow(specAngle, 1.0 + glossiness * 256.0);
	}
	
	return albedo * lightColor * (lambertian + spec) * adaptToPBR;
}