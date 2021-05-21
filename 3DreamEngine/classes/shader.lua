return {
	setPixelShader = function(self, shader)
		assert(shader.type == "pixel", "invalid shader type")
		self.pixelShader = shader
	end,
	
	setVertexShader = function(self, shader)
		assert(shader.type == "vertex", "invalid shader type")
		self.vertexShader = shader
	end,
	
	setWorldShader = function(self, shader)
		assert(shader.type == "world", "invalid shader type")
		self.worldShader = shader
	end,
}