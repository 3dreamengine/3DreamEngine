#pragma language glsl3

extern float scale;
extern float lod;

extern CubeImage tex;

extern float strength;

vec4 fetch(float p, vec2 tc, vec3 normal, vec3 dirX, vec3 dirY) {
	vec3 vec = normalize(normal + tc.x * dirX + tc.y * dirY);
	vec3 tangent = normalize(vec3(-vec.x, -vec.y, (vec.x*vec.x + vec.y*vec.y) / vec.z)) * p;
	vec3 bitangent = normalize(cross(vec, tangent)) * p;
	
	vec3 tangentH = tangent * 0.5;
	vec3 bitangentH = bitangent * 0.5;
	
	vec4 sum = vec4(0.0);
	
	sum += textureLod(tex, vec - tangent - bitangent, lod);
	sum += textureLod(tex, vec - tangentH - bitangent, lod);
	sum += textureLod(tex, vec - bitangent, lod);
	sum += textureLod(tex, vec + tangentH - bitangent, lod);
	sum += textureLod(tex, vec + tangent - bitangent, lod);
	
	sum += textureLod(tex, vec - tangent - bitangentH, lod);
	sum += textureLod(tex, vec - tangentH - bitangentH, lod);
	sum += textureLod(tex, vec - bitangentH, lod);
	sum += textureLod(tex, vec + tangentH - bitangentH, lod);
	sum += textureLod(tex, vec + tangent - bitangentH, lod);
	
	sum += textureLod(tex, vec - tangent, lod);
	sum += textureLod(tex, vec - tangentH, lod);
	sum += textureLod(tex, vec, lod);
	sum += textureLod(tex, vec + tangentH, lod);
	sum += textureLod(tex, vec + tangent, lod);
	
	sum += textureLod(tex, vec - tangent + bitangentH, lod);
	sum += textureLod(tex, vec - tangentH + bitangentH, lod);
	sum += textureLod(tex, vec + bitangentH, lod);
	sum += textureLod(tex, vec + tangentH + bitangentH, lod);
	sum += textureLod(tex, vec + tangent + bitangentH, lod);
	
	sum += textureLod(tex, vec - tangent + bitangent, lod);
	sum += textureLod(tex, vec - tangentH + bitangent, lod);
	sum += textureLod(tex, vec + bitangent, lod);
	sum += textureLod(tex, vec + tangentH + bitangent, lod);
	sum += textureLod(tex, vec + tangent + bitangent, lod);
	
	return sum / 25.0;
}

void effect() {
	vec2 tc = (love_PixelCoord.xy * scale - vec2(0.5)) * 2.0;
	float p = strength * (1.0 + lod * lod);
	
	love_Canvases[0] = fetch(
		p, tc,
		vec3(1.0, 0.0, 0.0),
		vec3(0.0, 0.0, -1.0),
		vec3(0.0, -1.0, 0.0)
	);
	
	love_Canvases[1] = fetch(
		p, tc,
		vec3(-1.0, 0.0, 0.0),
		vec3(0.0, 0.0, 1.0),
		vec3(0.0, -1.0, 0.0)
	);
	
	love_Canvases[2] = fetch(
		p, tc,
		vec3(0.0, 1.0, 0.0),
		vec3(1.0, 0.0, 0.0),
		vec3(0.0, 0.0, 1.0)
	);
	
	love_Canvases[3] = fetch(
		p, tc,
		vec3(0.0, -1.0, 0.0),
		vec3(1.0, 0.0, 0.0),
		vec3(0.0, 0.0, -1.0)
	);
	
	love_Canvases[4] = fetch(
		p, tc,
		vec3(0.0, 0.0, 1.0),
		vec3(1.0, 0.0, 0.0),
		vec3(0.0, -1.0, 0.0)
	);
	
	love_Canvases[5] = fetch(
		p, tc,
		vec3(0.0, 0.0, -1.0),
		vec3(-1.0, 0.0, 0.0),
		vec3(0.0, -1.0, 0.0)
	);
}