local lib = _3DreamEngine

return {
	setPixelShader = function(self, shader)
		if self.class == "object" then
			for d,s in pairs(self.objects) do
				s.material:setPixelShader(shader)
			end
		elseif self.class == "subObject" then
			self.material:setPixelShader(shader)
		else
			shader = lib:resolveShaderName(shader)
			assert(shader.type == "pixel", "invalid shader type")
			self.pixelShader = shader
		end
	end,
	
	setVertexShader = function(self, shader)
		if self.class == "object" then
			for d,s in pairs(self.objects) do
				s.material:setVertexShader(shader)
			end
		elseif self.class == "subObject" then
			self.material:setVertexShader(shader)
		else
			shader = lib:resolveShaderName(shader)
			assert(shader.type == "vertex", "invalid shader type")
			self.vertexShader = shader
		end
	end,
	
	setWorldShader = function(self, shader)
		if self.class == "object" then
			for d,s in pairs(self.objects) do
				s.material:setWorldShader(shader)
			end
		elseif self.class == "subObject" then
			self.material:setWorldShader(shader)
		else
			shader = lib:resolveShaderName(shader)
			assert(shader.type == "world", "invalid shader type")
			self.worldShader = shader
		end
	end,
}