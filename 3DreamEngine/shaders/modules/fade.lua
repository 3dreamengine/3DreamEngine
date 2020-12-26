local sh = { }

sh.type = "module"

sh.shadow = true

function sh:init(dream)
	self.fadeDistance = 10
	self.fadeWidth = 1
end

function sh:constructDefines(dream)
	return [[
	extern float shader_fade_distance;
	extern float shader_fade_width;
	varying float shader_fade;
	]]
end

function sh:constructPixelPre(dream)
	return [[
		albedo.a *= shader_fade;
	]]
end

function sh:constructVertexPost(dream)
	return [[
	{
		float dist = distance(vertexPos, viewPos) + vertex_position.a;
		shader_fade = clamp((shader_fade_distance - dist) * shader_fade_width, 0.0, 1.0);
	}
	]]
end

function sh:perShader(dream, shaderObject)
	local shader = shaderObject.shader
	shader:send("shader_fade_width", 1 / self.fadeWidth)
end

function sh:perMaterial(dream, shaderObject, material)
	
end

function sh:perTask(dream, shaderObject, task)
	local shader = shaderObject.shader
	local _, LOD_max = task:getScaledLOD()
	shader:send("shader_fade_distance", LOD_max)
end

return sh