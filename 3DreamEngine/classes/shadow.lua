local lib = _3DreamEngine

function lib:newShadow(typ, static, res)
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
		lastPos = vec3(0, 0, 0)
	}, self.meta.shadow)
end

function lib:newShadowCanvas(typ, res, dynamic)
	if typ == "sun" then
		local canvas = love.graphics.newCanvas(res, res,
			{format = "depth16", readable = true, msaa = 0, type = "2d"})
		
		canvas:setDepthSampleMode("greater")
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
	
	refresh = function(self)
		self.done = { }
	end,
	
	setStatic = function(self, static)
		self.static = static
	end,
	getStatic = function(self)
		return self.static
	end,
}