local lib = _3DreamEngine

function lib:newShadow(typ, static, res)
	if static == nil then
		static = "dynamic"
	end
	
	if typ == "point" then
		res = res or self.shadow_cube_resolution
	else
		res = res or self.shadow_resolution
	end
	
	return setmetatable({
		typ = typ,
		res = res,
		static = static or false,
		done = { },
		priority = 1.0,
		lastUpdate = 0,
		target = false,
		refreshStepSize = 1.0,
	}, self.meta.shadow)
end

function lib:newShadowCanvas(typ, res, dynamic)
	if typ == "sun" then
		local canvas = love.graphics.newCanvas(res, res,
			{format = dynamic and "rg16f" or "r16f", readable = true, msaa = 0, type = "2d"})
		
		canvas:setFilter("linear", "linear")
		
		return canvas
	elseif typ == "point" then
		local canvas = love.graphics.newCanvas(res, res,
			{format = dynamic and "rg16f" or "r16f", readable = true, msaa = 0, type = "cube"})
		
		canvas:setFilter("linear", "linear")
		
		return canvas
	end
end

return {
	link = {"shadow"},
	
	setterGetter = {
		refreshStepSize = "number",
	},
	
	refresh = function(self)
		self.done = { }
	end,
	
	setStatic = function(self, static)
		assert(static == true or static == false or static == "dynamic", "static has to be true, false or 'dynamic'")
		self.static = static
	end,
	getStatic = function(self)
		return self.static
	end,
	
	setTarget = function(self, target)
		self.target = target
	end,
	getTarget = function(self)
		return self.target
	end
}