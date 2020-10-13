return {
	setLOD = function(self, LOD)
		self.LOD = LOD
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
}