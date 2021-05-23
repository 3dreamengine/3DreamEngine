local sh = { }

sh.type = "vertex"

function sh:init(dream)
	self.speed = 0.5       -- the time multiplier
	self.strength = 1.0    -- the multiplier of animation
	self.scale = 3.0       -- the scale of wind waves
end

function sh:getId(dream, mat, shadow)
	return 0
end

function sh:buildDefines(dream, mat)
	return [[
#ifdef VERTEX
	extern float shader_wind;
	extern float shader_wind_strength;
	extern float shader_wind_scale;
	extern float shader_wind_height;
	extern float shader_wind_grass;
#endif
	]]
end

function sh:buildPixel(dream, mat)
	return ""
end

function sh:buildVertex(dream, mat)
		return [[
		vertexPos = vertexPos.xyz + vec3((
				cos(vertexPos.x*0.25*shader_wind_scale + shader_wind) +
				cos((vertexPos.z*4.0+vertexPos.y)*shader_wind_scale + shader_wind*2.0)
			) * mix(1.0, VertexPosition.y * shader_wind_height, shader_wind_grass) * shader_wind_strength, 0.0, 0.0);
		
		vertexPos = (transform * vec4(vertexPos, 1.0)).xyz;
	]]
end

function sh:perShader(dream, shaderObject)
	local shader = shaderObject.shader
	shader:send("shader_wind_strength", self.strength or 1.0)
	shader:send("shader_wind_scale", self.scale or 1.0)
	shader:send("shader_wind", love.timer.getTime() * (self.speed or 1.0))
end

function sh:perMaterial(dream, shaderObject, material)
	shader:send("shader_wind_height", 1.0)
	shader:send("shader_wind_grass", 1.0)
end

function sh:perTask(dream, shaderObject, task)

end

return sh