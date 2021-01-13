local lib = _3DreamEngine

return {
	setLOD = function(self, min, max, adaptSize)
		self.LOD_min = min
		self.LOD_max = max
		self.LOD_adaptSize = adaptSize
	end,
	getLOD = function(self)
		return self.LOD_min, self.LOD_max
	end,
	getScaledLOD = function(self)
		if self.LOD_min then
			return self.LOD_min * lib.LODDistance, self.LOD_adaptSize and (self.LOD_max * lib.LODDistance + self.boundingBox.size) or self.LOD_max * lib.LODDistance
		end
	end,
	
	setRenderVisibility = function(self, b)
		assert(type(b) == "boolean", "arg has to be a boolean")
		self.renderVisibility = b
	end,
	getRenderVisibility = function(self)
		return self.renderVisibility == true
	end,
	
	setShadowVisibility = function(self, b)
		assert(type(b) == "boolean", "arg has to be a boolean")
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