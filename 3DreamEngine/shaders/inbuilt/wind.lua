local dream = _3DreamEngine

local sh = { }

sh.type = "vertex"

function sh:init()
	self.speed = 0.05      -- the time multiplier
	self.strength = 1.0    -- the multiplier of animation
	self.scale = 0.25      -- the scale of wind waves
end

function sh:getId(mat, shadow)
	return 0
end

function sh:buildDefines(mat)
	return [[
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

function sh:buildPixel(mat)
	return ""
end

function sh:buildVertex(mat)
	return [[
		vec3 noise = Texel(noiseTexture, vertexPos.xz * windShaderScale * 0.3 + vec2(windShaderTime, windShaderTime * 0.7)).xyz - vec3(0.5);
		
		float windStrength = mix(1.0, (normalTransform * VertexPosition.xyz).y * windShaderHeight, windShaderGrass) * windShaderStrength;
		
		vertexPos = (transform * vec4(vertexPos, 1.0)).xyz + noise * vec3(windStrength, windStrength * 0.25, windStrength);
	]]
end

function sh:perShader(shaderObject)
	local shader = shaderObject.shader
	shader:send("noiseTexture", dream.textures.noise)
end

function sh:perMaterial(shaderObject, material)
	local shader = shaderObject.shader
	shader:send("windShaderScale", material.windShaderScale or self.scale)
	shader:send("windShaderStrength", material.windShaderStrength or self.strength)
	shader:send("windShaderHeight", 1 / (material.windShaderHeight or 1.0))
	shader:send("windShaderTime", (love.timer.getTime() % 10000) * (material.windShaderSpeed or self.speed))
	shader:send("windShaderGrass", material.windShaderGrass and 1 or 0)
end

function sh:perTask(shaderObject, task)

end

return sh