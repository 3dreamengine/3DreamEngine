#pragma language glsl3

extern vec3 dirX;
extern vec3 dirY;
extern vec3 normal;

extern float scale;
extern float lod;

extern CubeImage tex;

extern float strength;

extern float dir;

vec4 effect(vec4 color, Image lol, vec2 tc, vec2 sc) {
	tc = (sc * scale - vec2(0.5)) * 2.0;
	
	float p = strength * (1.0 + lod * lod);
	
	vec3 vec = normalize(normal + tc.x * dirX + tc.y * dirY);
	vec3 tangent = normalize(vec3(-vec.x, -vec.y, (vec.x*vec.x + vec.y*vec.y) / vec.z)) * p;
	vec3 bitangent = normalize(cross(vec, tangent)) * p;
	vec3 blurVec = mix(tangent, bitangent, dir);
	
	vec4 sum = vec4(0.0);
	
	sum += textureLod(tex, vec - blurVec * 1.0, lod) * 0.002166;
	sum += textureLod(tex, vec - blurVec * 0.8, lod) * 0.011902;
	sum += textureLod(tex, vec - blurVec * 0.6, lod) * 0.044758;
	sum += textureLod(tex, vec - blurVec * 0.4, lod) * 0.115233;
	sum += textureLod(tex, vec - blurVec * 0.2, lod) * 0.203199;
	
	sum += textureLod(tex, vec + blurVec * 0.0, lod) * 0.245484;
	
	sum += textureLod(tex, vec + blurVec * 0.2, lod) * 0.203199;
	sum += textureLod(tex, vec + blurVec * 0.4, lod) * 0.115233;
	sum += textureLod(tex, vec + blurVec * 0.6, lod) * 0.044758;
	sum += textureLod(tex, vec + blurVec * 0.8, lod) * 0.011902;
	sum += textureLod(tex, vec + blurVec * 1.0, lod) * 0.002166;
	
	return sum;
}