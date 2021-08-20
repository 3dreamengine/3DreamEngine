local lib = _3DreamEngine

return {
	setLOD = function(self, min, max)
		self.LOD_min = min
		self.LOD_max = max
	end,
	getLOD = function(self)
		return self.LOD_min, self.LOD_max
	end,
	
	setVisible = function(self, b)
		self.visible = b
	end,
	isVisible = function(self)
		return self.visible
	end,
	
	setRenderVisibility = function(self, b)
		if self.class == "object" then
			for d,s in pairs(self.objects) do
				s:setRenderVisibility(b)
			end
			for d,s in pairs(self.meshes) do
				s:setRenderVisibility(b)
			end
		else
			self.renderVisibility = b
		end
	end,
	getRenderVisibility = function(self)
		return self.renderVisibility == true
	end,
	
	setShadowVisibility = function(self, b)
		if self.class == "object" then
			for d,s in pairs(self.objects) do
				s:setShadowVisibility(b)
			end
			for d,s in pairs(self.meshes) do
				s:setShadowVisibility(b)
			end
		else
			self.shadowVisibility = b
		end
	end,
	getShadowVisibility = function(self)
		return self.shadowVisibility == true
	end,
	
	setFarVisibility = function(self, b)
		if self.class == "object" then
			for d,s in pairs(self.objects) do
				s:setFarVisibility(b)
			end
			for d,s in pairs(self.meshes) do
				s:setFarVisibility(b)
			end
		else
			self.farVisibility = b
		end
	end,
	getFarVisibility = function(self)
		return self.farVisibility == true
	end,
}