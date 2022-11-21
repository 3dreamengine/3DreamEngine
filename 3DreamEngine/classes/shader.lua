local lib = _3DreamEngine

---@class DreamHasShaders
local class = { }

function class:setPixelShader(shader)
	if self.class == "object" then
		for _, s in pairs(self.objects) do
			s:setPixelShader(shader)
		end
		
		for _, s in pairs(self.meshes) do
			s:setPixelShader(shader)
		end
	else
		shader = lib:getShader(shader)
		assert(shader.type == "pixel", "Invalid shader type")
		self.pixelShader = shader
		
		if self.class == "mesh" then
			self:clearMesh()
		end
	end
end

function class:setVertexShader(shader)
	if self.class == "object" then
		for _, s in pairs(self.objects) do
			s:setVertexShader(shader)
		end
		
		for _, s in pairs(self.meshes) do
			s:setVertexShader(shader)
		end
	else
		shader = lib:getShader(shader)
		assert(shader.type == "vertex", "Invalid shader type")
		self.vertexShader = shader
		
		if self.class == "mesh" then
			self:clearMesh()
		end
	end
end

function class:setWorldShader(shader)
	if self.class == "object" then
		for _, s in pairs(self.objects) do
			s:setWorldShader(shader)
		end
		
		for _, s in pairs(self.meshes) do
			s:setWorldShader(shader)
		end
	else
		shader = lib:getShader(shader)
		assert(shader.type == "world", "Invalid shader type")
		self.worldShader = shader
		
		if self.class == "mesh" then
			self:clearMesh()
		end
	end
end

return class