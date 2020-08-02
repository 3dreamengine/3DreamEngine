#pragma language glsl3

extern vec3 dirX;
extern vec3 dirY;
extern vec3 normal;

extern float margin;
extern float scale;
extern float lod;

extern CubeImage tex;

extern float strength = 0.025;

vec4 effect(vec4 color, Image lol, vec2 tc, vec2 sc) {
	tc = (sc * scale - vec2(0.5)) * 2.0;
	
	float p = strength * (1.0 + lod * lod);
	
	vec3 vec = normalize(normal + tc.x * dirX + tc.y * dirY);
	vec3 tangent = normalize(vec3(-vec.x, -vec.y, (vec.x*vec.x + vec.y*vec.y) / vec.z)) * p;
	vec3 bitangent = normalize(cross(vec, tangent)) * p;
	
	vec4 sum;
	sum += textureLod(tex, vec - tangent * 1.0 - bitangent * 1.0, lod);
	sum += textureLod(tex, vec - tangent * 0.5 - bitangent * 1.0, lod);
	sum += textureLod(tex, vec + tangent * 0.0 - bitangent * 1.0, lod);
	sum += textureLod(tex, vec + tangent * 0.5 - bitangent * 1.0, lod);
	sum += textureLod(tex, vec + tangent * 1.0 - bitangent * 1.0, lod);
	
	sum += textureLod(tex, vec - tangent * 1.0 - bitangent * 0.5, lod);
	sum += textureLod(tex, vec - tangent * 0.5 - bitangent * 0.5, lod);
	sum += textureLod(tex, vec + tangent * 0.0 - bitangent * 0.5, lod);
	sum += textureLod(tex, vec + tangent * 0.5 - bitangent * 0.5, lod);
	sum += textureLod(tex, vec + tangent * 1.0 - bitangent * 0.5, lod);
	
	sum += textureLod(tex, vec - tangent * 1.0 + bitangent * 0.0, lod);
	sum += textureLod(tex, vec - tangent * 0.5 + bitangent * 0.0, lod);
	sum += textureLod(tex, vec + tangent * 0.0 + bitangent * 0.0, lod);
	sum += textureLod(tex, vec + tangent * 0.5 + bitangent * 0.0, lod);
	sum += textureLod(tex, vec + tangent * 1.0 + bitangent * 0.0, lod);
	
	sum += textureLod(tex, vec - tangent * 1.0 + bitangent * 0.5, lod);
	sum += textureLod(tex, vec - tangent * 0.5 + bitangent * 0.5, lod);
	sum += textureLod(tex, vec + tangent * 0.0 + bitangent * 0.5, lod);
	sum += textureLod(tex, vec + tangent * 0.5 + bitangent * 0.5, lod);
	sum += textureLod(tex, vec + tangent * 1.0 + bitangent * 0.5, lod);
	
	sum += textureLod(tex, vec - tangent * 1.0 + bitangent * 1.0, lod);
	sum += textureLod(tex, vec - tangent * 0.5 + bitangent * 1.0, lod);
	sum += textureLod(tex, vec + tangent * 0.0 + bitangent * 1.0, lod);
	sum += textureLod(tex, vec + tangent * 0.5 + bitangent * 1.0, lod);
	sum += textureLod(tex, vec + tangent * 1.0 + bitangent * 1.0, lod);
	
	return sum / 25.0;
}