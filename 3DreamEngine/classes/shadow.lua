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
		done = false,
		target = false,
		refreshStepSize = 1.0,
	}, self.meta.shadow)
end

local class = {
	link = {"shadow"},
	
	setterGetter = {
		refreshStepSize = "number",
		refreshStepSize = "number",
	},
}
	
function class:refresh()
	self.rendered = false
end

function class:getStatic()
	return self.static
end

return class