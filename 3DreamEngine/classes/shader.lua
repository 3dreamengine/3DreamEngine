local lib = _3DreamEngine

return {
	setPixelShader = function(self, shader)
		if self.class == "object" then
			for d,s in pairs(self.objects) do
				s:setPixelShader(shader)
			end
		else
			shader = lib:resolveShaderName(shader)
			assert(shader.type == "pixel", "invalid shader type")
			self.pixelShader = shader
			
			if self.initShaders then
				self:initShaders()
			end
		end
	end,
	
	setVertexShader = function(self, shader)
		if self.class == "object" then
			for d,s in pairs(self.objects) do
				s:setVertexShader(shader)
			end
		else
			shader = lib:resolveShaderName(shader)
			assert(shader.type == "vertex", "invalid shader type")
			self.vertexShader = shader
			
			if self.initShaders then
				self:initShaders()
			end
		end
	end,
	
	setWorldShader = function(self, shader)
		if self.class == "object" then
			for d,s in pairs(self.objects) do
				s:setWorldShader(shader)
			end
		else
			shader = lib:resolveShaderName(shader)
			assert(shader.type == "world", "invalid shader type")
			self.worldShader = shader
			
			if self.initShaders then
				self:initShaders()
			end
		end
	end,
}