local lib = _3DreamEngine

return {
	setLOD = function(self, min, max)
		self.LOD_min = min
		self.LOD_max = max
	end,
	getLOD = function(self)
		return self.LOD_min, self.LOD_max
	end,
	
	setRenderVisibility = function(self, b)
		self.renderVisibility = b
	end,
	getRenderVisibility = function(self)
		return self.renderVisibility == true
	end,
	
	setShadowVisibility = function(self, b)
		self.shadowVisibility = b
	end,
	getShadowVisibility = function(self)
		return self.shadowVisibility == true
	end,
	
	setFarVisibility = function(self, b)
		assert(type(b) == "boolean", "arg has to be a boolean")
		self.farVisibility = b
	end,
	getFarVisibility = function(self)
		return self.farVisibility == true
	end,
}