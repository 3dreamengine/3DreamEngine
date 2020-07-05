//part of the 3DreamEngine by Luke100000
//point.glsl - point shadows

float sampleShadowPoint(vec3 lightVec, float size, samplerCube tex) {
	vec3 n = -normalize(lightVec) * vec3(1.0, -1.0, 1.0);
	vec3 t = normalize(vec3(-n.x, -n.y, (-n.x*n.x - n.y*n.y) / n.z));
	vec3 b = cross(n, t);
	
	float depth = length(lightVec);
	
	float bias = 0.01 + depth * 0.01;
	depth -= bias;
	
	return texture(tex, n).r > depth ? 1.0 : 0.0;
}