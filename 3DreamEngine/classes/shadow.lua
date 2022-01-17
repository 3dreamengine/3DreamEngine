local lib = _3DreamEngine

function lib:newShadow(typ, static, resolution)
	return setmetatable({
		typ = typ,
		
		resolution = resolution or (typ == "sun" and 512 or 256),
		static = static or false,
		done = false,
		target = false,
		refreshStepSize = 1.0,
		
		cascadeDistance = 8,
		cascadeFactor = 4,
		
		smooth = false,
	}, self.meta.shadow)
end

local class = {
	link = {"shadow"},
	
	setterGetter = {
		resolution = "number",
		
		refreshStepSize = "number",
		cascadeDistance = "number",
		cascadeFactor = "number",
		
		smooth = "boolean",
	},
}

function class:refresh()
	self.rendered = false
end

function class:clear()
	self.canvases = nil
	self.canvas = nil
	self:refresh()
end

function class:getStatic()
	return self.static
end

function class:setResolution(r)
	self.resolution = r
	self:clear()
end

function class:setSmooth(s)
	self.smooth = s
	self:clear()
end

return class