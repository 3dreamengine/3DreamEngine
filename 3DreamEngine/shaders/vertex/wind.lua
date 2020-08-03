local sh = { }

sh.type = "vertex"

function sh:constructDefines(dream, info)
	return [[
	extern float shader_wind;
	extern float shader_wind_strength;
	extern float shader_wind_scale;
	]]
end

function sh:constructPixel(dream, info)
	
end

function sh:constructVertex(dream, info)
	return [[
	vec4 pos = transform * (
		vec4(vertex_position.xyz, 1.0) +
		vec4((cos(vertex_position.x*0.25*shader_wind_scale + shader_wind) + cos((vertex_position.z*4.0+vertex_position.y)*shader_wind_scale + shader_wind*2.0)) * vertex_position.a * shader_wind_strength, 0.0, 0.0, 0.0)
	);
	]]
end

function sh:perShader(dream, shader, info)
	
end

function sh:perMaterial(dream, shader, info, material)
	shader:send("shader_wind_strength", material.shader_wind_strength or 1.0)
	shader:send("shader_wind_scale", material.shader_wind_scale or 1.0)
	shader:send("shader_wind", love.timer.getTime() * (material.shader_wind_speed or 1.0))
end

function sh:perObject(dream, shader, info, task)

end

return sh