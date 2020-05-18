extern samplerCube tex_background;
extern float reflections_levels;

vec3 reflection(vec3 ref, float roughness) {
	return textureLod(tex_background, ref * vec3(1.0, -1.0, 1.0), roughness * reflections_levels).rgb;
}