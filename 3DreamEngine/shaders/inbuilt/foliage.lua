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
	extern float windShaderFade;
#endif

#ifdef VERTEX
	extern float windShaderTime;
	extern float windShaderStrength;
	extern float windShaderScale;
	extern float windShaderHeight;
	extern float windShaderGrass;
	
	extern Image noiseTexture;
#endif
	]]
end

function sh:buildPixel(dream, mat)
	return [[
		alpha *= windShaderFade;
	]]
end

function sh:buildVertex(dream, mat)
	return [[
		vec3 noise = Texel(noiseTexture, vertexPos.xz * windShaderScale * 0.3 + vec2(windShaderTime, windShaderTime * 0.7)).xyz - vec3(0.5);
		
		float windStrength = mix(1.0, (normalTransform * VertexPosition.xyz).y * windShaderHeight, windShaderGrass) * windShaderStrength;
		
		vertexPos = (transform * vec4(vertexPos, 1.0)).xyz + noise * vec3(windStrength, windStrength * 0.25, windStrength);
	]]
end

function sh:perShader(dream, shaderObject)
	local shader = shaderObject.shader
	shader:send("noiseTexture", dream.textures.noise)
end

function sh:perMaterial(dream, shaderObject, material)
	local shader = shaderObject.shader
	shader:send("windShaderScale", material.windShaderScale or self.scale)
	shader:send("windShaderStrength", material.windShaderStrength or self.strength)
	shader:send("windShaderHeight", 1 / (material.windShaderHeight or 1.0))
	shader:send("windShaderTime", (love.timer.getTime() % 10000) * (material.windShaderSpeed or self.speed))
	shader:send("windShaderGrass", material.windShaderGrass and 1 or 0)
end

function sh:perTask(dream, shaderObject, task)
	local shader = shaderObject.shader
	local LOD_max = (task:getMesh().LOD_max or 1) * dream.LODDistance
	local width = task:getMesh().material.windShaderFadeWidth or self.fadeWidth
	local dist = (task:getPos() - dream.cam.pos):length() - task:getSize()
	local fade = math.max(0, math.min(1, (LOD_max - dist) / width))
	shader:send("windShaderFade", fade)
end

return sh