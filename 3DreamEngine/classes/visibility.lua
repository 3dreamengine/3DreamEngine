return {
	setLOD = function(self, render, shadow, reflections)
		self.LOD = render and {
			render = render,
			shadow = shadow or render,
			reflections = reflections or render,
		}
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