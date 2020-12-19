return {
	setLOD = function(self, min, max)
		self.LOD_min = min
		self.LOD_max = max
	end,
	getLOD = function(self)
		return self.LOD_min, self.LOD_max
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