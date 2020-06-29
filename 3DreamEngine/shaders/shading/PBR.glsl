//part of the 3DreamEngine by Luke100000
//PBR lighting shader, expects metallness + roughness workflow

const float pi = 3.14159265359;
const float ipi = 0.31830988618;

float DistributionGGX(vec3 normal, vec3 halfView, float roughness) {
    float a = pow(roughness, 4.0);
	
    float NdotH = max(dot(normal, halfView), 0.0);
    float NdotH2 = NdotH * NdotH;
	
    float denom = NdotH2 * (a - 1.0) + 1.0;
    denom = pi * denom * denom;
	
    return a / max(denom, 0.01);
}

float GeometrySchlickGGX(float NdotV, float roughness) {
    float r = roughness + 1.0;
    float k = (r * r) * 0.125;
    float denom = NdotV * (1.0 - k) + k;
    return NdotV / denom;
}

float GeometrySmith(vec3 normal, vec3 view, vec3 light, float roughness) {
    float NdotV = max(dot(normal, view), 0.0);
    float NdotL = max(dot(normal, light), 0.0);
    float ggx2 = GeometrySchlickGGX(NdotV, roughness);
    float ggx1 = GeometrySchlickGGX(NdotL, roughness);
    return ggx1 * ggx2;
}

vec3 getLight(vec3 lightColor, vec3 viewVec, vec3 lightVec, vec3 normal, vec3 albedo, float roughness, float metallic) {
	//reflectance
	vec3 F0 = mix(vec3(0.04), albedo, metallic);
	
	vec3 halfVec = normalize(viewVec + lightVec);
	
	float NDF = DistributionGGX(normal, halfVec, roughness);   
	float G = GeometrySmith(normal, viewVec, lightVec, roughness);
	
	//fresnel
	float cosTheta = clamp(dot(halfVec, viewVec), 0.0, 1.0);
	vec3 fresnel = F0 + (1.0 - F0) * pow(1.0 - cosTheta, 5.0);
	
	//specular
	vec3 nominator = NDF * G * fresnel;
	float denominator = 4.0 * max(dot(normal, viewVec), 0.0) * max(dot(normal, lightVec), 0.0) + 0.001;
	vec3 specular = nominator / denominator;
	
	//energy conservation
	vec3 kD = (vec3(1.0) - fresnel) * (1.0 - metallic);
	
	float lightAngle = max(dot(lightVec, normal), 0.0);
	return (kD * albedo * ipi + specular) * lightColor * lightAngle;
}