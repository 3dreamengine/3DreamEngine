local sh = { }

sh.type = "vertex"

function sh:init(dream)
	self.speed = 0.05      -- the time multiplier
	self.strength = 0.5    -- the multiplier of animation
	self.scale = 0.25      -- the scale of wind waves
	
	self.fadeWidth = 3     -- the blending margin
end

function sh:getId(dream, mat, shadow)
	return 0
end

function sh:buildDefines(dream, mat)
	return [[
#ifdef PIXEL
	extern float shader_fade;
#endif

#ifdef VERTEX
	extern float shader_wind;
	extern float shader_wind_strength;
	extern float shader_wind_scale;
	extern float shader_wind_height;
	extern float shader_wind_grass;
	
	extern Image tex_noise;
#endif
	]]
end

function sh:buildPixel(dream, mat)
	return [[
		alpha *= shader_fade;
	]]
end

function sh:buildVertex(dream, mat)
	return [[
		vec3 noise = Texel(tex_noise, VertexPos.xz * shader_wind_scale * 0.3 + vec2(shader_wind, shader_wind * 0.7)).xyz - vec3(0.5);
		
		float windStrength = mix(1.0, (normalTransform * VertexPosition.xyz).y * shader_wind_height, shader_wind_grass) * shader_wind_strength;
		
		VertexPos = (transform * vec4(VertexPos, 1.0)).xyz + noise * vec3(windStrength, windStrength * 0.25, windStrength);
	]]
end

function sh:perShader(dream, shaderObject)
	local shader = shaderObject.shader
	shader:send("tex_noise", dream.textures.noise)
end

function sh:perMaterial(dream, shaderObject, material)
	local shader = shaderObject.shader
	shader:send("shader_wind_scale", material.shaderWindScale or self.scale)
	shader:send("shader_wind_strength", material.shaderWindStrength or self.strength)
	shader:send("shader_wind_height", 1 / (material.shaderWindHeight or 1.0))
	shader:send("shader_wind", (love.timer.getTime() % 10000) * (material.shaderWindSpeed or self.speed))
	shader:send("shader_wind_grass", material.shaderWindGrass and 1 or 0)
end

function sh:perTask(dream, shaderObject, task)
	local shader = shaderObject.shader
	local LOD_max = (task:getMesh().LOD_max or 1) * dream.LODDistance
	local width = task:getMesh().material.shaderWindFadeWidth or self.fadeWidth
	local dist = (task:getPos() - dream.cam.pos):length() - task:getSize()
	local fade = math.max(0, math.min(1, (LOD_max - dist) / width))
	shader:send("shader_fade", fade)
end

return sh