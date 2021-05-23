local sh = { }

sh.type = "vertex"

function sh:init(dream)
	self.speed = 0.5       -- the time multiplier
	self.strength = 0.2    -- the multiplier of animation
	self.scale = 3.0       -- the scale of wind waves
	
	self.fadeWidth = 1
end

function sh:getId(dream, mat, shadow)
	return 0
end

function sh:buildDefines(dream, mat)
	return [[
	varying float shader_fade;
	
#ifdef VERTEX
	extern float shader_wind;
	extern float shader_wind_strength;
	extern float shader_wind_scale;
	extern float shader_wind_height;
	extern float shader_wind_grass;
	
	extern float shader_fade_distance;
	extern float shader_fade_width;
#endif
	]]
end

function sh:buildPixel(dream, mat)
	return [[
		if (shader_fade + alpha - 1.0 < 0.0) {
			discard;
		}
	]]
end

function sh:buildVertex(dream, mat)
		return [[
		vertexPos = vertexPos.xyz + vec3((
				cos(vertexPos.x*0.25*shader_wind_scale + shader_wind) +
				cos((vertexPos.z*4.0+vertexPos.y)*shader_wind_scale + shader_wind*2.0)
			) * mix(1.0, VertexPosition.y * shader_wind_height, shader_wind_grass) * shader_wind_strength, 0.0, 0.0);
		
		vertexPos = (transform * vec4(vertexPos, 1.0)).xyz;
		
		float dist = distance(vertexPos, viewPos);
		shader_fade = (shader_fade_distance - dist) * shader_fade_width;
	]]
end

function sh:perShader(dream, shaderObject)
	local shader = shaderObject.shader
	shader:send("shader_wind_strength", self.strength)
	shader:send("shader_wind_scale", self.scale)
	shader:send("shader_wind", love.timer.getTime() * self.speed)
	
	shader:send("shader_fade_width", 1 / self.fadeWidth)
end

function sh:perMaterial(dream, shaderObject, material)
	local shader = shaderObject.shader
	shader:send("shader_wind_height", 1.0)
	shader:send("shader_wind_grass", 1.0)
end

function sh:perTask(dream, shaderObject, task)
	local shader = shaderObject.shader
	local LOD_max = (task:getSubObj().LOD_max or 1) * dream.LODDistance
	shader:send("shader_fade_distance", LOD_max)
end

return sh