//optional data for the wind shader
extern float shader_wind;
extern float shader_wind_strength;
extern float shader_wind_scale;

//calculate vertex position
vec4 animations(vec4 vertex_position) {
	return (
		vec4(vertex_position.xyz, 1.0)
		+ vec4((cos(vertex_position.x*0.25*shader_wind_scale + shader_wind) + cos((vertex_position.z*4.0+vertex_position.y)*shader_wind_scale + shader_wind*2.0)) * vertex_position.a * shader_wind_strength, 0.0, 0.0, 0.0)
	);
}