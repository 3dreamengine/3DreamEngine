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
	
	setVisibility = function(self, render, shadows, reflections)
		if render == nil then
			self.visibility = false
		elseif type(render) == "table" then
			self.visibility = render
		else
			self.visibility = {
				render = render,
				shadows = shadows,
				reflections = reflections,
			}
		end
	end,
	getVisibility = function(self)
		if self.visibility then
			return self.visibility.render, self.visibility.shadows, self.visibility.reflections
		else
			return true, true, true
		end
	end,
}