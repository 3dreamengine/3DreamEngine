float hypot(vec2 z) {
  float t;
  float x = abs(z.x);
  float y = abs(z.y);
  t = min(x, y);
  x = max(x, y);
  t = t / x;
  return (z.x == 0.0 && z.y == 0.0) ? 0.0 : x * sqrt(1.0 + t * t);
}

vec4 effect(vec4 c, Image tex, vec2 tc, vec2 sc) {
	int face = int(tc.x * 6.0);
	vec2 tc2 = vec2(mod(tc.x * 6.0, 1.0), tc.y) * 2.0 - vec2(1.0);
	
	vec3 vec;
	if (face == 0) {
		vec = vec3(1.0, -tc2.y, -tc2.x);
	} else if (face == 1) {
		vec = vec3(-1.0, -tc2.y, tc2.x);
	} else if (face == 2) {
		vec = vec3(tc2.x, 1.0, tc2.y);
	} else if (face == 3) {
		vec = vec3(tc2.x, -1.0, -tc2.y);
	} else if (face == 4) {
		vec = vec3(tc2.x, -tc2.y, 1.0);
	} else {
		vec = vec3(-tc2.x, -tc2.y, -1.0);
	}
	
	float pi = 3.14159265359;
	float theta = atan(vec.y, vec.x) + pi * 0.5;
	float r = hypot(vec.xy);
	float phi = atan(vec.z, r);
	
	vec2 uv = vec2(
		(theta + pi) / pi * 0.5,
		(pi - phi * 2.0) / pi * 0.5
	);

	return Texel(tex, uv);
}