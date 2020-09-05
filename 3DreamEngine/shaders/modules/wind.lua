local sh = { }

sh.type = "module"

function sh:init(dream)
	self.speed = 0.5       -- the time multiplier
	self.strength = 1.0    -- the multiplier of animation
	self.scale = 3.0       -- the scale of wind waves
end

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
	vertexPos += vec3((cos(vertex_position.x*0.25*shader_wind_scale + shader_wind) + cos((vertex_position.z*4.0+vertex_position.y)*shader_wind_scale + shader_wind*2.0)) * vertex_position.a * shader_wind_strength, 0.0, 0.0);
	]]
end

function sh:perShader(dream, shader, info)
	shader:send("shader_wind_strength", self.strength or 1.0)
	shader:send("shader_wind_scale", self.scale or 1.0)
	shader:send("shader_wind", love.timer.getTime() * (self.speed or 1.0))
end

function sh:perMaterial(dream, shader, info, material)
	
end

function sh:perObject(dream, shader, info, task)

end

return sh