local lib = _3DreamEngine

function lib:newShadow(typ, resolution)
	return setmetatable({
		typ = typ,
		
		resolution = resolution or (typ == "sun" and 1024 or 512),
		done = false,
		target = false,
		refreshStepSize = typ == "sun" and 1.0 or 0.0001,
		
		cascadeDistance = 8,
		cascadeFactor = 4,
		
		static = false,
		smooth = false,
		dynamic = true,
		lazy = false,
	}, self.meta.shadow)
end

local class = {
	link = {"shadow"},
	
	setterGetter = {
		resolution = "number",
		
		refreshStepSize = "number",
		cascadeDistance = "number",
		cascadeFactor = "number",
		
		static = "boolean",
		dynamic = "boolean",
		smooth = "boolean",
		lazy = "boolean",
	},
}

function class:refresh()
	self.rendered = false
end

function class:clear()
	self.canvases = nil
	self.canvas = nil
	self.lastFace = nil
	self:refresh()
end

function class:setResolution(r)
	self.resolution = r
	self:clear()
end

function class:setStatic(s)
	self.static = s
	if s then
		self.dynamic = false
	end
	self:clear()
end

function class:setDynamic(s)
	self.dynamic = s
	self:clear()
end

function class:setSmooth(s)
	self.smooth = s
	self:clear()
end

return class