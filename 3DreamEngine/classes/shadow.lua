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
		done = false,
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

local class = {
	link = {"shadow"},
	
	setterGetter = {
		refreshStepSize = "number",
		refreshStepSize = "number",
	},
}
	
function class:refresh()
	self.done = false
end

function class:getStatic()
	return self.static
end

return class