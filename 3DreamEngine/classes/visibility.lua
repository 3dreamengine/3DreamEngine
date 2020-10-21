return {
	setLOD = function(self, LOD)
		self.LOD = LOD
	end,
	getLOD = function(self)
		return self.LOD
	end,
	
	setVisibility = function(self, render, shadow, reflections)
		if render == nil then
			self.visibility = false
		elseif type(render) == "table" then
			self.visibility = render
		else
			self.visibility = {
				render = render,
				shadow = shadow,
				reflections = reflections,
			}
		end
	end,
	getVisibility = function(self)
		if self.visibility then
			return self.visibility.render, self.visibility.shadow, self.visibility.reflections
		else
			return false, false, false
		end
	end,
}